#!/bin/bash

# Geth 私有链启动脚本 - 专门配合 Blockscout 使用
# 此脚本会启动一个与 Blockscout 完全兼容的 Geth 私有链

set -e

# 配置变量
CHAIN_ID=12345
DATADIR="./my-private-chain"
GENESIS_FILE="./genesis.json"
NETWORK_ID=12345

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Geth 私有链启动脚本 (Blockscout 兼容版) ===${NC}"

# 检查 geth 是否存在
if ! command -v geth &> /dev/null; then
    if [ -f "/home/monero/go-ethereum/build/bin/geth" ]; then
        echo -e "${YELLOW}使用本地编译的 geth: /home/monero/go-ethereum/build/bin/geth${NC}"
        GETH_CMD="/home/monero/go-ethereum/build/bin/geth"
    else
        echo -e "${RED}错误: 找不到 geth 可执行文件${NC}"
        echo -e "${YELLOW}请确保:${NC}"
        echo -e "  1. geth 已安装并在 PATH 中，或者"
        echo -e "  2. /home/monero/go-ethereum/build/bin/geth 存在"
        exit 1
    fi
else
    GETH_CMD="geth"
fi

echo -e "${GREEN}使用 Geth: $GETH_CMD${NC}"

# 检查 genesis.json 文件
if [ ! -f "$GENESIS_FILE" ]; then
    echo -e "${RED}错误: genesis.json 文件不存在${NC}"
    echo -e "${YELLOW}请确保 genesis.json 文件存在于当前目录${NC}"
    exit 1
fi

# 初始化创世块（仅在数据目录不存在时）
if [ ! -d "$DATADIR" ]; then
    echo -e "${YELLOW}初始化创世块...${NC}"
    $GETH_CMD --datadir $DATADIR init $GENESIS_FILE
    echo -e "${GREEN}创世块初始化完成${NC}"
else
    echo -e "${YELLOW}数据目录已存在，跳过创世块初始化${NC}"
fi

echo -e "${BLUE}=== 启动 Geth 私有链 ===${NC}"
echo -e "${YELLOW}Chain ID: $CHAIN_ID${NC}"
echo -e "${YELLOW}Network ID: $NETWORK_ID${NC}"
echo -e "${YELLOW}Data Directory: $DATADIR${NC}"
echo -e "${YELLOW}HTTP RPC: http://0.0.0.0:8545${NC}"
echo -e "${YELLOW}WebSocket RPC: ws://0.0.0.0:8546${NC}"
echo ""
echo -e "${GREEN}Blockscout 可通过以下端点连接:${NC}"
echo -e "  HTTP: http://localhost:8545"
echo -e "  WebSocket: ws://localhost:8546"
echo ""
echo -e "${BLUE}启动中... (按 Ctrl+C 停止)${NC}"
echo ""

# 启动 Geth 私有链
$GETH_CMD \
    --datadir $DATADIR \
    --networkid $NETWORK_ID \
    --http \
    --http.addr "0.0.0.0" \
    --http.port 8545 \
    --http.api "eth,net,web3,personal,miner,admin,debug,txpool,trace" \
    --http.corsdomain "*" \
    --http.vhosts "*" \
    --ws \
    --ws.addr "0.0.0.0" \
    --ws.port 8546 \
    --ws.api "eth,net,web3,personal,miner,admin,debug,txpool,trace" \
    --ws.origins "*" \
    --graphql \
    --graphql.corsdomain "*" \
    --graphql.vhosts "*" \
    --syncmode full \
    --gcmode archive \
    --txpool.pricelimit 0 \
    --txpool.pricebump 0 \
    --gpo.blocks 1 \
    --gpo.percentile 50 \
    --gpo.maxprice 500000000000 \
    --allow-insecure-unlock \
    --nodiscover \
    --maxpeers 0 \
    --mine \
    --miner.threads 1 \
    --miner.etherbase "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" \
    --unlock "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" \
    --password <(echo "") \
    --verbosity 3 \
    --log.file "./geth.log" \
    --authrpc.port 8551 \
    --authrpc.addr "0.0.0.0" \
    --authrpc.vhosts "*" \
    --authrpc.jwtsecret "./jwt.hex"
