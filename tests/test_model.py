"""Quality gate run by Jenkins after train.py. A failing test stops the deploy."""
import json
from pathlib import Path

import joblib
import pandas as pd

CONFIG = json.loads(Path('config.json').read_text())
METRICS = json.loads(Path('artifacts/metrics.json').read_text())


def test_metrics_fields():
    for key in ['student_id', 'accuracy', 'training_rows', 'model_version', 'git_sha']:
        assert key in METRICS


def test_student_id():
    assert METRICS['student_id'] == 'FA23-BDS-032'


def test_training_rows_match_dataset():
    assert METRICS['training_rows'] == len(pd.read_csv('dataset/train.csv'))


def test_accuracy_threshold():
    assert METRICS['accuracy'] >= 0.70


def test_model_predicts():
    bundle = joblib.load('artifacts/model.joblib')
    row = pd.DataFrame([{f: 0.0 for f in CONFIG['features']}])
    proba = bundle['model'].predict_proba(row)[:, 1]
    assert 0.0 <= proba[0] <= 1.0
