# ShardCoin: An AI-Native Cryptocurrency with Proof of AI Work, Smooth Emission Decay, and Privacy Extensions

**Version 2.0 - March 2026**

---

## Abstract

ShardCoin (SHRD) is the first AI-native cryptocurrency - a peer-to-peer digital currency that integrates local AI inference directly into its mining process. Every block mined on the ShardCoin network carries a cryptographic proof that the miner performed AI computation via Ollama, a local large language model runtime. This AI Proof-of-Work (PoAIW) mechanism transforms mining from pure hash grinding into a hybrid process that incentivizes running AI infrastructure alongside traditional Scrypt proof-of-work.

ShardCoin combines this innovation with a smooth emission decay model (10% reduction every 100,000 blocks), a scarce maximum supply of approximately 8.4 million SHRD, and a full suite of protocol features - Segregated Witness, Taproot, and Mimblewimble Extension Blocks (MWEB) - all activated from the genesis block.

---

## 1. Introduction

Bitcoin introduced the concept of a decentralized digital currency secured by proof-of-work. Litecoin adapted this model with faster block times and the memory-hard Scrypt hashing algorithm. Both use a halving-based emission schedule where block rewards are cut in half at fixed intervals - a mechanism that creates predictable but abrupt supply shocks.

ShardCoin builds on this lineage with four key design decisions:

1. **AI Proof-of-Work** - mining requires local AI inference via Ollama
2. **Smooth emission decay** rather than abrupt halvings
3. **Scarce fixed supply** of ~8.4M coins (10x scarcer than Bitcoin)
4. **All protocol upgrades active from genesis** - no activation delays

These choices create a cryptocurrency that incentivizes AI compute infrastructure, reduces supply-shock volatility, ensures genuine digital scarcity, and eliminates the technical debt of gradual feature activation.

---

## 2. Technical Foundation

ShardCoin is a full fork of the Litecoin Core codebase, which itself descends from Bitcoin Core. The network operates independently with its own genesis block, network parameters, and address format.

### 2.1 Consensus Parameters

| Parameter | Value |
|-----------|-------|
| Mining Algorithm | Scrypt + AI Proof-of-Work (PoAIW) |
| AI Backend | Ollama (local LLM inference) |
| Block Time | 2.5 minutes |
| Initial Block Reward | 5 SHRD |
| Emission Decay | 10% reduction every 100,000 blocks |
| Maximum Supply | ~8,400,000 SHRD |
| Smallest Unit | 1 shard = 0.00000001 SHRD |

### 2.2 Network Parameters

| Parameter | Value |
|-----------|-------|
| P2P Port (mainnet) | 7333 |
| RPC Port (mainnet) | 7332 |
| Address Prefix (P2PKH) | `S` (byte 63) |
| Address Prefix (P2SH) | byte 5 |
| Bech32 Prefix | `shrd` |
| WIF Prefix | byte 191 |
| BIP44 Coin Type | 1000 |
| Network Magic | `0xd3 0xa2 0xc4 0xe7` |

### 2.3 Data Directories

