# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShardCoin is an AI-native cryptocurrency forked from Litecoin Core (which itself is a fork of Bitcoin Core). It uses Scrypt proof-of-work augmented with AI Proof-of-Work (PoAIW) via Ollama, 2.5 minute block times, ~8.4M total supply (5 SHRD block reward with 10% decay every 100k blocks), and the ticker SHRD. The genesis block auto-mines on first run.

## Build Commands

```bash
# Full build (daemon only, no GUI)
./autogen.sh
./configure --without-gui
make -j$(nproc)

# Full build with Qt GUI
./autogen.sh
./configure
make -j$(nproc)

# Minimal build (no wallet, no GUI, no ZMQ)
./configure --disable-wallet --without-gui --disable-zmq
make -j$(nproc)

# Incremental rebuild after code changes (no autogen/configure needed)
make -j$(nproc)
```

**macOS dependencies**: `brew install automake libtool boost pkg-config libevent`
**Ubuntu dependencies**: `apt install build-essential libtool autotools-dev automake pkg-config bsdmainutils python3 libevent-dev libboost-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev libsqlite3-dev libssl-dev libfmt-dev libboost-thread-dev`

**With wallet support** (requires BDB): `apt install libdb-dev libdb++-dev` and add `--with-incompatible-bdb` to configure.
**With Qt GUI**: `apt install qtbase5-dev qttools5-dev qttools5-dev-tools libqrencode-dev`

## Testing

```bash
# Unit tests (C++, Boost test framework)
make check

# Single unit test suite
src/test/test_bitcoin --run_test=<suite_name>

# Functional tests (Python)
test/functional/test_runner.py

# Single functional test
test/functional/<test_name>.py

# Functional tests with parallelism
test/functional/test_runner.py --jobs=8

# Extended functional tests
test/functional/test_runner.py --extended

# Lint checks
test/lint/lint-all.sh
```

## Running

```bash
# Regtest (for development - instant mining, no real network)
src/shardcoind -regtest -daemon
src/shardcoin-cli -regtest createwallet "test"
src/shardcoin-cli -regtest -generate 101

# Regtest without AI (no Ollama needed)
src/shardcoind -regtest -daemon -noaiproof

# Mainnet (requires Ollama for mining)
ollama serve &
src/shardcoind -daemon
src/shardcoin-cli getblockchaininfo

# Check AI status
src/shardcoin-cli getaiinfo

# Stop
src/shardcoin-cli stop
```

## Architecture

### Library Structure (build order matters)

The codebase compiles into modular static libraries linked into the final binaries:

- **libbitcoin_crypto** - Low-level crypto (SHA256, Scrypt, secp256k1-zkp)
- **libbitcoin_consensus** - Consensus rules (script validation, merkle, tx verification). Deliberately minimal and isolated
- **libbitcoin_util** - Utilities (logging, args, filesystem, threading). No consensus or network code
- **libbitcoin_common** - Shared between daemon/CLI (key encoding, chain params, script utilities)
- **libbitcoin_server** - Full node (validation, mempool, net processing, RPC server, indexes, miner, AI proof)
- **libbitcoin_wallet** - Wallet (coin selection, key management, BDB/SQLite storage). Optional
- **libbitcoin_cli** - RPC client logic
- **libbitcoin_zmq** - ZeroMQ notification publisher. Optional

### Key Source Directories

- `src/ai/` - AI Proof-of-Work: Ollama client (`ollama.h/cpp`) and AI proof logic (`aiproof.h/cpp`)
- `src/consensus/` - Consensus-critical code (isolated, minimal dependencies)
- `src/primitives/` - Block and transaction data structures (`block.h`, `transaction.h`)
- `src/script/` - Script interpreter, descriptor parsing
- `src/validation.cpp` - Block/transaction validation (the largest and most critical file)
- `src/miner.cpp` - Block assembly and coinbase creation (includes AI proof embedding)
- `src/net.cpp` / `src/net_processing.cpp` - P2P networking and message handling
- `src/rpc/` - JSON-RPC interface (one file per domain: mining, blockchain, wallet, etc.)
- `src/wallet/` - Wallet implementation (48+ files)
- `src/interfaces/` - Abstract interfaces separating node/wallet/chain (for modularity)
- `src/qt/` - GUI application (125+ files, Qt 5)
- `src/libmw/` - Mimblewimble library (MWEB privacy extension)
- `src/mweb/` - MWEB integration with the main codebase

### Chain Parameters

All network-defining parameters are in `src/chainparams.cpp`:
- Genesis block (timestamp, nonce, hash)
- Network magic bytes, ports, address prefixes
- BIP activation heights
- DNS seeds, checkpoints

`src/chainparamsbase.cpp` defines RPC/P2P port mappings per network.

### Embedded Dependencies

