# Gesture

A video-call platform that recognizes continuous sign language in near real time and renders the result as live subtitles for everyone in the room.

**[English](#english) · [Tiếng Việt](#tiếng-việt)**

<!-- ADD: 30–60s screen recording of the system running, exported as GIF.
     Place at docs/demo.gif and uncomment:
![Demo](docs/demo.gif)
-->

---

## English

Built as an undergraduate thesis at VNU University of Engineering and Technology (2026). The engineering focus is **not** the recognition model itself — it is the inference system around it: turning an offline research pipeline into a streaming one, serving three deep learning models on NVIDIA Triton, and driving end-to-end latency from an unusable 8–12 s down to a stable **1.36 s average at RTF ≈ 1.0**.

📄 **Full thesis (Vietnamese):** [KLTN_PHAMQUANGMINH_21020359.pdf](KLTN_PHAMQUANGMINH_21020359.pdf)

### Table of contents

- [Results](#results)
- [Architecture](#architecture)
- [Scope](#scope)
- [How the latency was reduced](#how-the-latency-was-reduced)
- [Inference server: from client-oriented to resource-oriented](#inference-server-from-client-oriented-to-resource-oriented)
- [Known limitations](#known-limitations)
- [Repository structure](#repository-structure)
- [Running it](#running-it)
- [Stack](#stack)
- [References](#references)

### Results

Measured over the **complete PHOENIX-2014T test set** (~43 minutes of video streamed at 25 FPS), with the test client colocated with Triton on an RTX 4090.

| | Original paper configuration | This system |
|---|---|---|
| First-result latency | ~8 s, growing unbounded | 1.36 s average |
| P99 latency | — (never stabilized) | 1.72 s |
| Real-time factor (RTF) | > 1 — could not keep up | **1.0001** |
| Throughput | below input frame rate | 25.00 frames/s |
| WER (test) | 22.1 | 25.1 |

The original configuration prioritized accuracy and was never intended to run online: its latency grew steadily and the pipeline fell further behind the input stream over time. This system trades **+3.0 WER** for the ability to keep pace with a live 25 FPS video feed.

<!-- ADD: latency-over-time chart (Figure 4.2 from the thesis) at docs/latency.png
![Latency over time](docs/latency.png)
-->

### Architecture

<!-- ADD: system architecture diagram (Figure 3.2 from the thesis) at docs/architecture.png
![Architecture](docs/architecture.png)
-->

| Component | Role | Stack |
|---|---|---|
| **Frontend app** | Join a call, share camera/screen, control the recognition session, render gloss subtitles | Flutter (Web + Android) |
| **Real-time comms** | Room management, video distribution, control and result channel | LiveKit *(reused)* |
| **Bot server** | One bot per room — consumes the signer's stream, manages session state, orchestrates inference, publishes results | FastAPI, LiveKit Server SDK |
| **Inference server** | Serves the three-model pipeline: object detection → pose estimation → isolated sign recognition | NVIDIA Triton, TensorRT, Triton Python backend |

The recognition pipeline is organized as a **producer–consumer** chain with bounded intermediate buffers and batched inference at each stage.

### Scope

**Inherited** — the online CSLR method of Zuo et al., where an isolated-sign recognition (ISLR) model is applied over short sliding windows of a video stream and per-window predictions are post-processed into a gloss sequence. The ISLR model is used as pretrained on RWTH-PHOENIX-Weather 2014T. **No model was retrained**, no new architecture was proposed, and no dataset was collected.

**Built here** — everything from the model outward: reimplementing the pipeline to consume a live frame stream instead of a preprocessed dataset, the multi-component system architecture, the inference server (first a custom one, then Triton), the latency engineering, and the measurement methodology.

### How the latency was reduced

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

### Inference server: from client-oriented to resource-oriented

A custom inference server was built first (FastAPI + WebSocket), giving each session its own pipeline instance with private worker threads and buffers. It worked for a single session, but scheduled around **client sessions** while the scarce resources are the **GPU and model instances**. Four consequences:

1. Threads, CUDA streams and buffers grew linearly with session count; GPU capacity did not.
2. No global scheduler across sessions — no way to prioritize, drop stale frames, or bound queued work.
3. Requests from different clients could not be batched together.
4. Execution capacity scaled per session, not per model — a bottleneck stage could not be given more instances independently.

Triton addresses all four by organizing serving around resources: a per-model scheduler, dynamic batching across independent requests, and per-model instance counts. Detection and pose were converted to TensorRT via MMDeploy; ISLR is served through the Triton Python backend, as it depends on the original authors' PyTorch code.

### Known limitations

- **1.36 s is pipeline latency, not full end-to-end system latency.** The test client ran on the same machine as Triton, excluding camera capture, LiveKit transport, and subtitle rendering.
- **RTF sits right at 1.0**, leaving no headroom for network cost or concurrent streams.
- **Concurrency was never measured.** All experiments ran a single stream, even though the argument for migrating to Triton concerns multi-session resource management. The natural next step is a Perf Analyzer concurrency sweep up to GPU saturation.
- **The stride-5 configuration has no WER measurement** — its latency benefit is quantified, its accuracy cost is not.
- **Recognition is domain-bound to PHOENIX-2014T** (German Sign Language). Vietnamese Sign Language was not viable: existing VSL datasets cover isolated signs only, with no gloss-annotated continuous corpus.
- **Output is gloss, not translated natural language.**

### Repository structure

```
src/
  app/         Flutter frontend (Web + Android)
  services/    Bot server and supporting services
  triton/      Triton model repository and configs
references/    Reference material and third-party code
```

### Running it

1. Install and start LiveKit — see the [LiveKit getting-started guide](https://github.com/livekit/livekit?tab=readme-ov-file#getting-started).
2. Follow the component-specific instructions in [`src/app`](src/app/README.md), [`src/services`](src/services/README.md), and [`src/triton`](src/triton/README.md).

### Stack

Python · PyTorch · NVIDIA Triton Inference Server · TensorRT · MMDetection / MMPose / MMDeploy · CUDA · FastAPI · gRPC · LiveKit · Flutter · Docker

### References

- Zuo et al., online continuous sign language recognition via sliding-window ISLR — [SLRT](https://github.com/FangyunWei/SLRT)
- RWTH-PHOENIX-Weather 2014T dataset

---

## Tiếng Việt

Nền tảng gọi video có khả năng nhận dạng ngôn ngữ ký hiệu liên tục gần thời gian thực và hiển thị kết quả dưới dạng phụ đề trực tiếp cho mọi người trong phòng gọi.

Đây là khóa luận tốt nghiệp tại Trường Đại học Công nghệ, ĐHQGHN (2026). Trọng tâm kỹ thuật **không** nằm ở bản thân mô hình nhận dạng, mà ở hệ thống suy luận bao quanh nó: tổ chức lại một pipeline nghiên cứu thành pipeline xử lý luồng, triển khai ba mô hình học sâu trên NVIDIA Triton, và kéo độ trễ từ mức 8–12 giây không dùng được xuống **trung bình 1,36 giây với RTF ≈ 1,0**.

📄 **Toàn văn khóa luận:** [KLTN_PHAMQUANGMINH_21020359.pdf](KLTN_PHAMQUANGMINH_21020359.pdf)

### Mục lục

- [Kết quả](#kết-quả)
- [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
- [Phạm vi: phần kế thừa và phần tự làm](#phạm-vi-phần-kế-thừa-và-phần-tự-làm)
- [Quá trình giảm độ trễ](#quá-trình-giảm-độ-trễ)
- [Server suy luận: từ hướng client sang hướng tài nguyên](#server-suy-luận-từ-hướng-client-sang-hướng-tài-nguyên)
- [Các giới hạn đã biết](#các-giới-hạn-đã-biết)
- [Cấu trúc mã nguồn](#cấu-trúc-mã-nguồn)
- [Cách chạy](#cách-chạy)
- [Công nghệ sử dụng](#công-nghệ-sử-dụng)
- [Tài liệu tham khảo](#tài-liệu-tham-khảo)

### Kết quả

Đo trên **toàn bộ tập test PHOENIX-2014T** (~43 phút video, truyền ở 25 FPS), với client thử nghiệm đặt cùng máy với Triton trên RTX 4090.

| | Cấu hình gốc của nghiên cứu | Hệ thống này |
|---|---|---|
| Độ trễ kết quả đầu tiên | ~8 giây, tăng dần không kiểm soát | trung bình 1,36 giây |
| Độ trễ P99 | — (không bao giờ ổn định) | 1,72 giây |
| Real-time factor (RTF) | > 1 — không bắt kịp đầu vào | **1,0001** |
| Throughput | thấp hơn tốc độ frame đầu vào | 25,00 frame/giây |
| WER (tập test) | 22,1 | 25,1 |

Cấu hình gốc ưu tiên độ chính xác và vốn không được thiết kế để chạy trực tuyến: độ trễ tăng dần và pipeline ngày càng tụt lại so với luồng đầu vào. Hệ thống này đánh đổi **+3,0 WER** để lấy khả năng bắt kịp luồng video 25 FPS trực tiếp.

### Kiến trúc hệ thống

| Thành phần | Vai trò | Công nghệ |
|---|---|---|
| **Ứng dụng frontend** | Tham gia phòng gọi, chia sẻ camera/màn hình, điều khiển phiên nhận dạng, hiển thị phụ đề gloss | Flutter (Web + Android) |
| **Server truyền thông thời gian thực** | Quản lý phòng gọi, phân phối luồng video, kênh truyền lệnh và kết quả | LiveKit *(sử dụng lại)* |
| **Bot server** | Mỗi phòng một bot — nhận luồng video của người ký hiệu, quản lý trạng thái phiên, điều phối suy luận, gửi kết quả | FastAPI, LiveKit Server SDK |
| **Server suy luận** | Phục vụ pipeline ba mô hình: phát hiện đối tượng → ước lượng tư thế → nhận dạng ký hiệu đơn lẻ | NVIDIA Triton, TensorRT, Triton Python backend |

Pipeline nhận dạng được tổ chức theo cơ chế **producer–consumer** với các buffer trung gian có giới hạn kích cỡ và suy luận theo batch ở từng bước.

### Phạm vi: phần kế thừa và phần tự làm

**Phần kế thừa** — phương pháp CSLR trực tuyến của Zuo và cộng sự, trong đó mô hình nhận dạng ký hiệu đơn lẻ (ISLR) được áp dụng trên các cửa sổ thời gian ngắn của luồng video, sau đó các dự đoán theo cửa sổ được hậu xử lý thành chuỗi gloss. Mô hình ISLR được sử dụng ở trạng thái đã huấn luyện sẵn trên RWTH-PHOENIX-Weather 2014T. **Không huấn luyện lại mô hình**, không đề xuất kiến trúc mới, không thu thập dữ liệu.

**Phần tự làm** — toàn bộ phần từ mô hình trở ra: hiện thực lại pipeline để xử lý trực tiếp luồng frame thay vì dữ liệu đã tiền xử lý sẵn, thiết kế kiến trúc hệ thống nhiều thành phần, xây dựng server suy luận (đầu tiên tự viết, sau chuyển sang Triton), tối ưu độ trễ, và thiết kế phương pháp đo đạc.

### Quá trình giảm độ trễ

Điểm thú vị là mỗi lần khắc phục được một vấn đề thì bản chất bài toán lại thay đổi.

**1. Độ trễ tuyệt đối quá cao.** Các mô hình gốc (Faster R-CNN + HRNet) chính xác nhưng chi phí tính toán lớn — kết quả đầu tiên mất hơn 8 giây. Thay bằng YOLOv3 và ResNet50 giúp các kết quả đầu tiên giảm còn khoảng 0,8–1,4 giây.

**2. Vấn đề chuyển thành độ trễ tích lũy.** Độ trễ ban đầu đã ổn nhưng tăng dần theo thời gian: throughput vẫn chưa bắt kịp tốc độ 25 FPS của đầu vào. Đây là bài toán throughput chứ không phải độ trễ của từng request, nên được tiếp cận theo hai hướng trực giao — tăng throughput (điều chỉnh batch size, CUDA stream, GPU mạnh hơn) hoặc giảm lượng việc (tăng bước trượt của cửa sổ). Cả hai đều cho độ trễ ổn định.

**3. Kiến trúc triển khai quan trọng hơn tối ưu từng mô hình.** Profiling bằng Triton Performance Analyzer trên GPU thuê từ xa cho thấy chi phí giao tiếp lấn át thời gian tính toán tới vài bậc độ lớn:

| Mô hình | Thời gian tính toán của server | Giao tiếp client–server |
|---|---|---|
| Det | 129,6 ms | 0,579 giây |
| Pose | **5,4 ms** | **1,435 giây** |
| ISLR | 177,3 ms | 1,835 giây |

Mô hình Pose tốn 5,4 ms để tính toán nhưng 1,435 giây để giao tiếp — tỉ lệ hơn 260 lần. Tối ưu từng mô hình riêng lẻ không thể giải quyết được vấn đề này; ràng buộc thực sự nằm ở số lượt giao tiếp giữa các thành phần và vị trí đặt server.

### Server suy luận: từ hướng client sang hướng tài nguyên

Ban đầu, một server suy luận được tự xây dựng (FastAPI + WebSocket), trong đó mỗi phiên kết nối sở hữu một pipeline instance riêng với worker thread và buffer riêng. Cách này chạy tốt với một phiên, nhưng lập lịch xoay quanh **phiên client** trong khi tài nguyên khan hiếm thực sự là **GPU và các model instance**. Bốn hệ quả:

1. Số thread, CUDA stream và buffer tăng tuyến tính theo số phiên, trong khi năng lực GPU thì không.
2. Không có bộ lập lịch toàn cục giữa các phiên — không thể ưu tiên tác vụ, bỏ frame cũ, hay giới hạn tổng lượng công việc đang chờ.
3. Không gom batch được các request từ nhiều client khác nhau.
4. Năng lực thực thi chỉ mở rộng theo số phiên, không theo từng mô hình — không thể cấp thêm instance riêng cho bước đang là nút nghẽn.

Triton khắc phục cả bốn điểm nhờ tổ chức việc phục vụ quanh tài nguyên: bộ lập lịch riêng cho từng mô hình, dynamic batching giữa các request độc lập, và cấu hình số instance riêng cho từng mô hình. Mô hình Det và Pose được chuyển sang TensorRT qua MMDeploy; ISLR được phục vụ bằng Triton Python backend do phụ thuộc vào mã nguồn PyTorch của nhóm tác giả gốc.

### Các giới hạn đã biết

- **Con số 1,36 giây là độ trễ của pipeline suy luận, chưa phải độ trễ end-to-end của toàn hệ thống.** Client thử nghiệm chạy cùng máy với Triton, nên chưa bao gồm thu nhận video từ camera, truyền qua LiveKit và hiển thị phụ đề.
- **RTF chỉ vừa đạt ngưỡng 1,0**, tức chưa có dư địa cho chi phí mạng hay nhiều luồng đồng thời.
- **Chưa đo trường hợp nhiều phiên đồng thời.** Mọi thí nghiệm đều chạy một luồng, dù lập luận cho việc chuyển sang Triton xoay quanh quản lý tài nguyên đa phiên. Bước tiếp theo hợp lý là quét concurrency bằng Perf Analyzer đến điểm bão hòa GPU.
- **Cấu hình stride 5 chưa có số liệu WER** — lợi ích về độ trễ đã đo được, chi phí về độ chính xác thì chưa.
- **Khả năng nhận dạng bị giới hạn trong miền dữ liệu PHOENIX-2014T** (ngôn ngữ ký hiệu Đức). Ngôn ngữ ký hiệu Việt Nam chưa khả thi: các tập dữ liệu VSL hiện có đều dành cho ký hiệu đơn lẻ, chưa có bộ dữ liệu liên tục có chú thích gloss.
- **Đầu ra là chuỗi gloss, chưa phải câu ngôn ngữ tự nhiên đã được dịch.**

### Cấu trúc mã nguồn

```
src/
  app/         Frontend Flutter (Web + Android)
  services/    Bot server và các dịch vụ hỗ trợ
  triton/      Model repository và cấu hình Triton
references/    Tài liệu tham khảo và mã nguồn bên thứ ba
```

### Cách chạy

1. Cài đặt và khởi động LiveKit — xem [hướng dẫn của LiveKit](https://github.com/livekit/livekit?tab=readme-ov-file#getting-started).
2. Làm theo hướng dẫn riêng của từng thành phần trong [`src/app`](src/app/README.md), [`src/services`](src/services/README.md) và [`src/triton`](src/triton/README.md).

### Công nghệ sử dụng

Python · PyTorch · NVIDIA Triton Inference Server · TensorRT · MMDetection / MMPose / MMDeploy · CUDA · FastAPI · gRPC · LiveKit · Flutter · Docker

### Tài liệu tham khảo

- Zuo và cộng sự, nhận dạng ngôn ngữ ký hiệu liên tục trực tuyến bằng ISLR theo cửa sổ trượt — [SLRT](https://github.com/FangyunWei/SLRT)
- Bộ dữ liệu RWTH-PHOENIX-Weather 2014T
