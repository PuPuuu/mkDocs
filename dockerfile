# 使用官方Ubuntu 20.04基础镜像
FROM ubuntu:20.04

# 更新包管理器并安装必要的系统工具和Python
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 创建工作目录
WORKDIR /app

# 从whisperX子目录复制所有必要文件（单层复制）
COPY whisperX/ /app/

# 安装项目依赖
RUN sudo apt update && sudo apt install ffmpeg -y \
    && pip install setuptools-rust \
    && pip install -U openai-whisper \
    && uv sync --all-extras --dev


# 暴露应用端口（根据您的应用需要调整）
EXPOSE 8000

# 设置启动命令（根据您的项目实际情况调整）
CMD ["uv", "run", "main.py"]