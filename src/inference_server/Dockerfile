FROM nvidia/cuda:11.3.1-runtime-ubuntu20.04

# Install Python 3.8, pip, ffmpeg and utilities
# Make python3 point to python3.8
# Cleans up cached package lists to make the image smaller.
# Optional: ensure pip uses python3.8
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends \
      tzdata python3.8 python3.8-venv python3-pip python3-dev ffmpeg \
      wget unzip git \
      build-essential pkg-config libavformat-dev libavcodec-dev libavutil-dev libswscale-dev && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1 && \
    rm -rf /var/lib/apt/lists/* && \
    python -m pip install --upgrade pip

# Install PyTorch with CUDA 11.1 and torchvision
RUN pip install torch==1.10.0+cu111 torchvision==0.11.0+cu111 -f https://download.pytorch.org/whl/torch_stable.html

# Install mmdet and mmpose dependencies
RUN pip install -U openmim && \
    mim install mmengine && \
    pip install mmcv-full==1.7.0 -f https://download.openmmlab.com/mmcv/dist/cu111/torch1.10.0/index.html

WORKDIR /workspace

# Install mmdet v2.25.1
RUN wget https://github.com/open-mmlab/mmdetection/archive/refs/tags/v2.25.1.zip && \
    unzip v2.25.1.zip && \
    rm v2.25.1.zip && \
    cd mmdetection-2.25.1 && \
    pip install --editable . --user

# Install mmpose v0.28.1
RUN wget https://github.com/open-mmlab/mmpose/archive/refs/tags/v0.28.1.zip && \
    unzip v0.28.1.zip && \
    rm v0.28.1.zip && \
    cd mmpose-0.28.1 && \
    pip install -r requirements.txt && \
    pip install --editable . --user

COPY . ./inference_server

# Install lintel
RUN cd ./inference_server/lintel && pip install --editable . --user

# Install other dependencies
# Fix tensorboard's distutils.version.LooseVersion import error
RUN cd ./inference_server && pip install -r requirements.txt && \
    sed -i.bak 's|LooseVersion = distutils\.version\.LooseVersion|from distutils.version import LooseVersion|' /usr/local/lib/python3.8/dist-packages/torch/utils/tensorboard/__init__.py