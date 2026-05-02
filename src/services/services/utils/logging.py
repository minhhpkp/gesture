import logging
import sys

def setup_logging(log_level: str = "INFO") -> None:
    log_config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "default": {
                "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
                "datefmt": "%Y-%m-%d %H:%M:%S",
            },
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "stream": sys.stdout,
                "formatter": "default",
            },
            "file": {
                "class": "logging.handlers.RotatingFileHandler",
                "filename": "app.log",
                "maxBytes": 10_000_000,  # 10MB
                "backupCount": 5,
                "formatter": "default",
            },
        },
        "loggers": {
            "uvicorn": {"handlers": ["console"], "level": "INFO"},
            "uvicorn.access": {"handlers": ["console"], "level": "INFO"},
            "app": {"handlers": ["console", "file"], "level": log_level, "propagate": False},
        },
    }
    logging.config.dictConfig(log_config)


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(f"app.{name}")