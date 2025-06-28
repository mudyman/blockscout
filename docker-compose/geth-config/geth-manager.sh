#!/bin/bash

# Geth 私有链管理脚本 - 生产环境版本
# 提供更稳定的启动、停止和管理功能

set -e

# 配置变量
CHAIN_ID=12345
DATADIR="./my-private-chain"
GENESIS_FILE="./genesis.json"
NETWORK_ID=12345
PID_FILE="./geth.pid"
LOG_FILE="./geth.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查 geth 路径
if ! command -v geth &> /dev/null; then
    if [ -f "/home/monero/go-ethereum/build/bin/geth" ]; then
        GETH_CMD="/home/monero/go-ethereum/build/bin/geth"
    else
        echo -e "${RED}错误: 找不到 geth 可执行文件${NC}"
        exit 1
    fi
else
    GETH_CMD="geth"
fi

# 函数：显示帮助信息
show_help() {
    echo -e "${BLUE}Geth 私有链管理脚本${NC}"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  start     - 启动 Geth 私有链"
    echo "  stop      - 停止 Geth 私有链"
    echo "  restart   - 重启 Geth 私有链"
    echo "  status    - 查看运行状态"
    echo "  logs      - 查看日志"
    echo "  init      - 初始化创世块"
    echo "  clean     - 清除所有数据（危险操作）"
    echo "  attach    - 连接到 Geth 控制台"
    echo "  test      - 测试 RPC 连接"
    echo ""
}

# 函数：检查进程是否运行
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# 函数：初始化创世块
init_genesis() {
    echo -e "${YELLOW}初始化创世块...${NC}"
    if [ ! -f "$GENESIS_FILE" ]; then
        echo -e "${RED}错误: genesis.json 文件不存在${NC}"
        exit 1
    fi
    
    if [ -d "$DATADIR" ]; then
        echo -e "${YELLOW}警告: 数据目录已存在，将被清除${NC}"
        read -p "确认继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "操作已取消"
            exit 1
        fi
        rm -rf "$DATADIR"
    fi
    
    $GETH_CMD --datadir "$DATADIR" init "$GENESIS_FILE"
    echo -e "${GREEN}创世块初始化完成${NC}"
}

# 函数：启动 Geth
start_geth() {
    if is_running; then
        echo -e "${YELLOW}Geth 已在运行中 (PID: $(cat $PID_FILE))${NC}"
        return 0
    fi
    
    if [ ! -d "$DATADIR" ]; then
        echo -e "${YELLOW}数据目录不存在，自动初始化创世块...${NC}"
        init_genesis
    fi
    
    echo -e "${BLUE}启动 Geth 私有链...${NC}"
    echo -e "${YELLOW}Chain ID: $CHAIN_ID${NC}"
    echo -e "${YELLOW}HTTP RPC: http://0.0.0.0:8545${NC}"
    echo -e "${YELLOW}WebSocket: ws://0.0.0.0:8546${NC}"
    
    # 生成 JWT secret
    if [ ! -f "./jwt.hex" ]; then
        openssl rand -hex 32 > ./jwt.hex
    fi
    
    nohup $GETH_CMD \
        --datadir "$DATADIR" \
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
        --authrpc.port 8551 \
        --authrpc.addr "0.0.0.0" \
        --authrpc.vhosts "*" \
        --authrpc.jwtsecret "./jwt.hex" \
        > "$LOG_FILE" 2>&1 &
    
    echo $! > "$PID_FILE"
    
    # 等待启动
    sleep 3
    if is_running; then
        echo -e "${GREEN}Geth 启动成功 (PID: $(cat $PID_FILE))${NC}"
        echo -e "${GREEN}日志文件: $LOG_FILE${NC}"
    else
        echo -e "${RED}Geth 启动失败${NC}"
        tail -n 20 "$LOG_FILE"
        exit 1
    fi
}

# 函数：停止 Geth
stop_geth() {
    if ! is_running; then
        echo -e "${YELLOW}Geth 未运行${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}停止 Geth...${NC}"
    PID=$(cat "$PID_FILE")
    kill $PID
    
    # 等待进程结束
    for i in {1..10}; do
        if ! ps -p $PID > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    if ps -p $PID > /dev/null 2>&1; then
        echo -e "${YELLOW}强制停止 Geth...${NC}"
        kill -9 $PID
    fi
    
    rm -f "$PID_FILE"
    echo -e "${GREEN}Geth 已停止${NC}"
}

# 函数：查看状态
show_status() {
    if is_running; then
        PID=$(cat "$PID_FILE")
        echo -e "${GREEN}Geth 正在运行${NC}"
        echo -e "PID: $PID"
        echo -e "端口: 8545 (HTTP), 8546 (WebSocket)"
        echo -e "数据目录: $DATADIR"
        echo -e "日志文件: $LOG_FILE"
        
        # 显示 CPU 和内存使用
        ps -p $PID -o pid,ppid,pcpu,pmem,etime,comm
    else
        echo -e "${RED}Geth 未运行${NC}"
    fi
}

# 函数：查看日志
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        echo -e "${RED}日志文件不存在${NC}"
    fi
}

# 函数：连接控制台
attach_console() {
    if ! is_running; then
        echo -e "${RED}Geth 未运行${NC}"
        exit 1
    fi
    
    $GETH_CMD attach "$DATADIR/geth.ipc"
}

# 函数：测试 RPC 连接
test_rpc() {
    echo -e "${BLUE}测试 RPC 连接...${NC}"
    
    # 测试 HTTP RPC
    echo -e "${YELLOW}测试 HTTP RPC (8545)...${NC}"
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8545 > /dev/null; then
        echo -e "${GREEN}✓ HTTP RPC 连接成功${NC}"
        
        # 获取当前区块号
        BLOCK_NUM=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            http://localhost:8545 | jq -r '.result')
        echo -e "当前区块号: $BLOCK_NUM"
    else
        echo -e "${RED}✗ HTTP RPC 连接失败${NC}"
    fi
    
    # 测试 WebSocket（简单检查端口）
    echo -e "${YELLOW}测试 WebSocket (8546)...${NC}"
    if nc -z localhost 8546; then
        echo -e "${GREEN}✓ WebSocket 端口开放${NC}"
    else
        echo -e "${RED}✗ WebSocket 端口不可访问${NC}"
    fi
}

# 函数：清除数据
clean_data() {
    if is_running; then
        echo -e "${RED}请先停止 Geth${NC}"
        exit 1
    fi
    
    echo -e "${RED}警告: 这将删除所有区块链数据！${NC}"
    read -p "确认删除所有数据? (yes/NO): " -r
    if [[ $REPLY == "yes" ]]; then
        rm -rf "$DATADIR"
        rm -f "$LOG_FILE" "$PID_FILE" "./jwt.hex"
        echo -e "${GREEN}数据已清除${NC}"
    else
        echo "操作已取消"
    fi
}

# 主程序
case "${1:-help}" in
    start)
        start_geth
        ;;
    stop)
        stop_geth
        ;;
    restart)
        stop_geth
        sleep 2
        start_geth
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    init)
        init_genesis
        ;;
    clean)
        clean_data
        ;;
    attach)
        attach_console
        ;;
    test)
        test_rpc
        ;;
    help|*)
        show_help
        ;;
esac
