# Triton

Models deployed on NVIDIA Triton inference server.

## Getting started

1. Build the Docker image or use `phamquangminh/sign_recognition:1.0`.

2. Start a Docker container, upload or copy the `models` folder.

3. Start the Triton server:

```
tritonserver --model-repository=/path/to/models
```
