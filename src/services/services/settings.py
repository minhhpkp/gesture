from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import BaseModel
from enum import Enum


class LiveKitSettings(BaseSettings):
    api_key: str
    api_secret: str
    server_url: str

    model_config = SettingsConfigDict(
        env_file="livekit.env",
        env_file_encoding="utf-8",
        case_sensitive=False
    )


class DetectionSettings(BaseModel):
    input_size: tuple[int, int]
    batch_size: int
    batching_timeout: float | None = None
    score_thr: float = 0.5
    area_thr: int = 1600

class PoseSettings(BaseModel):
    input_size: tuple[int, int]
    mean: list[float]
    std: list[float]
    max_batch_size: int
    batching_timeout: float | None = None
    flip_test: bool = False
    use_udp: bool = False
    post_process: str = "default"
    shift_heatmap: bool = True

class VotingStrategy(str, Enum):
    MAJORITY = "MAJORITY"
    MAX_AVG_PROB = "MAX_AVG_PROB"

class CslrSettings(BaseModel):
    input_size: tuple[int, int]
    target_ratio: float = 260 / 210
    bbox_margin: float = 0.1
    crop_border: int = 10
    used_parts: list[str]
    window_size: int
    stride: int
    batch_size: int
    batching_timeout: float | None = None
    blank_id: int = 0
    num_classes: int
    voting_strategy: VotingStrategy
    voting_bag_size: int
    voting_bag_stride: int

class InferSettings(BaseSettings):
    server_url: str

    det: DetectionSettings
    pose: PoseSettings
    cslr: CslrSettings

    model_config = SettingsConfigDict(
        env_file="infer.env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        env_nested_delimiter='__'
    )


class BotSettings(BaseSettings):
    vocab_file: str
    stop_timeout: float | None = None
    
    model_config = SettingsConfigDict(
        env_file="bot.env",
        env_file_encoding="utf-8",
        case_sensitive=False
    )
