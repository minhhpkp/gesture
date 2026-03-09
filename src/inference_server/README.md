# Online CSLR Inference Server

## How to run

### Using pre-built image

Run a Docker container from this [image](https://hub.docker.com/repository/docker/phamquangminh/onlinecslr/tags/1.0/sha256-bee2775f9652688db1d0c32da27cf74a09f7c6f401f87c376ae4f820badd59ec):

```bash
docker run --gpus all -it --rm --net=host -w /workplace/SLRT/Online/CSLR phamquangminh/onlinecslr:1.0 fastapi run main.py --port 8000
```
