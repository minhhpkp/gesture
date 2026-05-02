FROM nvcr.io/nvidia/tritonserver:22.12-py3

# install dependencies of online_cslr
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libgl1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# copy dependencies and set environment variables for MMDeploy
COPY cudnn-linux-x86_64-8.9.7.29_cuda11-archive ./cudnn-8.9.7.29_cuda11
ENV CUDNN_DIR=/work/cudnn-8.9.7.29_cuda11
ENV LD_LIBRARY_PATH=$CUDNN_DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
COPY TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-11.8/TensorRT-8.6.1.6 ./TensorRT-8.6.1.6
ENV TENSORRT_DIR=/work/TensorRT-8.6.1.6
ENV LD_LIBRARY_PATH=$TENSORRT_DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

COPY environments ./environments
