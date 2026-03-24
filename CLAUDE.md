# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShardCoin is a cryptocurrency forked from Litecoin Core (which itself is a fork of Bitcoin Core). It uses Scrypt proof-of-work, 2.5 minute block times, ~8.4M total supply (5 SHRD block reward with 10% decay every 100k blocks), and the ticker SHRD. The genesis block auto-mines on first run.

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

# Mainnet
src/shardcoind -daemon
src/shardcoin-cli getblockchaininfo

# Stop
src/shardcoin-cli stop
```

## Architecture

### Library Structure (build order matters)

The codebase compiles into modular static libraries linked into the final binaries:

- **libbitcoin_crypto** — Low-level crypto (SHA256, Scrypt, secp256k1-zkp)
- **libbitcoin_consensus** — Consensus rules (script validation, merkle, tx verification). Deliberately minimal and isolated
- **libbitcoin_util** — Utilities (logging, args, filesystem, threading). No consensus or network code
- **libbitcoin_common** — Shared between daemon/CLI (key encoding, chain params, script utilities)
- **libbitcoin_server** — Full node (validation, mempool, net processing, RPC server, indexes, miner)
- **libbitcoin_wallet** — Wallet (coin selection, key management, BDB/SQLite storage). Optional
- **libbitcoin_cli** — RPC client logic
- **libbitcoin_zmq** — ZeroMQ notification publisher. Optional

### Key Source Directories

- `src/consensus/` — Consensus-critical code (isolated, minimal dependencies)
- `src/primitives/` — Block and transaction data structures
- `src/script/` — Script interpreter, descriptor parsing
- `src/validation.cpp` — Block/transaction validation (the largest and most critical file)
- `src/net.cpp` / `src/net_processing.cpp` — P2P networking and message handling
- `src/rpc/` — JSON-RPC interface (one file per domain: mining, blockchain, wallet, etc.)
- `src/wallet/` — Wallet implementation (48+ files)
- `src/interfaces/` — Abstract interfaces separating node/wallet/chain (for modularity)
- `src/qt/` — GUI application (125+ files, Qt 5)
- `src/libmw/` — Mimblewimble library (MWEB privacy extension)
- `src/mweb/` — MWEB integration with the main codebase

### Chain Parameters

All network-defining parameters are in `src/chainparams.cpp`:
- Genesis block (timestamp, nonce, hash)
- Network magic bytes, ports, address prefixes
- BIP activation heights
- DNS seeds, checkpoints

`src/chainparamsbase.cpp` defines RPC/P2P port mappings per network.

### Embedded Dependencies

These live in-tree and are built as part of the project (do not update independently):
- `src/leveldb/` — Key-value store for blockchain/UTXO database
- `src/secp256k1-zkp/` — Elliptic curve library with zero-knowledge proof extensions
- `src/univalue/` — JSON parser
- `src/crc32c/` — CRC32C checksums

### Binary Targets

| Binary | Source | Purpose |
|--------|--------|---------|
| `shardcoind` | `src/bitcoind.cpp` | Full node daemon |
| `shardcoin-cli` | `src/bitcoin-cli.cpp` | RPC client |
| `shardcoin-tx` | `src/bitcoin-tx.cpp` | Offline transaction tool |
| `shardcoin-wallet` | `src/bitcoin-wallet.cpp` | Offline wallet tool |
| `shardcoin-qt` | `src/qt/bitcoin.cpp` | GUI wallet |

Note: Source filenames retain `bitcoin` prefix from upstream — only binary output names were changed in `configure.ac` and `Makefile.am`.

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

## Third-Party Wallet Integration

When configuring external wallets for ShardCoin, these are the network parameters:
- P2PKH prefix: 63, P2SH prefix: 5, WIF prefix: 191
- Bech32 HRP: `shrd`, BIP44 coin type: 1000
- BIP32 public: `0x0488B21E`, BIP32 private: `0x0488ADE4`

Official PWA wallet: [github.com/code2031/ShardWallet](https://github.com/code2031/ShardWallet)

## Code Formatting

C++ formatting rules are defined in `src/.clang-format`. The codebase follows Bitcoin Core style conventions documented in `doc/developer-notes.md`.
