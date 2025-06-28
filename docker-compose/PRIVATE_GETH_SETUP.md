# 私有 Geth 链 Blockscout 部署指南

## 前提条件

1. **确保您的 Geth 私有链正在运行**，并且：
   - HTTP RPC 服务在 `0.0.0.0:8545` 上监听
   - WebSocket RPC 服务在 `0.0.0.0:8546` 上监听  
   - 启用了必要的 API：`eth,net,web3,personal,miner,admin,debug,txpool,trace`
   - 使用 `--gcmode archive` 模式（保留完整历史状态）
   - 启用 CORS 和适当的域名配置

   **重要**: 我们在 `geth-config/` 目录中提供了完整的 Geth 私有链配置文件和启动脚本。
   
   **快速启动您的 Geth 私有链**：
   ```bash
   # 进入 Geth 配置目录
   cd geth-config/
   
   # 启动私有链（使用我们提供的配置）
   ./geth-manager.sh start
   
   # 验证连接
   ./geth-manager.sh test
   ```

2. **安装 Docker 和 Docker Compose**：
   ```bash
   # 检查版本
   docker --version
   docker-compose --version
   ```

## 部署步骤

### 0. 启动 Geth 私有链（必须先执行）
```bash
# 进入 Geth 配置目录
cd geth-config/

# 启动私有链
./geth-manager.sh start

# 验证 Geth 正常运行
./geth-manager.sh status
./geth-manager.sh test
```

### 1. 进入配置目录
```bash
cd /home/monero/blockscout/docker-compose
```

### 2. 启动 Blockscout
使用为您的私有链定制的配置：
```bash
docker-compose -f my-private-geth.yml up -d
```

### 3. 检查服务状态
```bash
# 查看所有服务状态
docker-compose -f my-private-geth.yml ps

# 查看后端日志
docker-compose -f my-private-geth.yml logs backend

# 查看所有日志
docker-compose -f my-private-geth.yml logs
```

### 4. 访问 Blockscout
- **Web 界面**: http://localhost
- **API 端点**: http://localhost/api

## 配置详解

### 网络连接配置
- `ETHEREUM_JSONRPC_HTTP_URL`: 连接到您的 Geth HTTP RPC (8545)
- `ETHEREUM_JSONRPC_WS_URL`: 连接到您的 Geth WebSocket RPC (8546)
- `ETHEREUM_JSONRPC_TRACE_URL`: 用于获取交易追踪信息

### 链信息配置
- `NETWORK`: 显示名称 "Private Geth Chain"
- `SUBNETWORK`: 子网络信息，包含您的 Chain ID (12345)
- `COIN_NAME` 和 `COIN`: 代币显示名称

### 重要的环境变量
在 `envs/my-private-chain.env` 文件中的关键配置：

```bash
# 如果您的 Geth 节点运行在不同的主机上，请修改这些 URL
ETHEREUM_JSONRPC_HTTP_URL=http://your-geth-host:8545/
ETHEREUM_JSONRPC_TRACE_URL=http://your-geth-host:8545/
ETHEREUM_JSONRPC_WS_URL=ws://your-geth-host:8546/
```

## 故障排除

### 1. 连接问题
如果 Blockscout 无法连接到您的 Geth 节点：

```bash
# 检查 Geth 是否可访问
curl http://localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# 从 Docker 容器内测试连接
docker exec backend curl http://host.docker.internal:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### 2. 查看详细日志
```bash
# 后端服务日志
docker-compose -f my-private-geth.yml logs -f backend

# 数据库日志
docker-compose -f my-private-geth.yml logs -f db

# 前端日志
docker-compose -f my-private-geth.yml logs -f frontend
```

### 3. 重启服务
```bash
# 重启所有服务
docker-compose -f my-private-geth.yml restart

# 重启特定服务
docker-compose -f my-private-geth.yml restart backend
```

### 4. 完全重新部署
```bash
# 停止并删除所有容器
docker-compose -f my-private-geth.yml down

# 删除数据库数据（谨慎操作！）
sudo rm -rf ./services/blockscout-db-data/

# 重新启动
docker-compose -f my-private-geth.yml up -d
```

## 自定义配置

### 修改链信息显示
编辑 `envs/my-private-chain.env` 文件：
```bash
COIN_NAME=MyToken
COIN=MTK
NETWORK=My Private Network
SUBNETWORK=Development Chain
```

### 添加自定义 Logo
1. 将 logo 文件放到适当位置
2. 在环境文件中设置：
```bash
LOGO=/images/my-logo.svg
LOGO_FOOTER=/images/my-logo.svg
```

### 启用/禁用功能
```bash
# 禁用待处理交易获取器
INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER=true

# 禁用内部交易获取器
INDEXER_DISABLE_INTERNAL_TRANSACTIONS_FETCHER=true

# 禁用市场数据
DISABLE_MARKET=true
```

## 生产环境注意事项

1. **安全性**: 确保 Geth 节点的 RPC 接口不对外开放
2. **性能**: 根据需要调整数据库连接池大小 (`POOL_SIZE`)
3. **监控**: 设置适当的日志记录和监控
4. **备份**: 定期备份数据库数据

## 常用命令

```bash
# 启动
docker-compose -f my-private-geth.yml up -d

# 停止
docker-compose -f my-private-geth.yml down

# 查看状态
docker-compose -f my-private-geth.yml ps

# 查看日志
docker-compose -f my-private-geth.yml logs -f

# 进入后端容器
docker-compose -f my-private-geth.yml exec backend bash

# 数据库迁移（如果需要）
docker-compose -f my-private-geth.yml exec backend bin/blockscout eval "Elixir.Explorer.ReleaseTasks.create_and_migrate()"
```
