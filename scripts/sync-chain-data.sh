#!/bin/bash
# Syncs blockchain data to the ShardChain-data GitHub repo.
# Run via cron on the node: */5 * * * * /home/pi/shardcoin/scripts/sync-chain-data.sh

CLI="${SHARDCOIN_CLI:-/home/pi/shardcoin/bin/shardcoin-cli}"
CLI_ARGS="${SHARDCOIN_CLI_ARGS:--conf=/home/pi/shardcoin/shardcoin.conf -datadir=/home/pi/shardcoin/data}"
REPO_DIR="${CHAIN_DATA_DIR:-/home/pi/shardcoin/chain-data}"
export LD_LIBRARY_PATH="/home/pi/shardcoin/lib:$LD_LIBRARY_PATH"

# Ensure repo exists
if [ ! -d "$REPO_DIR/.git" ]; then
    git clone https://github.com/code2031/ShardChain-data.git "$REPO_DIR" 2>/dev/null || {
        mkdir -p "$REPO_DIR" && cd "$REPO_DIR" && git init && git remote add origin https://github.com/code2031/ShardChain-data.git
    }
fi

cd "$REPO_DIR" || exit 1

# Get chain info
INFO=$($CLI $CLI_ARGS getblockchaininfo 2>/dev/null)
if [ -z "$INFO" ]; then
    echo "Node not responding" >&2
    exit 1
fi

HEIGHT=$(echo "$INFO" | python3 -c "import sys,json; print(json.load(sys.stdin)['blocks'])")
CHAIN=$(echo "$INFO" | python3 -c "import sys,json; print(json.load(sys.stdin)['chain'])")

# Export chain info
echo "$INFO" | python3 -m json.tool > chain_info.json

# Export latest blocks
mkdir -p blocks
for i in $(seq $((HEIGHT > 19 ? HEIGHT - 19 : 0)) $HEIGHT); do
    HASH=$($CLI $CLI_ARGS getblockhash $i 2>/dev/null)
    if [ -n "$HASH" ] && [ ! -f "blocks/${i}.json" ]; then
        $CLI $CLI_ARGS getblock "$HASH" 1 2>/dev/null | python3 -m json.tool > "blocks/${i}.json" 2>/dev/null
    fi
done

# Export AI proofs
mkdir -p ai_proofs
for i in $(seq $((HEIGHT > 19 ? HEIGHT - 19 : 0)) $HEIGHT); do
    HASH=$($CLI $CLI_ARGS getblockhash $i 2>/dev/null)
    if [ -n "$HASH" ] && [ ! -f "ai_proofs/${i}.json" ]; then
        PROOF=$($CLI $CLI_ARGS getaiproof "$HASH" 2>/dev/null)
        if [ -n "$PROOF" ]; then
            echo "$PROOF" | python3 -m json.tool > "ai_proofs/${i}.json" 2>/dev/null
        fi
    fi
done

# Generate README
cat > README.md << HEREDOC
# ShardCoin Blockchain Data

Live blockchain data from the ShardCoin network, auto-updated every 5 minutes.

## Chain Status

- **Chain**: $CHAIN
- **Height**: $HEIGHT
- **Last Updated**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Structure

- \`chain_info.json\` - Current chain state
- \`blocks/\` - Block data (JSON, one per block)
- \`ai_proofs/\` - AI proof data extracted from blocks

## ShardCoin

ShardCoin is an AI-native cryptocurrency. Every block includes proof of AI inference via Ollama.

- [Source Code](https://github.com/code2031/ShardCoin)
- [Whitepaper](https://github.com/code2031/ShardCoin/blob/master/WHITEPAPER.md)
- [Explorer](http://node.local:4402)
HEREDOC

# Commit and push
git add -A
if ! git diff --cached --quiet; then
    git commit -m "Chain update: height $HEIGHT ($(date -u +%Y-%m-%d\ %H:%M))" --author="ShardCoin Node <node@shardcoin.local>"
    git push origin main 2>/dev/null || git push origin master 2>/dev/null
fi
