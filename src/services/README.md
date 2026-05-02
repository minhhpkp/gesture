# Services

All backend services, including:

1. Sign Recognition Bot: Provides the video inference feature, enabling users to start and stop on-demand inference sessions on their live video feed. Encapsulates session lifecycle management and the orchestration of the server-side model pipeline.

2. LiveKit configuration and a bash script for starting a dev LiveKit server.

3. A placeholder auth service providing join tokens.

## Getting started

1. Create a Python virtual environment or Conda environment. For example:

```bash
conda create -n services python=3.12
```

2. Install dependencies:

```bash
pip install -r requirements.txt"
```

3. Create `livekit.env`, `infer.env` and `bot.env` with fields as listed in [livekit.env.example](livekit.env.example), [infer.env.example](infer.env.example), [bot.env.example](bot.env.example)
4. Run:

```bash
uvicorn services.main:app --reload --port 3000
```