These live in-tree and are built as part of the project (do not update independently):
- `src/leveldb/` - Key-value store for blockchain/UTXO database
- `src/secp256k1-zkp/` - Elliptic curve library with zero-knowledge proof extensions
- `src/univalue/` - JSON parser
- `src/crc32c/` - CRC32C checksums

### Binary Targets

| Binary | Source | Purpose |
|--------|--------|---------|
| `shardcoind` | `src/bitcoind.cpp` | Full node daemon |
| `shardcoin-cli` | `src/bitcoin-cli.cpp` | RPC client |
| `shardcoin-tx` | `src/bitcoin-tx.cpp` | Offline transaction tool |
| `shardcoin-wallet` | `src/bitcoin-wallet.cpp` | Offline wallet tool |
| `shardcoin-qt` | `src/qt/bitcoin.cpp` | GUI wallet |

Note: Source filenames retain `bitcoin` prefix from upstream - only binary output names were changed in `configure.ac` and `Makefile.am`.

## Key Codebase Patterns

### Locking

RAII locking via `src/sync.h`. The primary global lock is `cs_main` (declared in `validation.h`) which guards all blockchain state.

- `LOCK(cs_main)` - Acquire a single lock (scoped RAII)
- `LOCK2(cs_main, m_mempool.cs)` - Acquire two locks in order (deadlock-safe)
- `WITH_LOCK(cs, expr)` - Inline lock for single expressions
- `EXCLUSIVE_LOCKS_REQUIRED(cs_main)` - Thread-safety annotation (Clang checked)
- `AssertLockHeld(cs_main)` - Debug assertion that lock is held

### Adding New RPC Commands

Register in `src/rpc/<domain>.cpp`. Pattern:

```cpp
static RPCHelpMan mycommand()
{
    return RPCHelpMan{"mycommand",
        "\nDescription.\n",
        { /* RPCArg entries */ },
        RPCResult{RPCResult::Type::OBJ, "", "", { /* fields */ }},
        RPCExamples{HelpExampleCli("mycommand", "")},
        [&](const RPCHelpMan& self, const JSONRPCRequest& request) -> UniValue
    {
        LOCK(cs_main);
        UniValue obj(UniValue::VOBJ);
        obj.pushKV("key", value);
        return obj;
    },
    };
}
```

Then add to the command table in the `Register*RPCCommands()` function at the bottom of the file. The registration function must be declared in `src/rpc/register.h`.

### Logging

Two tiers defined in `src/logging.h`:

- `LogPrintf("message %s\n", val)` - Always logs (unconditional)
- `LogPrint(BCLog::BENCH, "message %s\n", val)` - Only logs if category enabled

Categories: `NET`, `TOR`, `MEMPOOL`, `HTTP`, `BENCH`, `ZMQ`, `RPC`, `VALIDATION`, `COINDB`, `QT`, `LEVELDB`, etc.

### Arguments (gArgs)

Global `ArgsManager gArgs` in `src/util/system.h`:

- `gArgs.GetArg("-option", "default")` - String value
- `gArgs.GetBoolArg("-option", false)` - Boolean (supports `-nooption` syntax)
- `gArgs.IsArgSet("-option")` - Check if explicitly set

Register new args in `src/init.cpp` `SetupServerArgs()`:
```cpp
argsman.AddArg("-myopt=<val>", "Description", ArgsManager::ALLOW_ANY, OptionsCategory::OPTIONS);
```

### Serialization

`SERIALIZE_METHODS` macro in `src/serialize.h` generates both serialize/deserialize:

```cpp
SERIALIZE_METHODS(MyType, obj) {
    READWRITE(obj.field1, obj.field2);
}
```

### Error Handling in Validation

`ValidationState<T>` pattern (`src/consensus/validation.h`):

```cpp
BlockValidationState state;
if (!CheckBlock(block, state, params)) {
    // state.GetRejectReason() has the error
    return state.Invalid(BlockValidationResult::BLOCK_CONSENSUS, "reason", "debug msg");
}
```

### Optional Type

This codebase uses `Optional<T>` (alias for `boost::optional<T>`) from `src/optional.h`, not `std::optional`.

### Unit Test Pattern

Boost Test in `src/test/`:

```cpp
BOOST_FIXTURE_TEST_SUITE(my_tests, BasicTestingSetup)
BOOST_AUTO_TEST_CASE(test_something)
{
    BOOST_CHECK_EQUAL(actual, expected);
}
BOOST_AUTO_TEST_SUITE_END()
```

Fixtures: `BasicTestingSetup` (minimal), `TestingSetup` (full chain + mempool).

### Functional Test Pattern

Python in `test/functional/`:

```python
class MyTest(BitcoinTestFramework):
    def set_test_params(self):
        self.num_nodes = 1
    def run_test(self):
        self.nodes[0].generate(1)
        assert_equal(self.nodes[0].getblockcount(), 1)
if __name__ == '__main__':
    MyTest().main()
```

