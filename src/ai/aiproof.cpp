// Copyright (c) 2025 The ShardCoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <ai/aiproof.h>
#include <hash.h>
#include <logging.h>
#include <script/script.h>
#include <streams.h>
#include <util/strencodings.h>

#include <sstream>

const unsigned char CAIProof::MAGIC[4] = {0x41, 0x49, 0x50, 0x52}; // "AIPR"

std::vector<unsigned char> CAIProof::Serialize() const
{
    std::vector<unsigned char> data;
    data.reserve(SERIALIZED_SIZE);

    // Magic bytes
    data.insert(data.end(), MAGIC, MAGIC + 4);

    // Version
    data.push_back(version);

    // Response hash (32 bytes)
    data.insert(data.end(), response_hash.begin(), response_hash.end());

    // Model tag (4 bytes, little-endian)
    data.push_back((model_tag >>  0) & 0xff);
    data.push_back((model_tag >>  8) & 0xff);
    data.push_back((model_tag >> 16) & 0xff);
    data.push_back((model_tag >> 24) & 0xff);

    return data;
}

bool CAIProof::Deserialize(const std::vector<unsigned char>& data, CAIProof& proof)
{
    if (data.size() < SERIALIZED_SIZE) return false;

    // Check magic
    if (memcmp(data.data(), MAGIC, 4) != 0) return false;

    proof.version = data[4];
    memcpy(proof.response_hash.begin(), data.data() + 5, 32);

    proof.model_tag = (uint32_t)data[37]
                    | ((uint32_t)data[38] << 8)
                    | ((uint32_t)data[39] << 16)
                    | ((uint32_t)data[40] << 24);

    return true;
}

bool CAIProof::IsValid() const
{
    if (version < 1) return false;
    if (response_hash.IsNull()) return false;
    return true;
}

std::string GetAIChallenge(const uint256& prev_hash, int32_t height)
{
    // Deterministic prompt derived from block data.
    // Each block gets a unique challenge based on previous hash and height.
    std::ostringstream ss;
    ss << "ShardCoin block " << height << ". "
       << "Previous hash: " << prev_hash.GetHex().substr(0, 16) << ". "
       << "Provide a brief, unique analysis related to decentralized computing, "
       << "cryptography, or artificial intelligence. "
       << "Seed: " << prev_hash.GetHex();
    return ss.str();
}

CAIProof CreateAIProof(const std::string& response, const std::string& model)
{
    CAIProof proof;
    proof.version = CAIProof::CURRENT_VERSION;

    // Hash the AI response
    CHashWriter hasher(SER_GETHASH, 0);
    hasher << response;
    proof.response_hash = hasher.GetHash();

    // Hash the model name, take first 4 bytes as tag
    CHashWriter model_hasher(SER_GETHASH, 0);
    model_hasher << model;
    uint256 model_hash = model_hasher.GetHash();
    memcpy(&proof.model_tag, model_hash.begin(), 4);

    return proof;
}

bool ExtractAIProof(const CBlock& block, CAIProof& proof)
{
    if (block.vtx.empty() || !block.vtx[0]->IsCoinBase()) return false;

    const CTransaction& coinbase = *block.vtx[0];

    // Scan coinbase outputs for OP_RETURN with AI proof magic
    for (const CTxOut& out : coinbase.vout) {
        if (out.nValue != 0) continue;
        if (out.scriptPubKey.size() < 2) continue;
        if (out.scriptPubKey[0] != OP_RETURN) continue;

        // Extract pushed data after OP_RETURN
        CScript::const_iterator it = out.scriptPubKey.begin();
        opcodetype opcode;
        std::vector<unsigned char> data;

        // Skip OP_RETURN
        it++;

        // Read pushed data
        if (!out.scriptPubKey.GetOp(it, opcode, data)) continue;

        // Check for AI proof magic
        if (data.size() >= CAIProof::SERIALIZED_SIZE &&
            memcmp(data.data(), CAIProof::MAGIC, 4) == 0) {
            return CAIProof::Deserialize(data, proof);
        }
    }

    return false;
}

bool CheckAIProof(const CBlock& block)
{
    CAIProof proof;
    if (!ExtractAIProof(block, proof)) return false;
    return proof.IsValid();
}

CScript BuildAIProofScript(const CAIProof& proof)
{
    std::vector<unsigned char> data = proof.Serialize();
    CScript script;
    script << OP_RETURN << data;
    return script;
}
