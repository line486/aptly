# Aptly Docker Image

## 快速开始

```bash
docker run -d \
  --name aptly \
  --restart unless-stopped \
  -p 80:80 \
  -v .aptly:/root/.aptly \
  -v .gnupg:/root/.gnupg \
  lineio/aptly:latest
```

### Docker Compose

```yaml
services:
  aptly:
    image: lineio/aptly:latest
    container_name: aptly
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - .aptly:/root/.aptly
      - .gnupg:/root/.gnupg

volumes:
  .aptly:
  .gnupg:
```

```bash
docker compose up -d
```

## 架构

```text
:80 (nginx)
  ├── /          → 静态仓库文件
  └── /api       → 反向代理到 :8080 (aptly api serve)
```

| 端口 | 用途       |
| ---- | ---------- |
| 80   | 仓库 + API |

| 数据卷         | 说明               |
| -------------- | ------------------ |
| `/root/.aptly` | 数据库、仓库元数据 |
| `/root/.gnupg` | GPG 密钥           |

## GPG 密钥

发布仓库前需先生成 GPG 密钥：

```bash
docker exec -it aptly bash
gpg --batch --pinentry-mode loopback --passphrase '' --quick-gen-key "Aptly Repository <aptly@localhost>" default default never
```

密钥保存在数据卷中，重启不丢失。导出公钥供客户端使用：

```bash
docker exec -it aptly gpg --armor --export "aptly@localhost" > aptly-public.key
```

或

```bash
cd /root/.aptly/public
gpg --export --armor > repo-key.asc
wget -qO- https://localhost:80/repo-key.asc | sudo gpg --dearmor -o /usr/share/keyrings/aptly.gpg
```

## 环境变量

使用 `APTLY_` 前缀，如 `APTLY_ARCHITECTURES`。完整配置参考 [aptly 官方文档](https://www.aptly.info/doc/feature/configuration/)。

## 常用操作

```bash
# 创建仓库
curl -X POST http://localhost:80/api/repos \
  -H "Content-Type: application/json" \
  -d '{"Name": "my-repo", "DefaultDistribution": "bookworm", "DefaultComponent": "main"}'

# 上传包
curl -X POST http://localhost:80/api/files/my-pkg \
  -F "file=@/path/to/package.deb"

# 添加包到仓库
curl -X POST http://localhost:80/api/repos/my-repo/file/my-pkg

# 发布仓库
curl -X PUT http://localhost:80/api/publish/:./bookworm \
  -H "Content-Type: application/json" \
  -d '{"Storage": "", "SourceKind": "local", "Sources": [{"Name": "my-repo"}]}'
```

## 客户端使用

```bash
echo "deb http://your-server:80/ bookworm main" | sudo tee /etc/apt/sources.list.d/aptly.list
sudo apt update
```

## CI/CD

GitHub Actions 每日 UTC 06:00 检查上游新版本，自动构建并推送 `linux/amd64`、`linux/arm64` 镜像到 Docker Hub。

| Secret               | 说明                    |
| -------------------- | ----------------------- |
| `DOCKERHUB_USERNAME` | Docker Hub 用户名       |
| `DOCKERHUB_TOKEN`    | Docker Hub Access Token |

## 版本选择

```bash
docker pull lineio/aptly:latest   # 最新版
docker pull lineio/aptly:1.5.0    # 指定版本
```

## 参考链接

- [aptly 官方网站](https://www.aptly.info/)
- [aptly GitHub 仓库](https://github.com/aptly-dev/aptly)
- [aptly API 文档](https://www.aptly.info/doc/api/)
