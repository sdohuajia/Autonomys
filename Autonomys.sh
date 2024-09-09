#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/Autonomys.sh"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 执行选项 1 的所有命令
function execute_option_1() {
    # 创建目录
    mkdir -p ~/.local/bin
    mkdir -p ~/.local/share
    echo "目录 ~/.local/bin 和 ~/.local/share 已创建。"
    
    # 下载 Node
    wget -O ~/.local/bin/subspace-node https://github.com/autonomys/subspace/releases/download/gemini-3h-2024-sep-03/subspace-node-ubuntu-x86_64-skylake-gemini-3h-2024-sep-03
    echo "Node 文件已下载到 ~/.local/bin/subspace-node。"

    # 下载 Farmer
    wget -O ~/.local/bin/subspace-farmer https://github.com/autonomys/subspace/releases/download/gemini-3h-2024-sep-03/subspace-farmer-ubuntu-x86_64-skylake-gemini-3h-2024-sep-03
    echo "Farmer 文件已下载到 ~/.local/bin/subspace-farmer。"
    
    # 设置执行权限
    chmod +x ~/.local/bin/subspace-node
    chmod +x ~/.local/bin/subspace-farmer
    echo "已设置执行权限。"

    # 创建和编辑 systemd 服务文件
    SERVICE_FILE_NODE="/etc/systemd/system/subspace-node.service"
    cat <<EOL > $SERVICE_FILE_NODE
[Unit]
Description=Subspace Node
Wants=network.target
After=network.target

[Service]
User=subspace
Group=subspace
ExecStart=/root/.local/bin/subspace-node \\
          run \\
          --name subspace \\
          --base-path /root/.local/share/subspace-node \\
          --chain gemini-3h \\
          --farmer \\
          --listen-on /ip4/0.0.0.0/tcp/30333 \\
          --dsn-listen-on /ip4/0.0.0.0/tcp/30433           
KillSignal=SIGINT
Restart=always
RestartSec=10
Nice=-5
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOL
    echo "systemd 服务文件 subspace-node.service 已创建并编辑为 $SERVICE_FILE_NODE。"

    # 获取用户输入的奖励地址
    read -p "请输入奖励地址: " REWARD_ADDRESS

    # 创建和编辑 systemd 服务文件
    SERVICE_FILE_FARMER="/etc/systemd/system/subspace-farmer.service"
    cat <<EOL > $SERVICE_FILE_FARMER
[Unit]
Description=Subspace Farmer
Wants=network.target
After=network.target
Wants=subspace-node.service
After=subspace-node.service

[Service]
User=subspace
Group=subspace
ExecStart=/root/.local/bin/subspace-farmer \\
          farm \\
          --reward-address $REWARD_ADDRESS \\
          --listen-on /ip4/0.0.0.0/tcp/30533 \\
          path=/root/.local/share/subspace-farmer,size=100G           
KillSignal=SIGINT
Restart=always
RestartSec=10
Nice=-5
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOL
    echo "systemd 服务文件 subspace-farmer.service 已创建并编辑为 $SERVICE_FILE_FARMER。"

    # 重新加载 systemd 配置并启动服务
    sudo systemctl daemon-reload
    sudo systemctl enable --now subspace-node.service subspace-farmer.service
    echo "systemd 服务 subspace-node 和 subspace-farmer 已启用并设置为开机自启。"

    # 额外启动服务
    sudo systemctl start subspace-node
    sudo systemctl start subspace-farmer
    echo "systemd 服务 subspace-node 和 subspace-farmer 已启动。"

    # 提示用户按任意键返回主菜单
    read -p "按 Enter 键返回主菜单..."
}

# 停止节点函数
function stop_services() {
    sudo systemctl stop subspace-node
    sudo systemctl stop subspace-farmer
    echo "systemd 服务 subspace-node 和 subspace-farmer 已停止。"
    read -p "按 Enter 键返回主菜单..."
}

# 检查服务状态函数
function check_services_status() {
    echo "检查服务状态:"
    echo "--------------------"
    echo "Subspace Node 服务状态:"
    sudo systemctl status subspace-node
    read -p "按任意键查看 Subspace Farmer 服务状态..."

    echo "Subspace Farmer 服务状态:"
    sudo systemctl status subspace-farmer
    echo "--------------------"
    echo "按键盘 ctrl + C 退出查看状态并返回主菜单..."
}

# 查看日志函数
function view_logs() {
    echo "查看服务日志:"
    echo "--------------------"
    echo "Subspace Node 日志:"
    sudo journalctl -f -o cat -u subspace-node
    read -p "按任意键查看 Subspace Farmer 日志..."

    echo "Subspace Farmer 日志:"
    sudo journalctl -f -o cat -u subspace-farmer
    echo "--------------------"
    echo "按键盘 ctrl + C 退出查看日志并返回主菜单..."
}

# 查看奖励函数
function check_rewards() {
    echo "查看奖励数量:"
    REWARDS_COUNT=$(sudo journalctl -o cat -u subspace-farmer --since="1 hour ago" | grep -i "Successfully signed reward hash" | wc -l)
    echo "过去一小时内成功签署的奖励数量: $REWARDS_COUNT"
    read -p "按 Enter 键返回主菜单..."
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 安装并启动节点"
        echo "2. 停止节点"
        echo "3. 检查节点服务状态"
        echo "4. 查看日志"
        echo "5. 查看奖励"
        echo "6. 退出脚本"
        read -p "请输入你的选择 (1/2/3/4/5/6): " choice

        case $choice in
            1)
                execute_option_1
                ;;
            2)
                stop_services
                ;;
            3)
                check_services_status
                ;;
            4)
                view_logs
                ;;
            5)
                check_rewards
                ;;
            6)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效的选择，请输入 1、2、3、4、5 或 6。"
                read -p "按 Enter 键重新选择..."
                ;;
        esac
    done
}

# 调用主菜单函数
main_menu
