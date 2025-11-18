from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import tempfile


app = FastAPI()

'''
Esto es bastante inseguro pero es para probar por mientras
'''
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Pio Pio"}

@app.post("/identificarAve")
async def identificar_ave(file: UploadFile = File(...)):
    with tempfile.NamedTemporaryFile(delete=True, suffix=".wav") as temp:
        audio = await file.read()
        temp.write(audio)
        temp.flush()

        '''
        TODO:
        aca va la funcion que llame al modelo
        resultado = modelo_clasificar(temp.name)
        '''
        resultado = None

        # TODO: aca puede ir la funcion que busque las imagenes

    return {
        "common_name": resultado['common_name'],
        "scientific_name": resultado['scientific_name'],
        "confidence": resultado['confidence']
    }  