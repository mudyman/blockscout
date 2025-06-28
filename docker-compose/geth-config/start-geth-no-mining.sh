#!/bin/bash

# Geth 私有链启动脚本 - 无挖矿版本
# 先启动 RPC 服务，稍后手动启动挖矿

set -e

DATADIR="./my-private-chain"
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

echo "=== 启动 Geth 私有链 (无挖矿) ==="
echo "HTTP RPC: http://0.0.0.0:8545"
echo "WebSocket: ws://0.0.0.0:8546"

# 启动 Geth - 不挖矿
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
    --verbosity 3
