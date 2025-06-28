#!/bin/bash

# Geth 私有链启动脚本 - 最简版本
# 专门配合 Blockscout 使用，不自动解锁账户

set -e

# 配置变量
CHAIN_ID=12345
DATADIR="./my-private-chain"
GENESIS_FILE="./genesis.json"
NETWORK_ID=12345

# 检查 geth
if ! command -v geth &> /dev/null; then
    if [ -f "/home/monero/go-ethereum/build/bin/geth" ]; then
        GETH_CMD="/home/monero/go-ethereum/build/bin/geth"
    else
        echo "错误: 找不到 geth"
        exit 1
    fi
else
    GETH_CMD="geth"
fi

echo "=== 启动 Geth 私有链 ==="
echo "HTTP RPC: http://0.0.0.0:8545"
echo "WebSocket: ws://0.0.0.0:8546"

# 启动 Geth - 最基本配置
$GETH_CMD \
    --datadir $DATADIR \
    --networkid $NETWORK_ID \
    --http \
    --http.addr "0.0.0.0" \
    --http.port 8545 \
    --http.api "eth,net,web3,personal,miner,admin,debug,txpool" \
    --http.corsdomain "*" \
    --http.vhosts "*" \
    --ws \
    --ws.addr "0.0.0.0" \
    --ws.port 8546 \
    --ws.api "eth,net,web3,personal,miner,admin,debug,txpool" \
    --ws.origins "*" \
    --syncmode full \
    --gcmode archive \
    --allow-insecure-unlock \
    --nodiscover \
    --maxpeers 0 \
    --mine \
    --miner.threads 1 \
    --verbosity 3
