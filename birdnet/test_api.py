import requests

sample_filename = "goose.mp3"

with open(sample_filename, "rb") as audio_file:
    r = requests.post(
        "http://localhost:8000/analyze/",
        files={"audio_sample": (sample_filename, audio_file, "audio/mpeg")},
        data={
            "lat": 12,
            "lon": 24,
        },
    )

    print(r.status_code, r.reason)
    print(r.json())
