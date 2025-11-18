from datetime import datetime
from pathlib import Path
import shutil

from fastapi import FastAPI, File, Form, UploadFile

from birdnetlib import Recording
from birdnetlib.analyzer import Analyzer

app = FastAPI()

analyzer = Analyzer()

@app.post("/analyze/")
async def classify_bird(
    lat: float = Form(...),
    lon: float = Form(...),
    audio_sample: UploadFile = File(...)
):
    upload_path = Path("uploads") / audio_sample.filename

    with upload_path.open("wb") as file_buffer:
        shutil.copyfileobj(audio_sample.file, file_buffer)

    recording = Recording(
        analyzer,
        upload_path,
        date=datetime.now(),
        min_conf=0.25,
    )

    recording.analyze()

    return {"filename": audio_sample.filename, "scientific_name": recording.detections[0]["scientific_name"], "latlon": (lat, lon)}
