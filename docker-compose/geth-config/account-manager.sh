#!/bin/bash

# 账户生成和管理脚本
# 帮助您创建和管理 Geth 私有链的账户

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DATADIR="./my-private-chain"

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

echo -e "${BLUE}=== Geth 账户管理工具 ===${NC}"
echo ""

# 函数：创建新账户
create_account() {
    echo -e "${YELLOW}创建新账户...${NC}"
    echo -e "${YELLOW}请输入密码（用于保护私钥）:${NC}"
    read -s password
    echo ""
    
    if [ ! -d "$DATADIR" ]; then
        echo -e "${YELLOW}数据目录不存在，创建中...${NC}"
        mkdir -p "$DATADIR"
    fi
    
    echo "$password" | $GETH_CMD --datadir "$DATADIR" account new --password /dev/stdin
    echo ""
    echo -e "${GREEN}账户创建成功！${NC}"
    echo -e "${YELLOW}请记住您的密码，并备份 keystore 文件${NC}"
    echo -e "${YELLOW}Keystore 位置: $DATADIR/keystore/${NC}"
}

# 函数：列出所有账户
list_accounts() {
    echo -e "${YELLOW}当前账户列表:${NC}"
    if [ -d "$DATADIR" ]; then
        $GETH_CMD --datadir "$DATADIR" account list
    else
        echo -e "${RED}数据目录不存在，请先创建账户${NC}"
    fi
}

# 函数：导入私钥
import_privatekey() {
    echo -e "${YELLOW}从私钥导入账户...${NC}"
    echo -e "${YELLOW}请输入私钥（不含 0x 前缀）:${NC}"
    read -s privatekey
    echo ""
    echo -e "${YELLOW}请输入密码保护这个账户:${NC}"
    read -s password
    echo ""
    
    if [ ! -d "$DATADIR" ]; then
        mkdir -p "$DATADIR"
    fi
    
    # 创建临时文件
    temp_key=$(mktemp)
    echo "$privatekey" > "$temp_key"
    
    echo "$password" | $GETH_CMD --datadir "$DATADIR" account import "$temp_key" --password /dev/stdin
    
    rm "$temp_key"
    echo -e "${GREEN}私钥导入成功！${NC}"
}

# 函数：生成预分配配置
generate_prealloc() {
    echo -e "${YELLOW}生成 genesis.json 的预分配配置...${NC}"
    echo ""
    
    if [ ! -d "$DATADIR/keystore" ]; then
        echo -e "${RED}没有找到账户，请先创建账户${NC}"
        return 1
    fi
    
    echo -e "${BLUE}当前账户:${NC}"
    $GETH_CMD --datadir "$DATADIR" account list
    echo ""
    
    echo -e "${YELLOW}以下是可以添加到 genesis.json 的预分配配置:${NC}"
    echo "\"alloc\": {"
    
    # 获取所有账户地址
    addresses=$($GETH_CMD --datadir "$DATADIR" account list | grep -oP '(?<=\{)[^}]+')
    
    for addr in $addresses; do
        echo "  \"$addr\": {"
        echo "    \"balance\": \"1000000000000000000000000\""
        echo "  },"
    done
    
    echo "  \"0x0000000000000000000000000000000000000001\": {"
    echo "    \"balance\": \"1000000000000000000000000\""
    echo "  }"
    echo "}"
}

# 函数：显示账户详情
show_account_details() {
    echo -e "${YELLOW}显示推荐的挖矿账户配置:${NC}"
    echo ""
    
    if [ ! -d "$DATADIR/keystore" ]; then
        echo -e "${RED}没有找到账户，请先创建账户${NC}"
        return 1
    fi
    
    # 获取第一个账户作为推荐的挖矿账户
    first_account=$($GETH_CMD --datadir "$DATADIR" account list | head -1 | grep -oP '(?<=\{)[^}]+')
    
    if [ -n "$first_account" ]; then
        echo -e "${GREEN}推荐的挖矿账户: $first_account${NC}"
        echo ""
        echo -e "${YELLOW}在启动脚本中使用以下配置:${NC}"
        echo "--miner.etherbase \"$first_account\""
        echo "--unlock \"$first_account\""
        echo ""
        echo -e "${YELLOW}在 genesis.json 中添加预分配:${NC}"
        echo "\"$first_account\": {"
        echo "  \"balance\": \"10000000000000000000000000\""
        echo "},"
    fi
}

# 显示菜单
show_menu() {
    echo "请选择操作:"
    echo "1) 创建新账户"
    echo "2) 列出所有账户"
    echo "3) 从私钥导入账户"
    echo "4) 生成预分配配置"
    echo "5) 显示推荐挖矿账户配置"
    echo "6) 退出"
    echo ""
}

# 主循环
while true; do
    show_menu
    read -p "请输入选择 (1-6): " choice
    echo ""
    
    case $choice in
        1)
            create_account
            ;;
        2)
            list_accounts
            ;;
        3)
            import_privatekey
            ;;
        4)
            generate_prealloc
            ;;
        5)
            show_account_details
            ;;
        6)
            echo -e "${GREEN}再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择，请重试${NC}"
            ;;
    esac
    echo ""
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
    clear
done