- Linux: `~/.shardcoin/`
- macOS: `~/Library/Application Support/ShardCoin/`
- Windows: `%APPDATA%\ShardCoin\`
- Configuration file: `shardcoin.conf`

---

## 3. Smooth Emission Decay

### 3.1 Motivation

Bitcoin and Litecoin use a halving schedule: every N blocks, the block reward drops by exactly 50%. While simple and predictable, this creates discrete supply shocks. Miners experience sudden 50% revenue drops, which can cause hash rate instability, increased centralization pressure, and speculative volatility around halving dates.

### 3.2 ShardCoin's Approach

ShardCoin replaces halvings with a smooth exponential decay. The block reward decreases by 10% every 100,000 blocks (approximately 173 days at a 2.5-minute block time):

```
R(n) = 5 * 0.9^(n / 100,000)
```

Where `R(n)` is the reward at block height `n`.

### 3.3 Emission Schedule

| Block Height | Approximate Date | Block Reward | Cumulative Supply |
|-------------|-------------------|--------------|-------------------|
| 0 | Genesis | 5.00000000 SHRD | 0 |
| 100,000 | ~173 days | 4.50000000 SHRD | 500,000 SHRD |
| 200,000 | ~347 days | 4.05000000 SHRD | 950,000 SHRD |
| 500,000 | ~2.4 years | 2.95245000 SHRD | 2,160,000 SHRD |
| 1,000,000 | ~4.8 years | 1.74339220 SHRD | 3,790,000 SHRD |
| 2,000,000 | ~9.5 years | 0.60781770 SHRD | 5,960,000 SHRD |
| 5,000,000 | ~23.8 years | 0.02565781 SHRD | 7,890,000 SHRD |
| 10,000,000 | ~47.6 years | 0.00013158 SHRD | 8,350,000 SHRD |

The reward approaches zero asymptotically. The implementation enforces a hard floor: once the computed reward drops below 1 shard (0.00000001 SHRD), the reward becomes zero.

### 3.4 Supply Cap

The total supply converges to approximately **8,400,000 SHRD**. This is enforced by the `MAX_MONEY` constant in the consensus code. For context:

- Bitcoin: 21,000,000 BTC
- Litecoin: 84,000,000 LTC
- **ShardCoin: ~8,400,000 SHRD**

ShardCoin is 2.5x scarcer than Bitcoin in total supply, while maintaining a comparable emission timeline.

### 3.5 Implementation

The subsidy calculation is implemented in `GetBlockSubsidy()`:

```cpp
CAmount GetBlockSubsidy(int nHeight, const Consensus::Params& consensusParams)
{
    const int decayInterval = 100000;
    int reductions = nHeight / decayInterval;
    CAmount nSubsidy = 5 * COIN;

    for (int i = 0; i < reductions; i++) {
        nSubsidy = nSubsidy * 9 / 10;
        if (nSubsidy < 1) return 0;
    }
    return nSubsidy;
}
```

This approach uses integer arithmetic only, avoiding floating-point rounding issues. Each 10% reduction is computed iteratively to ensure deterministic results across all platforms.

---

## 4. Mining

### 4.1 Hybrid Proof-of-Work: Scrypt + AI

ShardCoin introduces a hybrid mining model that combines traditional Scrypt proof-of-work with AI Proof-of-Work (PoAIW). Every block mined on the network must include a cryptographic commitment proving the miner performed AI inference using a local large language model.

The target block time is 2.5 minutes, with difficulty adjusted every 2016 blocks (~3.5 days).

### 4.2 AI Proof-of-Work (PoAIW)

#### 4.2.1 Overview

PoAIW requires miners to run [Ollama](https://ollama.com), an open-source local LLM runtime, alongside the ShardCoin node. When constructing a new block, the mining software:

1. **Challenge generation**: Derives a deterministic prompt from the previous block hash and the current block height
2. **AI inference**: Sends the challenge to the local Ollama instance, which generates a response using the configured language model
3. **Proof creation**: Computes `Hash256(response)` and embeds it in the coinbase transaction as an OP_RETURN output
4. **Scrypt mining**: Proceeds with standard Scrypt nonce grinding until the block hash meets the difficulty target

The AI proof becomes part of the block's identity through the Merkle root - changing the AI response changes the coinbase transaction, which changes the Merkle root, which changes the block header hash.

#### 4.2.2 Proof Structure

The AI proof is encoded in a coinbase OP_RETURN output with the following format:

```
OP_RETURN [push 41 bytes] [magic "AIPR" (4B)] [version (1B)] [response_hash (32B)] [model_tag (4B)]
```

| Field | Size | Description |
|-------|------|-------------|
| Magic | 4 bytes | `0x41 0x49 0x50 0x52` ("AIPR") - identifies the output as an AI proof |
| Version | 1 byte | Proof format version (currently `0x01`) |
| Response Hash | 32 bytes | `Hash256` of the AI model's response text |
| Model Tag | 4 bytes | First 4 bytes of `Hash256(model_name)` - identifies which model was used |

Total: 41 bytes, well within the standard OP_RETURN relay limit.

#### 4.2.3 Challenge Determinism

The challenge prompt is deterministically derived from block data:

```
"ShardCoin block {height}. Previous hash: {prev_hash[:16]}.
 Provide a brief, unique analysis related to decentralized computing,
 cryptography, or artificial intelligence. Seed: {prev_hash}"
