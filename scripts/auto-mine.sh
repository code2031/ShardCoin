#!/bin/bash
# Auto-mining script for ShardCoin regtest
# Mines a block every ~150 seconds (2.5 min) to match target block time
# Also sends periodic transactions to keep the chain active
#
# Usage: nohup ./scripts/auto-mine.sh >> ~/shardcoin/mine.log 2>&1 &
# Or run as a systemd service

export LD_LIBRARY_PATH="/home/pi/shardcoin/lib:$LD_LIBRARY_PATH"
CLI="${SHARDCOIN_CLI:-/home/pi/shardcoin/bin/shardcoin-cli}"
CONF="${SHARDCOIN_CONF:--conf=/home/pi/shardcoin/shardcoin.conf -datadir=/home/pi/shardcoin/data}"
MINE_ADDR="${MINE_ADDR:-rshrd1qy93h2alrelahaalasxhp6tn768aefnhcf4usjd}"
INTERVAL="${MINE_INTERVAL:-150}"

rpc() {
    $CLI $CONF "$@" 2>/dev/null
}

echo "[$(date)] Auto-miner starting (interval: ${INTERVAL}s, addr: ${MINE_ADDR})"

# Ensure wallet is loaded
rpc loadwallet "main" > /dev/null 2>&1

BLOCK_COUNT=0

while true; do
    # Mine 1 block
    RESULT=$(rpc generatetoaddress 1 "$MINE_ADDR")
    if [ -n "$RESULT" ]; then
        HEIGHT=$(rpc getblockcount)
        BALANCE=$(rpc getbalance)
        echo "[$(date)] Block mined! Height: $HEIGHT, Balance: $BALANCE SHRD"
        BLOCK_COUNT=$((BLOCK_COUNT + 1))

        # Every 5 blocks, send a transaction to another address to create activity
        if [ $((BLOCK_COUNT % 5)) -eq 0 ]; then
            # Generate a new address and send some SHRD to it
            NEW_ADDR=$(rpc getnewaddress "auto-tx-$BLOCK_COUNT")
            if [ -n "$NEW_ADDR" ]; then
                TXID=$(rpc sendtoaddress "$NEW_ADDR" 0.1 "auto-tx" "auto-miner" false)
                if [ -n "$TXID" ]; then
                    echo "[$(date)] TX sent: $TXID -> $NEW_ADDR (0.1 SHRD)"
                fi
            fi
        fi
    else
        echo "[$(date)] Mining failed, retrying..."
    fi

    sleep "$INTERVAL"
done
