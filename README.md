# Gesture

A video-call platform that recognizes continuous sign language in near real time and renders the result as live subtitles for everyone in the room.

Built as an undergraduate thesis at VNU University of Engineering and Technology (2026). The engineering focus is **not** the recognition model itself — it is the inference system around it: turning an offline research pipeline into a streaming one, serving three deep learning models on NVIDIA Triton, and driving end-to-end latency from an unusable 8–12 s down to a stable **1.36 s average at RTF ≈ 1.0**.


---

## Results

Measured over the **complete PHOENIX-2014T test set** (~43 minutes of video streamed at 25 FPS), with the test client colocated with Triton on an RTX 4090.

| | Original paper configuration | This system |
|---|---|---|
| First-result latency | ~8 s, growing unbounded | 1.36 s average |
| P99 latency | — (never stabilized) | 1.72 s |
| Real-time factor (RTF) | > 1 — could not keep up | **1.0001** |
| Throughput | below input frame rate | 25.00 frames/s |
| WER (test) | 22.1 | 25.1 |

The original configuration prioritized accuracy and was never intended to run online: its latency grew steadily and the pipeline fell further behind the input stream over time. This system trades **+3.0 WER** for the ability to keep pace with a live 25 FPS video feed.


---

## Architecture



| Component | Role | Stack |
|---|---|---|
| **Frontend app** | Join a call, share camera/screen, control the recognition session, render gloss subtitles | Flutter (Web + Android) |
| **Real-time comms** | Room management, video distribution, control and result channel | LiveKit *(reused)* |
| **Bot server** | One bot per room — consumes the signer's stream, manages session state, orchestrates inference, publishes results | FastAPI, LiveKit Server SDK |
| **Inference server** | Serves the three-model pipeline: object detection → pose estimation → isolated sign recognition | NVIDIA Triton, TensorRT, Triton Python backend |

The recognition pipeline is organized as a **producer–consumer** chain with bounded intermediate buffers and batched inference at each stage.

---

## Scope

**Inherited** — the online CSLR method of Zuo et al., where an isolated-sign recognition (ISLR) model is applied over short sliding windows of a video stream and per-window predictions are post-processed into a gloss sequence. The ISLR model is used as pretrained on RWTH-PHOENIX-Weather 2014T. **No model was retrained**, no new architecture was proposed, and no dataset was collected.

**Built here** — everything from the model outward: reimplementing the pipeline to consume a live frame stream instead of a preprocessed dataset, the multi-component system architecture, the inference server (first a custom one, then Triton), the latency engineering, and the measurement methodology.

---

## How the latency was reduced

The interesting part was that the problem changed shape each time it was fixed.

**1. Absolute latency was too high.** The original models (Faster R-CNN + HRNet) were accurate but expensive — the first result took over 8 seconds. Replacing them with YOLOv3 and ResNet50 brought first results down to ~0.8–1.4 s.

**2. The problem became cumulative latency.** Initial latency was now fine, but grew steadily: throughput still could not keep up with 25 FPS input. This is a throughput problem, not a per-request latency problem, so it was attacked from two orthogonal directions — increase throughput (batch size tuning, CUDA streams, a stronger GPU) or reduce work (larger sliding-window stride). Both produced stable latency.

**3. Deployment architecture turned out to matter more than model optimization.** Profiling with Triton Performance Analyzer on a remotely rented GPU showed that communication cost dominated compute by orders of magnitude:

| Model | Server compute | Client–server communication |
|---|---|---|
| Detection | 129.6 ms | 0.579 s |
| Pose | **5.4 ms** | **1.435 s** |
| ISLR | 177.3 ms | 1.835 s |

The pose model spent 5.4 ms computing and 1.435 s communicating — a ratio of over 260×. No amount of per-model optimization would have fixed this; the number of cross-component round trips and the placement of servers were the real constraint.

---

## Inference server: from client-oriented to resource-oriented

A custom inference server was built first (FastAPI + WebSocket), giving each session its own pipeline instance with private worker threads and buffers. It worked for a single session, but scheduled around **client sessions** while the scarce resources are the **GPU and model instances**. Four consequences:

1. Threads, CUDA streams and buffers grew linearly with session count; GPU capacity did not.
2. No global scheduler across sessions — no way to prioritize, drop stale frames, or bound queued work.
3. Requests from different clients could not be batched together.
4. Execution capacity scaled per session, not per model — a bottleneck stage could not be given more instances independently.

Triton addresses all four by organizing serving around resources: a per-model scheduler, dynamic batching across independent requests, and per-model instance counts. Detection and pose were converted to TensorRT via MMDeploy; ISLR is served through the Triton Python backend, as it depends on the original authors' PyTorch code.

---

## Known limitations

- **1.36 s is pipeline latency, not full end-to-end system latency.** The test client ran on the same machine as Triton, excluding camera capture, LiveKit transport, and subtitle rendering.
- **RTF sits right at 1.0**, leaving no headroom for network cost or concurrent streams.
- **Concurrency was never measured.** All experiments ran a single stream, even though the argument for migrating to Triton concerns multi-session resource management. The natural next step is a Perf Analyzer concurrency sweep up to GPU saturation.
- **The stride-5 configuration has no WER measurement** — its latency benefit is quantified, its accuracy cost is not.
- **Recognition is domain-bound to PHOENIX-2014T** (German Sign Language). Vietnamese Sign Language was not viable: existing VSL datasets cover isolated signs only, with no gloss-annotated continuous corpus.
- **Output is gloss, not translated natural language.**

---

## Repository structure

```
src/
  app/         Flutter frontend (Web + Android)
  services/    Bot server and supporting services
  triton/      Triton model repository and configs
references/    Reference material and third-party code
```

## Running it

1. Install and start LiveKit — see the [LiveKit getting-started guide](https://github.com/livekit/livekit?tab=readme-ov-file#getting-started).
2. Follow the component-specific instructions in [`src/app`](src/app/README.md), [`src/services`](src/services/README.md), and [`src/triton`](src/triton/README.md).

## Stack

Python · PyTorch · NVIDIA Triton Inference Server · TensorRT · MMDetection / MMPose / MMDeploy · CUDA · FastAPI · gRPC · LiveKit · Flutter · Docker

## References

- Zuo et al., online continuous sign language recognition via sliding-window ISLR — [SLRT](https://github.com/FangyunWei/SLRT)
- RWTH-PHOENIX-Weather 2014T dataset
