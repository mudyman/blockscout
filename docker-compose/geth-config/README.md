# Geth 私有链完整部署指南

## 概述
本指南将帮助您设置一个与 Blockscout 完全兼容的 Geth 私有链，包括所有必要的配置和启动脚本。

## 文件结构
```
geth-config/
├── genesis.json        # 创世块配置
├── start-geth.sh      # 简单启动脚本
├── geth-manager.sh    # 完整管理脚本
└── README.md          # 本文档
```

## 快速开始

### 1. 复制配置文件到您的 Geth 目录
```bash
# 如果您的 geth 在 /home/monero/go-ethereum/build/bin/
cd /home/monero/go-ethereum/build/bin/
cp /home/monero/blockscout/docker-compose/geth-config/* .

# 或者直接在配置目录中工作
cd /home/monero/blockscout/docker-compose/geth-config/
```

### 2. 启动私有链
```bash
# 方法一：使用管理脚本（推荐）
./geth-manager.sh start

# 方法二：使用简单启动脚本
./start-geth.sh
```

### 3. 启动 Blockscout
```bash
cd /home/monero/blockscout/docker-compose/
docker-compose -f my-private-geth.yml up -d
```

## 详细配置说明

### Genesis.json 配置特点

1. **Chain ID**: 12345（与 Blockscout 配置匹配）
2. **共识机制**: Clique PoA（权威证明）
   - 出块间隔：3秒
   - Epoch：30000块
3. **预分配账户**: 包含测试账户，预分配了大量 ETH
4. **兼容性**: 支持所有以太坊改进提案（EIP）

### Geth 启动参数详解

**关键的 Blockscout 兼容参数：**

```bash
# RPC 配置
--http                                    # 启用 HTTP RPC
--http.addr "0.0.0.0"                   # 监听所有接口
--http.port 8545                         # HTTP RPC 端口
--http.api "eth,net,web3,personal,miner,admin,debug,txpool,trace"  # 完整 API

# WebSocket 配置
--ws                                     # 启用 WebSocket
--ws.addr "0.0.0.0"                    # 监听所有接口
--ws.port 8546                          # WebSocket 端口
--ws.api "eth,net,web3,personal,miner,admin,debug,txpool,trace"   # 完整 API

# 同步和存储模式
--syncmode full                          # 完整同步模式
--gcmode archive                         # 归档模式（保留所有历史状态）

# 挖矿配置
--mine                                   # 启用挖矿
--miner.threads 1                        # 挖矿线程数
--miner.etherbase "ADDRESS"              # 挖矿收益地址
```

## 使用管理脚本

### 基本命令
```bash
# 启动
./geth-manager.sh start

# 停止
./geth-manager.sh stop

# 重启
./geth-manager.sh restart

# 查看状态
./geth-manager.sh status

# 查看日志
./geth-manager.sh logs

# 测试连接
./geth-manager.sh test
```

### 高级功能
```bash
# 初始化创世块
./geth-manager.sh init

# 连接到 Geth 控制台
./geth-manager.sh attach

# 清除所有数据
./geth-manager.sh clean
```

## 验证设置

### 1. 检查 Geth 是否正确运行
```bash
# 检查 HTTP RPC
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545

# 检查 WebSocket 端口
nc -z localhost 8546
```

### 2. 验证与 Blockscout 的连接
```bash
# 从 Blockscout 容器内测试
docker exec backend curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://host.docker.internal:8545
```

## 账户管理

### 预配置的测试账户

1. **主挖矿账户**:
   - 地址: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
   - 余额: 10,000,000 ETH

2. **测试账户**:
   - 地址: `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
   - 余额: 10,000,000 ETH

### 创建新账户
```bash
# 连接到 Geth 控制台
./geth-manager.sh attach

# 在控制台中创建新账户
> personal.newAccount("password")

# 解锁账户
> personal.unlockAccount("0xYourAddress", "password", 0)
```

## 性能优化

### 针对开发环境
```bash
# 快速出块
--miner.recommit 1s

# 降低难度
# 在 genesis.json 中设置 "difficulty": "0x1"

# 预分配 Gas
--txpool.pricelimit 0
--txpool.pricebump 0
```

### 针对测试环境
```bash
# 增加 Gas 限制
--miner.gaslimit 30000000

# 增加挖矿线程
--miner.threads 2
```

## 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 检查端口使用情况
   netstat -tulpn | grep :8545
   netstat -tulpn | grep :8546
   ```

2. **权限问题**
   ```bash
   # 确保脚本有执行权限
   chmod +x *.sh
   ```

3. **防火墙问题**
   ```bash
   # Ubuntu/Debian
   sudo ufw allow 8545
   sudo ufw allow 8546
   
   # CentOS/RHEL
   sudo firewall-cmd --add-port=8545/tcp --permanent
   sudo firewall-cmd --add-port=8546/tcp --permanent
   sudo firewall-cmd --reload
   ```

### 日志分析
```bash
# 查看 Geth 日志
tail -f geth.log

# 查看 Blockscout 后端日志
docker-compose -f my-private-geth.yml logs backend
```

## 生产环境注意事项

1. **安全性**
   - 不要在生产环境中使用 `--allow-insecure-unlock`
   - 设置适当的防火墙规则
   - 使用强密码保护账户

2. **性能**
   - 根据需要调整 `--cache` 参数
   - 监控磁盘空间使用
   - 定期备份数据目录

3. **监控**
   - 设置日志轮转
   - 监控进程状态
   - 设置告警机制

## 完整启动流程

### 启动私有链和 Blockscout
```bash
# 1. 启动 Geth 私有链
cd /home/monero/blockscout/docker-compose/geth-config/
./geth-manager.sh start

# 2. 验证 Geth 运行正常
./geth-manager.sh test

# 3. 启动 Blockscout
cd /home/monero/blockscout/docker-compose/
docker-compose -f my-private-geth.yml up -d

# 4. 检查 Blockscout 状态
docker-compose -f my-private-geth.yml ps
docker-compose -f my-private-geth.yml logs backend

# 5. 访问 Blockscout
# http://localhost
```

### 停止服务
```bash
# 停止 Blockscout
docker-compose -f my-private-geth.yml down

# 停止 Geth
cd geth-config/
./geth-manager.sh stop
```
