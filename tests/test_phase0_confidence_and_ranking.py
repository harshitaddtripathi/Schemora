import json
from pathlib import Path
import pytest

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "config"


def test_confidence_weights_total():
    path = DATA / "confidence-weights.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    components = data["components"]
    calculated = sum(components.values())
    assert calculated == 100, f"Confidence components must sum to 100, got {calculated}"
    assert data["total"] == 100
    for key, val in components.items():
        assert val >= 0, f"Component {key} has negative weight {val}"


def test_ranking_weights_total():
    path = DATA / "ranking-weights.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    components = data["components"]
    calculated = sum(components.values())
    assert calculated == 100, f"Ranking components must sum to 100, got {calculated}"
    assert data["total"] == 100
    for key, val in components.items():
        assert val >= 0, f"Component {key} has negative weight {val}"