```

This ensures each block has a unique, unpredictable challenge that can only be known after the previous block is mined.

#### 4.2.4 Validation

Full nodes validate AI proofs without re-running inference:

1. Locate the OP_RETURN output with the `AIPR` magic bytes in the coinbase transaction
2. Verify the proof is well-formed (correct size, valid version, non-null response hash)
3. Accept the block if the proof passes format validation

This asymmetry - expensive to produce (requires running an LLM), cheap to verify (just format checking) - mirrors the fundamental property of all proof-of-work systems.

#### 4.2.5 Design Rationale

Traditional proof-of-work converts electricity into security through hash computation that produces no useful output. PoAIW preserves this security model (Scrypt still secures the chain) while adding a requirement that miners contribute AI compute. This:

- **Incentivizes AI infrastructure**: Miners must run capable hardware with LLM support
- **Creates verifiable AI work**: Each block permanently records that AI inference occurred
- **Remains permissionless**: Any miner with Ollama installed can participate
- **Preserves decentralization**: Ollama runs locally - no centralized AI API dependency

### 4.3 Mining Methods

- **Solo Mining with Ollama**: Start Ollama + ShardCoin node, use `generatetoaddress` RPC
- **CPU Mining**: Using `cpuminer` with `--algo=scrypt` (AI proof handled by the node)
- **GPU Mining**: Using `cgminer` or `bfgminer` with Scrypt mode
- **ASIC Mining**: Any Scrypt-compatible ASIC hardware (node handles AI proof via `getblocktemplate`)

### 4.4 AI-Driven Fee Estimation

ShardCoin uses AI to recommend optimal transaction fees. The `estimateaifee` RPC command queries Ollama with current mempool conditions (transaction count, byte size, fee distribution) and a user-specified urgency level (low, normal, high). The AI analyzes demand and returns a fee rate recommendation with reasoning.

This replaces static fee lookup tables with adaptive, context-aware estimation that responds to real-time network conditions.

### 4.5 RPC Interface

ShardCoin provides AI-specific RPC commands:

| Command | Description |
|---------|-------------|
| `getaiinfo` | AI subsystem status - Ollama connection, model, available models |
| `getaichallenge` | Current AI challenge prompt for the next block |
| `getaiproof <hash>` | Extract AI proof from a specific block |
| `estimateaifee [urgency]` | AI-powered fee estimation (low/normal/high urgency) |
| `analyzaiblock <hash>` | AI analysis of block content, mining activity, and significance |
| `analyzaimempool` | AI analysis of mempool congestion, fees, and transaction advice |
| `analyzainetwork` | AI comprehensive network health report with chain metrics |

---

## 5. Protocol Features

### 5.1 Segregated Witness (SegWit)

Active from block 0. SegWit separates transaction signatures from transaction data, enabling:

- Transaction malleability fix
- ~4x effective block size increase via the weight system
- Foundation for Lightning Network compatibility
- More efficient signature validation

Native SegWit addresses use the bech32 format with the `shrd` prefix: `shrd1q...`

### 5.2 Taproot

Active from block 0 (BIPs 340, 341, 342). Taproot provides:

- Schnorr signatures (more efficient, enables signature aggregation)
- Merkelized Abstract Syntax Trees (MAST) for compact smart contracts
- Enhanced privacy - complex spending conditions look identical to simple payments on-chain
- Key-path spending for optimal efficiency in the common case

### 5.3 Mimblewimble Extension Blocks (MWEB)

Active from block 0. MWEB provides optional privacy-enhanced transactions through a Mimblewimble sidechain integrated via extension blocks:

- **Confidential Transactions**: Transaction amounts are hidden using Pedersen commitments
- **Peg-in / Peg-out**: Users can move funds between the main chain and the MWEB chain
- **Cut-through**: Intermediate transaction data can be pruned, reducing blockchain size
- **Optional privacy**: Users choose when to use MWEB for enhanced privacy

MWEB transactions use a separate address format with the `shrdmweb` prefix.

### 5.4 Feature Activation Strategy

Unlike Bitcoin and Litecoin, which activated features gradually over years of operation, ShardCoin activates all features from the genesis block:

- BIP16 (P2SH): Block 0
- BIP34 (Block v2): Block 0
- BIP65 (CHECKLOCKTIMEVERIFY): Block 0
- BIP66 (Strict DER): Block 0
- CSV (BIP68, 112, 113): Block 0
- SegWit (BIP141, 143, 147): Block 0
- Taproot (BIP340, 341, 342): Block 0
- MWEB: Block 0

This eliminates the complexity of activation signaling and soft-fork coordination, and ensures all users and miners operate with the full feature set from the start.

---

## 6. Wallet Architecture

### 6.1 ShardCoin Core Wallet (shardcoin-qt)

The built-in desktop wallet provides full node functionality with a graphical interface. It stores private keys locally and validates all transactions independently.

### 6.2 ShardWallet (PWA)

ShardWallet is a non-custodial Progressive Web App wallet that runs in any modern browser:

- **Client-side key management**: BIP39 seed phrases generated in the browser
- **HD derivation**: BIP32 key derivation at path `m/84'/1000'/0'/0/*`
- **Client-side signing**: Transactions are built and signed entirely in the browser using secp256k1 ECDSA
- **Zero trust**: The ShardCoin node is used only for reading blockchain data and broadcasting pre-signed transactions - it never receives private keys
- **Encrypted storage**: Seeds are encrypted with AES-256-GCM (PBKDF2, 200,000 iterations) in the browser's localStorage
- **Installable**: PWA manifest enables native-like installation on any device

