#!/bin/bash

# Geth 私有链启动脚本 - 兼容 geth 1.10.1
# 专门配合 Blockscout 使用

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
NC='\033[0m'

echo -e "${BLUE}=== Geth 私有链启动脚本 (兼容版本) ===${NC}"

# 检查 geth 是否存在
if ! command -v geth &> /dev/null; then
    if [ -f "/home/monero/go-ethereum/build/bin/geth" ]; then
        echo -e "${YELLOW}使用本地编译的 geth: /home/monero/go-ethereum/build/bin/geth${NC}"
        GETH_CMD="/home/monero/go-ethereum/build/bin/geth"
    else
        echo -e "${RED}错误: 找不到 geth 可执行文件${NC}"
        exit 1
    fi
else
    GETH_CMD="geth"
fi

echo -e "${GREEN}使用 Geth: $GETH_CMD${NC}"

# 检查 geth 版本
$GETH_CMD version

# 检查 genesis.json 文件
if [ ! -f "$GENESIS_FILE" ]; then
    echo -e "${RED}错误: genesis.json 文件不存在${NC}"
    exit 1
fi

# 初始化创世块（仅在数据目录不存在时）
if [ ! -d "$DATADIR" ]; then
    echo -e "${YELLOW}初始化创世块...${NC}"
    $GETH_CMD --datadir $DATADIR init $GENESIS_FILE
    echo -e "${GREEN}创世块初始化完成${NC}"
fi

# 生成 JWT secret（如果不存在）
if [ ! -f "./jwt.hex" ]; then
    openssl rand -hex 32 > ./jwt.hex 2>/dev/null || echo "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef" > ./jwt.hex
fi

echo -e "${BLUE}=== 启动 Geth 私有链 ===${NC}"
echo -e "${YELLOW}Chain ID: $CHAIN_ID${NC}"
echo -e "${YELLOW}Network ID: $NETWORK_ID${NC}"
echo -e "${YELLOW}HTTP RPC: http://0.0.0.0:8545${NC}"
echo -e "${YELLOW}WebSocket: ws://0.0.0.0:8546${NC}"
echo ""

# 启动 Geth - 去除不兼容的参数
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
    --txpool.pricelimit 0 \
    --txpool.pricebump 0 \
    --allow-insecure-unlock \
    --nodiscover \
    --maxpeers 0 \
    --mine \
    --miner.threads 1 \
    --miner.etherbase "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" \
    --unlock "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" \
    --password <(echo "") \
    --verbosity 3