## ShardCoin-Specific Changes from Litecoin

- Currency unit: SHRD (defined in `src/policy/feerate.h` as `CURRENCY_UNIT`)
- Address prefix: `S` for mainnet (base58 prefix 63), bech32 `shrd`
- P2P port 7333, RPC port 7332 (mainnet)
- Network magic: `0xd3 0xa2 0xc4 0xe7`
- Data directory: `~/.shardcoin` (Linux), `~/Library/Application Support/ShardCoin` (macOS)
- Config file: `shardcoin.conf`
- Block reward: 5 SHRD with smooth 10% decay every 100,000 blocks (in `GetBlockSubsidy()` in `validation.cpp`)
- Total supply: ~8.4M SHRD (MAX_MONEY in `amount.h`)
- Genesis block includes auto-miner in `MineGenesisBlock()` function in `chainparams.cpp`
- All BIPs + Taproot + MWEB activated from block 0
- Empty checkpoints map guarded with `.empty()` check in `chainparams.h`
- No DNS seeds or checkpoints (fresh chain)
- AI Proof-of-Work via Ollama (see below)

## AI Proof-of-Work (PoAIW)

ShardCoin integrates local AI inference into the mining process via Ollama. Miners must run Ollama; validators do not.

### Architecture

- `src/ai/ollama.h/cpp` - HTTP client for the Ollama API (default: localhost:11434). Uses POSIX sockets.
- `src/ai/aiproof.h/cpp` - AI proof creation, serialization, extraction from blocks, and validation
- Global client: `g_ollama` (std::unique_ptr, initialized in `init.cpp`, used in `miner.cpp` and `rpc/mining.cpp`)

### Mining Flow

1. `BlockAssembler::CreateNewBlock()` generates a deterministic challenge via `GetAIChallenge(prev_hash, height)`
2. Sends challenge to Ollama via `g_ollama->Generate(model, prompt)`
3. Creates proof via `CreateAIProof(response, model)` - hashes response and model name
4. Embeds 41-byte proof in coinbase OP_RETURN via `BuildAIProofScript(proof)`
5. Proof format: `[magic "AIPR" 4B] [version 1B] [response_hash 32B] [model_tag 4B]`
6. Standard Scrypt PoW proceeds as normal

### Validation

`CheckBlock()` in `validation.cpp` extracts and validates AI proof format via `ExtractAIProof()`. Validation does NOT require Ollama - it only checks proof format and commitment integrity.

### Configuration

CLI args registered in `init.cpp`: `-aiproof` (default: on), `-ollamahost`, `-ollamaport`, `-ollamamodel` (default: `llama3.2:1b`)

### RPC Commands

Registered in `rpc/mining.cpp` under the `"ai"` category:
- `getaiinfo` - Ollama status, model info, available models
- `getaichallenge` - Current AI challenge for next block
- `getaiproof <blockhash>` - Extract AI proof from a block
- `estimateaifee [urgency]` - AI-powered fee estimation (queries Ollama with mempool stats)
- `analyzaiblock <blockhash>` - AI analysis of a specific block
- `analyzaimempool` - AI analysis of current mempool state
- `analyzainetwork` - AI comprehensive network health report

## Web Services

- `website_flutter/` - Flutter web app (port 4401): project site with 5 tabs (Home, Technology, Download, Network, Explorer link). Build with `flutter build web --release`, serve with `node serve.js`.
- `explorer_flutter/` - Flutter web app (port 4402): standalone blockchain explorer with block/tx/AI proof browsing. Build with `flutter build web --release`, serve with `node serve.js`. The serve.js also provides the JSON API (`/api/*`) that calls `shardcoin-cli`.
- `explorer/` - Legacy HTML explorer (superseded by explorer_flutter)
- `website/` - Legacy HTML site (superseded by website_flutter)
- `scripts/sync-chain-data.sh` - Exports blockchain data to GitHub repo (code2031/ShardChain-data) via cron every 5 min

Both Flutter apps are served by their respective `serve.js` (Node.js static file server with SPA fallback). Set `SHARDCOIN_CLI` and `SHARDCOIN_CLI_ARGS` env vars for the explorer.

## Third-Party Wallet Integration

When configuring external wallets for ShardCoin, these are the network parameters:
- P2PKH prefix: 63, P2SH prefix: 5, WIF prefix: 191
- Bech32 HRP: `shrd`, BIP44 coin type: 1000
- BIP32 public: `0x0488B21E`, BIP32 private: `0x0488ADE4`

Official PWA wallet: [github.com/code2031/ShardWallet](https://github.com/code2031/ShardWallet)

## Code Formatting

C++ formatting rules are defined in `src/.clang-format`: 4-space indent, no tabs, no column limit, left-aligned pointers (`int* p`), braces on new line for classes/functions. Run `clang-format -i src/file.cpp` to format.
