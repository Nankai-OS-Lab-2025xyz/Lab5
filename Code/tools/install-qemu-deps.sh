#!/bin/bash
# 安装QEMU编译依赖

echo "安装QEMU编译依赖..."

sudo apt-get update
sudo apt-get install -y \
    python3-venv \
    python3-pip \
    ninja-build \
    pkg-config \
    libglib2.0-dev \
    libpixman-1-dev \
    build-essential \
    git

echo "依赖安装完成"












