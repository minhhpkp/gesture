from services.main import app
from services.di import get_infer_orchestrator
from .fakes.fake_orchestrator import get_fake_infer_orchestrator

app.dependency_overrides[get_infer_orchestrator] = get_fake_infer_orchestrator