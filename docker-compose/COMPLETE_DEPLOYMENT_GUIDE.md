# 🚀 Geth 私有链 + Blockscout 完整部署指南

## 📋 概述
本指南将帮助您从零开始设置一个完整的 Geth 私有链环境，并配合 Blockscout 区块浏览器。

## 📁 项目结构
```
/home/monero/blockscout/docker-compose/
├── geth-config/                    # Geth 私有链配置
│   ├── genesis.json               # 创世块配置
│   ├── start-geth.sh             # 简单启动脚本
│   ├── geth-manager.sh           # 完整管理脚本
│   └── README.md                 # Geth 详细文档
├── envs/
│   └── my-private-chain.env      # 私有链环境配置
├── my-private-geth.yml           # Docker Compose 配置
└── COMPLETE_DEPLOYMENT_GUIDE.md  # 本文档
```

## 🔧 您的启动配置需要的修改

基于您提供的 Geth 启动命令，以下是必要的修改以确保与 Blockscout 兼容：

### ❌ 原始配置问题：
```bash
--http.api "eth,net,web3,personal,miner,admin"  # API 不完整
# 缺少 --gcmode archive                         # 需要归档模式
# 缺少 debug, txpool, trace API                # Blockscout 必需
```

### ✅ Blockscout 兼容配置：
```bash
# 完整的 API 列表
--http.api "eth,net,web3,personal,miner,admin,debug,txpool,trace"
--ws.api "eth,net,web3,personal,miner,admin,debug,txpool,trace"

# 归档模式（保留所有历史状态）
--gcmode archive

# CORS 配置
--http.corsdomain "*"
--http.vhosts "*"
--ws.origins "*"
```

## 🚀 完整部署流程

### 步骤 1: 准备 Geth 私有链

#### 1.1 复制配置文件到您的 Geth 目录
```bash
# 如果您的 geth 在自定义位置
cp /home/monero/blockscout/docker-compose/geth-config/* /home/monero/go-ethereum/build/bin/

# 或者直接在我们的配置目录中工作
cd /home/monero/blockscout/docker-compose/geth-config/
```

#### 1.2 启动 Geth 私有链
```bash
# 方法一：使用我们的管理脚本（强烈推荐）
./geth-manager.sh start

# 方法二：使用简单启动脚本
./start-geth.sh

# 方法三：修改您的原始启动命令
/path/to/your/compiled/geth \
  --datadir ./my-private-chain \
  --networkid 12345 \
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
  --miner.etherbase "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" \
  --mine \
  --allow-insecure-unlock \
  --nodiscover \
  --maxpeers 0
```

#### 1.3 验证 Geth 运行状态
```bash
# 使用管理脚本验证
./geth-manager.sh test

# 或手动测试
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545
```

### 步骤 2: 启动 Blockscout

#### 2.1 进入 Docker Compose 目录
```bash
cd /home/monero/blockscout/docker-compose/
```

#### 2.2 启动 Blockscout 服务
```bash
# 后台启动
docker-compose -f my-private-geth.yml up -d

# 或前台启动（查看日志）
docker-compose -f my-private-geth.yml up
```

#### 2.3 检查服务状态
```bash
# 查看所有服务状态
docker-compose -f my-private-geth.yml ps

# 查看后端日志
docker-compose -f my-private-geth.yml logs -f backend

# 查看前端日志
docker-compose -f my-private-geth.yml logs -f frontend
```

### 步骤 3: 验证部署

#### 3.1 访问 Blockscout
- **Web 界面**: http://localhost
- **API 端点**: http://localhost/api
- **API 文档**: http://localhost/api-docs

#### 3.2 验证区块同步
```bash
# 检查 Blockscout 是否正在同步区块
docker-compose -f my-private-geth.yml logs backend | grep -i "block"

# 在 Geth 中创建一些交易来测试
./geth-manager.sh attach
```

## 🛠️ 配置文件详解

### Genesis.json 关键配置
```json
{
  "config": {
    "chainId": 12345,              // 与 Blockscout 配置匹配
    "clique": {                    // Clique PoA 共识
      "period": 3,                 // 3秒出块
      "epoch": 30000
    }
  },
  "difficulty": "0x1",             // 低难度，快速出块
  "gasLimit": "0x47b760",          // 合适的 Gas 限制
  "alloc": {                       // 预分配账户
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266": {
      "balance": "10000000000000000000000000"
    }
  }
}
```

