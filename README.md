ShardCoin Core
=====================================

What is ShardCoin?
------------------

ShardCoin (SHRD) is a peer-to-peer cryptocurrency forked from Litecoin Core. It uses the Scrypt proof-of-work algorithm, enabling mining with consumer hardware. ShardCoin operates on a fully decentralized network with no central authority — transactions and coin issuance are managed collectively by the network.

ShardCoin includes MWEB (Mimblewimble Extension Blocks) for optional privacy-enhanced transactions, Taproot for smart contract capabilities, and full SegWit support — all activated from block 0.

### Key Parameters

| Parameter | Value |
|-----------|-------|
| Algorithm | Scrypt (Proof of Work) |
| Block Time | 2.5 minutes |
| Total Supply | ~8,400,000 SHRD |
| Block Reward | 5 SHRD (decreases 10% every 100,000 blocks) |
| P2P Port | 7333 (mainnet) |
| RPC Port | 7332 (mainnet) |
| Address Prefix | S (mainnet), bech32: `shrd1...` |
| Smallest Unit | 1 shard = 0.00000001 SHRD |

License
-------

ShardCoin Core is released under the terms of the MIT license. See [COPYING](COPYING) for more information or see https://opensource.org/licenses/MIT.

Building from Source
--------------------

### Dependencies

**macOS:**
```bash
brew install automake libtool boost pkg-config libevent
```

**Ubuntu/Debian:**
```bash
sudo apt install build-essential libtool autotools-dev automake pkg-config \
  bsdmainutils python3 libevent-dev libboost-dev libboost-system-dev \
  libboost-filesystem-dev libboost-test-dev libsqlite3-dev
```

See platform-specific build guides for full details:
- [Unix/Linux](doc/build-unix.md)
- [macOS](doc/build-osx.md)
- [Windows](doc/build-windows.md)
- [FreeBSD](doc/build-freebsd.md)

### Build

```bash
./autogen.sh
./configure
make -j$(nproc)
```

To build without the GUI wallet:
```bash
./configure --without-gui
```

After building, binaries are located in `src/`:
- `shardcoind` — Full node daemon
- `shardcoin-cli` — Command-line RPC client
- `shardcoin-tx` — Transaction utility
- `shardcoin-wallet` — Wallet utility
- `shardcoin-qt` — GUI wallet (if built with Qt)

Running
-------

### First Run

On first startup, ShardCoin will mine its genesis block (this happens automatically and takes a few seconds).

```bash
# Start the daemon
./src/shardcoind -daemon

# Check blockchain status
./src/shardcoin-cli getblockchaininfo

# Stop the daemon
./src/shardcoin-cli stop
```

### Regtest Mode (for development/testing)

```bash
# Start in regtest mode (instant block mining, isolated network)
./src/shardcoind -regtest -daemon

# Create a wallet
./src/shardcoin-cli -regtest createwallet "main"

# Get a new address
./src/shardcoin-cli -regtest getnewaddress

# Mine 101 blocks (coins mature after 100 confirmations)
./src/shardcoin-cli -regtest -generate 101

# Check balance
./src/shardcoin-cli -regtest getbalance
```

### Configuration

Create `~/.shardcoin/shardcoin.conf` (Linux) or `~/Library/Application Support/ShardCoin/shardcoin.conf` (macOS):

```ini
# Enable RPC server
server=1
rpcuser=yourusername
rpcpassword=yourpassword

# Run in the background
daemon=1
```

### Network Ports

| Network | P2P Port | RPC Port |
|---------|----------|----------|
| Mainnet | 7333 | 7332 |
| Testnet | 17335 | 17332 |
| Regtest | 17444 | 17443 |

Testing
-------

```bash
# Run unit tests
make check

# Run functional tests (requires Python 3)
test/functional/test_runner.py

# Run a single functional test
test/functional/feature_block.py

# Run lint checks
test/lint/lint-all.sh
```

Compatible Wallets
------------------

Any wallet that supports Bitcoin/Litecoin-compatible networks can be used with ShardCoin by configuring these parameters:

| Parameter | Value |
|-----------|-------|
| Coin | ShardCoin (SHRD) |
| Algorithm | Scrypt |
| P2PKH prefix | 63 (addresses start with `S`) |
| P2SH prefix | 5 |
| WIF prefix | 191 |
| Bech32 HRP | `shrd` |
| BIP32 public | `0x0488B21E` |
| BIP32 private | `0x0488ADE4` |
| BIP44 coin type | 1000 |
| Default port | 7333 |
| RPC port | 7332 |

**Compatible wallet software:**
- **Electrum** — add ShardCoin as a custom network (fork Electrum-LTC and change parameters)
- **Trust Wallet / Coinomi** — support custom coin configurations
- **Any Bitcoin/Litecoin-compatible hardware wallet** (Ledger, Trezor) — with custom app or coin config
- **ShardWallet** — our official PWA wallet ([github.com/code2031/ShardWallet](https://github.com/code2031/ShardWallet))
- **shardcoin-qt** — built-in GUI desktop wallet (included with ShardCoin Core)

For RPC-compatible wallets, point them at `http://127.0.0.1:7332` with your configured `rpcuser`/`rpcpassword`.

Development
-----------

ShardCoin Core is a fork of Litecoin Core, which is itself a fork of Bitcoin Core. The codebase follows Bitcoin Core's architecture and coding conventions. See [doc/developer-notes.md](doc/developer-notes.md) for development guidelines.

### Adding Seed Nodes

To connect nodes on the network, add seed nodes to `src/chainparamsseeds.h` or use the `-addnode` flag:

```bash
./src/shardcoind -addnode=<ip:port>
```

### Mining

ShardCoin uses Scrypt proof-of-work. To solo mine in regtest:

```bash
./src/shardcoin-cli -regtest -generate <num_blocks>
```

For real mining on mainnet/testnet, use a Scrypt-compatible mining application pointed at the ShardCoin RPC interface.