### 6.3 Third-Party Wallet Compatibility

Any wallet supporting Bitcoin/Litecoin-compatible networks can be configured for ShardCoin using the network parameters defined in Section 2.2. This includes Electrum, Trust Wallet, Coinomi, and hardware wallets such as Ledger and Trezor with custom coin configurations.

---

## 7. Network Architecture

### 7.1 Peer-to-Peer Network

ShardCoin operates a decentralized peer-to-peer network. Nodes communicate using a binary protocol over TCP on port 7333. The network has no central servers, DNS seeds, or hardcoded seed nodes at launch - nodes discover peers through manual addition or future DNS seed infrastructure.

### 7.2 Transaction Propagation

Transactions are broadcast to all connected peers using an inventory-based relay protocol. Each node independently validates transactions against consensus rules before relaying them.

### 7.3 Block Propagation

New blocks are propagated using compact block relay (BIP152), reducing bandwidth by transmitting only short transaction IDs rather than full transaction data.

---

## 8. Security Considerations

### 8.1 51% Attack Resistance

As a new proof-of-work chain, ShardCoin's security depends on the total hash rate of the network. A Scrypt-based chain benefits from the existing ecosystem of Scrypt mining hardware. As the network grows, increasing hash rate provides greater resistance to majority attacks.

### 8.2 Replay Protection

ShardCoin uses unique network magic bytes (`0xd3 0xa2 0xc4 0xe7`) and a distinct genesis block, providing natural replay protection against Bitcoin, Litecoin, and all other networks.

### 8.3 Address Collision Prevention

ShardCoin uses unique address prefixes (P2PKH byte 63, bech32 `shrd`) that are distinct from all major networks, preventing accidental cross-chain address usage.

---

## 9. Comparison

| | Bitcoin | Litecoin | ShardCoin |
|---|---------|----------|-----------|
| Algorithm | SHA-256 | Scrypt | Scrypt + AI (PoAIW) |
| AI Integration | None | None | Ollama (local LLM) |
| Block Time | 10 min | 2.5 min | 2.5 min |
| Total Supply | 21M | 84M | ~8.4M |
| Emission | Halving/210k blocks | Halving/840k blocks | 10% decay/100k blocks |
| SegWit | Activated 2017 | Activated 2017 | Genesis |
| Taproot | Activated 2021 | Activated 2023 | Genesis |
| MWEB | No | Activated 2022 | Genesis |
| Privacy | Pseudonymous | MWEB optional | MWEB optional |

---

## 10. Conclusion

ShardCoin is the first cryptocurrency to integrate AI inference directly into its mining process. By requiring miners to perform local AI computation via Ollama and embedding cryptographic proofs in every block, ShardCoin creates a blockchain that incentivizes AI infrastructure while maintaining the security guarantees of traditional proof-of-work.

Combined with a smooth emission decay model, a scarce supply of ~8.4 million coins, and a complete feature set (SegWit, Taproot, MWEB) activated from genesis, ShardCoin represents a new class of AI-native digital currency - one where every block is proof that both computational work and artificial intelligence contributed to securing the network.

The project is open source under the MIT license.

---

## References

1. Nakamoto, S. (2008). *Bitcoin: A Peer-to-Peer Electronic Cash System*.
2. Lee, C. (2011). *Litecoin - a lite version of Bitcoin*.
3. Percival, C. (2009). *Stronger Key Derivation via Sequential Memory-Hard Functions* (Scrypt).
4. Wuille, P. (2015). *Segregated Witness* (BIP141).
5. Wuille, P., et al. (2020). *Taproot: SegWit version 1 spending rules* (BIPs 340-342).
6. Jedusor, T. (2016). *Mimblewimble*.
7. Poelstra, A. (2016). *Mimblewimble* (revised).

---

**Source Code**: [github.com/code2031/ShardCoin](https://github.com/code2031/ShardCoin)
**Web Wallet**: [github.com/code2031/ShardWallet](https://github.com/code2031/ShardWallet)
**License**: MIT
