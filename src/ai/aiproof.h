// Copyright (c) 2025 The ShardCoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef BITCOIN_AI_AIPROOF_H
#define BITCOIN_AI_AIPROOF_H

#include <primitives/block.h>
#include <uint256.h>

#include <string>
#include <vector>

/**
 * AI Proof-of-Work (PoAIW) — Proof that the miner performed AI inference.
 *
 * Stored in the coinbase transaction as an OP_RETURN output:
 *   OP_RETURN [push N bytes] [magic 4B] [version 1B] [response_hash 32B] [model_tag 4B]
 *
 * The response_hash commits to the AI model's output for a deterministic
 * challenge derived from the previous block hash and height. Validators
 * check format and commitment without re-running inference.
 */
struct CAIProof {
    static const unsigned char MAGIC[4]; // "AIPR" = {0x41, 0x49, 0x50, 0x52}
    static const uint8_t CURRENT_VERSION = 1;
    static const size_t SERIALIZED_SIZE = 41; // 4 + 1 + 32 + 4

    uint8_t version{CURRENT_VERSION};
    uint256 response_hash;  // Hash256(ai_response_text)
    uint32_t model_tag{0};  // First 4 bytes of Hash256(model_name)

    std::vector<unsigned char> Serialize() const;
    static bool Deserialize(const std::vector<unsigned char>& data, CAIProof& proof);
    bool IsValid() const;
};

/** Generate a deterministic AI challenge prompt from block data. */
std::string GetAIChallenge(const uint256& prev_hash, int32_t height);

/** Create an AI proof from the model response and model name. */
CAIProof CreateAIProof(const std::string& response, const std::string& model);

/** Extract AI proof from a block's coinbase OP_RETURN (if present). */
bool ExtractAIProof(const CBlock& block, CAIProof& proof);

/** Check that a block contains a valid AI proof. */
bool CheckAIProof(const CBlock& block);

/** Build an OP_RETURN script containing the serialized AI proof. */
CScript BuildAIProofScript(const CAIProof& proof);

#endif // BITCOIN_AI_AIPROOF_H
