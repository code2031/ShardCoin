ShardCoin Core
=====================================

What is ShardCoin?
------------------

ShardCoin (SHRD) is the first AI-native cryptocurrency. It integrates local AI inference directly into the mining process via [Ollama](https://ollama.com), requiring miners to perform AI computation for every block they produce. Each block carries a cryptographic proof of AI work embedded in the coinbase transaction.

Built on the proven Litecoin/Bitcoin Core architecture, ShardCoin uses Scrypt proof-of-work augmented with AI Proof-of-Work (PoAIW). It includes MWEB (Mimblewimble Extension Blocks) for optional privacy, Taproot for smart contracts, and full SegWit support - all activated from block 0.

### Key Parameters

| Parameter | Value |
|-----------|-------|
| Algorithm | Scrypt + AI Proof-of-Work (PoAIW) |
| AI Backend | Ollama (local inference) |
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
- `shardcoind` - Full node daemon
- `shardcoin-cli` - Command-line RPC client
- `shardcoin-tx` - Transaction utility
- `shardcoin-wallet` - Wallet utility
- `shardcoin-qt` - GUI wallet (if built with Qt)

AI Mining (Ollama)
------------------

ShardCoin requires [Ollama](https://ollama.com) for AI-powered mining. Each block includes a cryptographic proof that the miner performed AI inference.

### Setup

1. Install Ollama: https://ollama.com/download
2. Pull a model:
   ```bash
   ollama pull llama3.2:1b
   ```
3. Ollama runs automatically on `localhost:11434`

### How It Works

When mining a block, ShardCoin:
1. Generates a deterministic AI challenge from the previous block hash and height
2. Sends the challenge to your local Ollama instance
3. Hashes the AI response and embeds the proof in the coinbase transaction (OP_RETURN)
4. Completes standard Scrypt proof-of-work

Validators check the AI proof format without re-running inference, so non-mining nodes do not need Ollama.

### Configuration

Add to `shardcoin.conf` or pass as command-line flags:

```ini
# Enable/disable AI proof (default: 1)
aiproof=1

# Ollama connection (defaults shown)
ollamahost=127.0.0.1
ollamaport=11434
ollamamodel=llama3.2:1b
```

### AI RPC Commands

```bash
# Check AI subsystem status
./src/shardcoin-cli getaiinfo

# Get the AI challenge for the next block
./src/shardcoin-cli getaichallenge

# Extract AI proof from a mined block
./src/shardcoin-cli getaiproof <blockhash>

# AI-powered fee estimation (requires Ollama)
./src/shardcoin-cli estimateaifee          # normal urgency
./src/shardcoin-cli estimateaifee "high"   # next-block priority
./src/shardcoin-cli estimateaifee "low"    # minimize fee

# AI analysis commands
./src/shardcoin-cli analyzaiblock <hash>   # AI block analysis
./src/shardcoin-cli analyzaimempool        # AI mempool analysis
./src/shardcoin-cli analyzainetwork        # AI network health report
```

Web Services
------------

### ShardCoin Website (port 4401) - Flutter

```bash
cd website_flutter
flutter build web --release
node serve.js
```

Flutter web app with 5 tabs: Home, Technology, Download, Network, Explorer. The Explorer tab links to the standalone explorer on port 4402.

### Blockchain Explorer (port 4402) - Flutter

```bash
cd explorer_flutter
flutter build web --release
SHARDCOIN_CLI=./src/shardcoin-cli node serve.js
```

Standalone Flutter blockchain explorer. Features:
- Search by block height, block hash, txid, or wallet address (S... or shrd1...)
- Full transaction detail per block: FROM addresses, TO addresses, amounts, fees
- Sender addresses resolved from previous transaction outputs
- OP_RETURN and AI PROOF outputs detected and labeled
- Coinbase (mining reward) transactions tagged
- Address lookup with balance, UTXOs, and full transaction history
- Block detail: confirmations, block reward, total fees, total output, chain work, merkle root, median time, bits, stripped size, next/previous block navigation
- Transaction detail: confirmations, block time, inputs with source txid, outputs with clickable addresses, virtual size, weight
- AI proof display with response hash and model tag
- Auto AI insights on every page: network analysis, mempool analysis, fee recommendation, block analysis (via deepseek-r1:32b)
- Live auto-refresh every 30s
- All links functional: footer opens GitHub/Releases/ShardWallet/Chain Data, logo returns home

The serve.js provides both the Flutter app and JSON API (`/api/*`).

Running
-------

### First Run

On first startup, ShardCoin will mine its genesis block (this happens automatically and takes a few seconds). Make sure Ollama is running if you plan to mine.

```bash
# Start Ollama (if not already running)
ollama serve &

# Start the daemon
./src/shardcoind -daemon

# Check blockchain status
./src/shardcoin-cli getblockchaininfo

# Check AI status
./src/shardcoin-cli getaiinfo

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
- **Electrum** - add ShardCoin as a custom network (fork Electrum-LTC and change parameters)
- **Trust Wallet / Coinomi** - support custom coin configurations
- **Any Bitcoin/Litecoin-compatible hardware wallet** (Ledger, Trezor) - with custom app or coin config
- **ShardWallet** - our official PWA wallet ([github.com/code2031/ShardWallet](https://github.com/code2031/ShardWallet))
- **shardcoin-qt** - built-in GUI desktop wallet (included with ShardCoin Core)

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

ShardCoin uses Scrypt proof-of-work combined with AI Proof-of-Work. To solo mine in regtest:

```bash
# Make sure Ollama is running
ollama serve &

./src/shardcoin-cli -regtest -generate <num_blocks>
```

For mining without AI proof (e.g., testing without Ollama):
```bash
./src/shardcoind -regtest -daemon -noaiproof
```

For real mining on mainnet/testnet, ensure Ollama is running with your preferred model, then use `getblocktemplate` or the built-in `generatetoaddress` RPC.
