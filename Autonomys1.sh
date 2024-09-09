#!/bin/bash

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 启动节点"
        echo "2. 查看日志"
        echo "3. 退出脚本"

        read -p "请输入选项 [1-3]: " option

        case $option in
            1)
                # 检查 Docker Compose 是否安装
                if ! command -v docker-compose &> /dev/null; then
                    echo "Docker Compose 未安装，正在安装 Docker Compose..."
                    # 安装 Docker Compose
                    DOCKER_COMPOSE_VERSION="2.20.2"
                    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                    chmod +x /usr/local/bin/docker-compose
                else
                    echo "Docker Compose 已安装。"
                fi

                # 输出 Docker Compose 版本
                echo "Docker Compose 版本:"
                docker-compose --version

                # 提示用户输入 reward-address 和 name
                read -p "请输入 reward-address: " REWARD_ADDRESS
                read -p "请输入 name: " NAME

                # 创建 docker-compose.yaml 文件
                cat <<EOF > docker-compose.yaml
version: '3'
services:
  node:
    image: ghcr.io/autonomys/node:gemini-3h-2024-sep-03
    volumes:
      - node-data:/var/subspace:rw
    ports:
      - "0.0.0.0:30333:30333/tcp"
      - "0.0.0.0:30433:30433/tcp"
    restart: unless-stopped
    command:
      [
        "run",
        "--chain", "gemini-3h",
        "--base-path", "/var/subspace",
        "--listen-on", "/ip4/0.0.0.0/tcp/30333",
        "--dsn-listen-on", "/ip4/0.0.0.0/tcp/30433",
        "--rpc-cors", "all",
        "--rpc-methods", "unsafe",
        "--rpc-listen-on", "0.0.0.0:9944",
        "--farmer",
        "--name", "$NAME"
      ]
    healthcheck:
      timeout: 5s
      interval: 30s
      retries: 60

  farmer:
    depends_on:
      node:
        condition: service_healthy
    image: ghcr.io/autonomys/farmer:gemini-3h-2024-sep-03
    volumes:
      - farmer-data:/var/subspace:rw
    ports:
      - "0.0.0.0:30533:30533/tcp"
    restart: unless-stopped
    command:
      [
        "farm",
        "--node-rpc-url", "ws://node:9944",
        "--listen-on", "/ip4/0.0.0.0/tcp/30533",
        "--reward-address", "$REWARD_ADDRESS",
        "path=/var/subspace,size=120G"
      ]
volumes:
  node-data:
  farmer-data:
EOF

                # 提示用户按任意键继续
                read -n 1 -s -r -p "docker-compose.yaml 文件已创建。按任意键继续..."

                # 创建 subspace 目录
                mkdir -p subspace

                # 移动 docker-compose.yaml 文件到 subspace 目录
                mv docker-compose.yaml subspace/

                # 进入 subspace 目录并执行 docker compose up -d
                cd subspace
                docker compose up -d

                echo "服务已启动。"

                # 返回主菜单
                cd ..
                ;;
            2)
                # 检查是否在 subspace 目录中
                if [ -d "subspace" ]; then
                    cd subspace
                    echo "显示最新的 1000 行日志（持续更新）:"
                    docker compose logs --tail=1000 -f
                else
                    echo "未找到 subspace 目录。请先启动节点。"
                fi
                # 返回主菜单
                cd ..
                ;;
            3)
                echo "退出脚本..."
                exit 0
                ;;
            *)
                echo "无效选项，请输入 1、2 或 3。"
                ;;
        esac
    done
}

# 执行主菜单函数
main_menu
