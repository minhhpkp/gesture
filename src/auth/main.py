from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv
from livekit import api

# make sure that LIVEKIT_URL, LIVEKIT_API_KEY, and LIVEKIT_API_SECRET are set
load_dotenv()

app = FastAPI()

class CreateJoinTokenRequest(BaseModel):
    username: str
    roomId: str

@app.post("/join-tokens")
def createJoinToken(req: CreateJoinTokenRequest):    
    token = (
        api.AccessToken()
        .with_identity(req.username.strip())
        .with_grants(
            api.VideoGrants(
                room_join=True,
                room=req.roomId.strip(),
            )
        )
        .to_jwt()
    )
    return { "token": token, }