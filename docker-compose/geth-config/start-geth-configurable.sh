#!/bin/bash

# Geth 私有链启动脚本 - 可配置版本
# 支持自定义挖矿账户和更安全的配置

set -e

# 配置变量
CHAIN_ID=12345
DATADIR="./my-private-chain"
GENESIS_FILE="./genesis.json"
NETWORK_ID=12345

# 默认挖矿账户（Hardhat 测试账户）
DEFAULT_MINER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Geth 私有链启动脚本 (可配置版本) ===${NC}"

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

# 检查 genesis.json 文件
if [ ! -f "$GENESIS_FILE" ]; then
    echo -e "${RED}错误: genesis.json 文件不存在${NC}"
    exit 1
fi

# 选择挖矿账户
echo -e "${YELLOW}=== 挖矿账户配置 ===${NC}"
echo -e "${YELLOW}选择挖矿账户:${NC}"
echo "1) 使用默认测试账户 (Hardhat): $DEFAULT_MINER"
echo "2) 使用您自己的账户"
echo "3) 创建新账户"
echo ""

read -p "请选择 (1-3): " account_choice

case $account_choice in
    1)
        MINER_ACCOUNT="$DEFAULT_MINER"
        UNLOCK_ACCOUNT="$DEFAULT_MINER"
        USE_PASSWORD=false
        echo -e "${GREEN}使用默认测试账户: $MINER_ACCOUNT${NC}"
        ;;
    2)
        echo -e "${YELLOW}请输入您的账户地址:${NC}"
        read MINER_ACCOUNT
        UNLOCK_ACCOUNT="$MINER_ACCOUNT"
        USE_PASSWORD=true
        echo -e "${GREEN}使用自定义账户: $MINER_ACCOUNT${NC}"
        ;;
    3)
        echo -e "${YELLOW}创建新账户...${NC}"
        ./account-manager.sh
        exit 0
        ;;
    *)
        echo -e "${YELLOW}使用默认账户${NC}"
        MINER_ACCOUNT="$DEFAULT_MINER"
        UNLOCK_ACCOUNT="$DEFAULT_MINER"
        USE_PASSWORD=false
        ;;
esac

# 初始化创世块
if [ ! -d "$DATADIR" ]; then
    echo -e "${YELLOW}初始化创世块...${NC}"
    $GETH_CMD --datadir $DATADIR init $GENESIS_FILE
    echo -e "${GREEN}创世块初始化完成${NC}"
fi

echo -e "${BLUE}=== 启动 Geth 私有链 ===${NC}"
echo -e "${YELLOW}Chain ID: $CHAIN_ID${NC}"
echo -e "${YELLOW}Network ID: $NETWORK_ID${NC}"
echo -e "${YELLOW}挖矿账户: $MINER_ACCOUNT${NC}"
echo -e "${YELLOW}HTTP RPC: http://0.0.0.0:8545${NC}"
echo -e "${YELLOW}WebSocket RPC: ws://0.0.0.0:8546${NC}"
echo ""

# 构建启动命令
GETH_ARGS=(
    --datadir "$DATADIR"
    --networkid $NETWORK_ID
    --http
    --http.addr "0.0.0.0"
    --http.port 8545
    --http.api "eth,net,web3,personal,miner,admin,debug,txpool,trace"
    --http.corsdomain "*"
    --http.vhosts "*"
    --ws
    --ws.addr "0.0.0.0"
    --ws.port 8546
    --ws.api "eth,net,web3,personal,miner,admin,debug,txpool,trace"
    --ws.origins "*"
    --graphql
    --graphql.corsdomain "*"
    --graphql.vhosts "*"
    --syncmode full
    --gcmode archive
    --txpool.pricelimit 0
    --txpool.pricebump 0
    --nodiscover
    --maxpeers 0
    --mine
    --miner.threads 1
    --miner.etherbase "$MINER_ACCOUNT"
    --verbosity 3
    --log.file "./geth.log"
)

# 添加认证 RPC 配置
if [ ! -f "./jwt.hex" ]; then
    openssl rand -hex 32 > ./jwt.hex || echo "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef" > ./jwt.hex
fi

GETH_ARGS+=(
    --authrpc.port 8551
    --authrpc.addr "0.0.0.0"
    --authrpc.vhosts "*"
    --authrpc.jwtsecret "./jwt.hex"
)

# 根据是否使用自定义账户决定是否需要解锁
if [ "$USE_PASSWORD" = true ]; then
    echo -e "${YELLOW}注意: 使用自定义账户需要解锁${NC}"
    echo -e "${YELLOW}您需要在 Geth 控制台中手动解锁账户:${NC}"
    echo -e "${BLUE}personal.unlockAccount(\"$MINER_ACCOUNT\", \"your_password\", 0)${NC}"
    GETH_ARGS+=(--allow-insecure-unlock)
else
    # 对于默认测试账户，自动解锁
    GETH_ARGS+=(
        --unlock "$UNLOCK_ACCOUNT"
        --password <(echo "")
        --allow-insecure-unlock
    )
fi

echo -e "${BLUE}启动中... (按 Ctrl+C 停止)${NC}"
echo ""

# 启动 Geth
exec "$GETH_CMD" "${GETH_ARGS[@]}"