### Blockscout 环境配置
```bash
# 关键配置项
ETHEREUM_JSONRPC_HTTP_URL=http://host.docker.internal:8545/
ETHEREUM_JSONRPC_WS_URL=ws://host.docker.internal:8546/
COIN_NAME=ETH
NETWORK=Private Geth Chain
SUBNETWORK=Private Chain (Chain ID: 12345)
DISABLE_MARKET=true
```

## 🔍 故障排除

### 常见问题及解决方案

#### 问题 1: Blockscout 无法连接到 Geth
```bash
# 检查 Geth 是否正确监听
netstat -tulpn | grep :8545
netstat -tulpn | grep :8546

# 测试从 Docker 容器内的连接
docker exec backend curl http://host.docker.internal:8545 \
  -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

#### 问题 2: Blockscout 显示 "No blocks" 或同步缓慢
```bash
# 检查 Geth 是否在挖矿
./geth-manager.sh attach
> miner.start(1)

# 检查 Blockscout 索引器日志
docker-compose -f my-private-geth.yml logs backend | grep -i "indexer"
```

#### 问题 3: API 调用失败
```bash
# 确保 Geth 启用了所有必要的 API
# 检查启动参数中是否包含: debug,txpool,trace
./geth-manager.sh logs | grep -i "api"
```

### 调试命令
```bash
# Geth 相关
./geth-manager.sh status          # 查看 Geth 状态
./geth-manager.sh logs           # 查看 Geth 日志
./geth-manager.sh test           # 测试连接

# Blockscout 相关
docker-compose -f my-private-geth.yml ps              # 服务状态
docker-compose -f my-private-geth.yml logs backend    # 后端日志
docker-compose -f my-private-geth.yml logs frontend   # 前端日志
docker-compose -f my-private-geth.yml logs db         # 数据库日志
```

## 🔄 完整的启动/停止流程

### 启动流程
```bash
# 1. 启动 Geth 私有链
cd /home/monero/blockscout/docker-compose/geth-config/
./geth-manager.sh start

# 2. 验证 Geth 状态
./geth-manager.sh test

# 3. 启动 Blockscout
cd /home/monero/blockscout/docker-compose/
docker-compose -f my-private-geth.yml up -d

# 4. 检查服务状态
docker-compose -f my-private-geth.yml ps

# 5. 访问 Blockscout
echo "Blockscout 已启动: http://localhost"
```

### 停止流程
```bash
# 1. 停止 Blockscout
cd /home/monero/blockscout/docker-compose/
docker-compose -f my-private-geth.yml down

# 2. 停止 Geth
cd geth-config/
./geth-manager.sh stop
```

## 📊 生产环境建议

### 性能优化
```bash
# Geth 优化
--cache 2048                    # 增加缓存
--miner.threads 2              # 增加挖矿线程（如果需要）

# Blockscout 优化
POOL_SIZE=100                  # 增加数据库连接池
INDEXER_CATCHUP_BLOCKS_BATCH_SIZE=50
```

### 安全配置
```bash
# 生产环境不要使用
--allow-insecure-unlock        # 仅开发环境

# 限制 RPC 访问
--http.addr "127.0.0.1"       # 仅本地访问
--http.corsdomain "localhost"  # 限制 CORS
```

### 监控和日志
```bash
# 设置日志轮转
--log.file "./logs/geth.log"
--log.rotate

# 定期备份数据
rsync -av ./my-private-chain/ ./backup/
```

## 🎯 下一步

1. **测试交易**: 在 Geth 控制台中发送一些测试交易
2. **部署合约**: 部署智能合约并在 Blockscout 中查看
3. **自定义配置**: 根据需要修改网络名称、Logo 等
4. **监控设置**: 配置日志和监控系统

## 📞 支持

如果遇到问题：
1. 查看 `geth-config/README.md` 了解 Geth 详细配置
2. 查看 `PRIVATE_GETH_SETUP.md` 了解 Blockscout 配置
3. 检查相关日志文件
4. 使用提供的调试命令

---

**恭喜！** 您现在拥有一个完整的私有区块链环境，包括 Geth 节点和 Blockscout 区块浏览器。
