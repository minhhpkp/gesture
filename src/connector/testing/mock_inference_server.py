from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import asyncio
import contextlib
from random import randint

app = FastAPI()

@app.websocket('/infer')
async def repeat(ws: WebSocket):
    await ws.accept()

    async def send():
        while True:
            await ws.send_json({'gloss_id': randint(1, 1000)})
            await asyncio.sleep(0.5)
    
    send_task = asyncio.create_task(send())

    try:
        while True:
            await ws.receive_json()
            await ws.receive_bytes()            
    except WebSocketDisconnect:
        pass
    send_task.cancel()
    with contextlib.suppress(asyncio.exceptions.CancelledError):
        await send_task