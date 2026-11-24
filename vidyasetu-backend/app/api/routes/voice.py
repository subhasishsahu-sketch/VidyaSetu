"""Voice API routes for Sarvam AI Text-to-Speech (TTS) and Speech-to-Text (STT)."""

import base64
import logging
from typing import Optional
from fastapi import APIRouter, File, Form, HTTPException, Response, UploadFile, status

from app.schemas.voice_schema import (
    SttResponse,
    TtsRequest,
    TtsResponse,
    ValidSttLanguage,
    ValidSttMode,
)
from app.services import voice_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/voice", tags=["Voice Intelligence (Sarvam AI)"])

AUDIO_MIME_TYPES = {
    "mp3": "audio/mpeg",
    "wav": "audio/wav",
    "aac": "audio/aac",
    "opus": "audio/opus",
}


@router.post(
    "/tts",
    response_model=TtsResponse,
    status_code=status.HTTP_200_OK,
    summary="Synthesize speech (JSON with Base64 audio)",
)
async def synthesize_speech_json(request: TtsRequest) -> TtsResponse:
    """Synthesizes speech from text and returns a JSON payload containing base64 audio."""
    return await voice_service.synthesize_speech(request)


@router.post(
    "/tts/audio",
    status_code=status.HTTP_200_OK,
    summary="Synthesize speech (Raw binary audio stream)",
    responses={
        200: {
            "content": {
                "audio/mpeg": {},
                "audio/wav": {},
                "audio/aac": {},
                "audio/opus": {},
            },
            "description": "Raw decoded audio stream suitable for direct browser or mobile playback.",
        }
    },
)
async def synthesize_speech_audio(request: TtsRequest) -> Response:
    """Synthesizes speech from text and streams decoded raw audio bytes directly."""
    tts_result = await voice_service.synthesize_speech(request)
    try:
        audio_bytes = base64.b64decode(tts_result.audio_base64)
    except Exception as exc:
        logger.error("Failed to decode base64 audio: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to decode synthesized audio output.",
        )

    media_type = AUDIO_MIME_TYPES.get(request.output_audio_codec, "audio/mpeg")
    return Response(
        content=audio_bytes,
        media_type=media_type,
        headers={
            "Content-Disposition": f'inline; filename="speech.{request.output_audio_codec}"'
        },
    )


@router.post(
    "/stt",
    response_model=SttResponse,
    status_code=status.HTTP_200_OK,
    summary="Transcribe audio file to text (STT)",
)
async def transcribe_audio(
    file: UploadFile = File(..., description="Audio file payload to transcribe"),
    language_code: ValidSttLanguage = Form(
        "od-IN", description="Language code (e.g. od-IN, en-IN, hi-IN, or unknown)"
    ),
    mode: ValidSttMode = Form(
        "transcribe",
        description="Transcription mode: transcribe, translate, verbatim, translit, codemix",
    ),
    keyterms_csv: Optional[str] = Form(
        None, description="Comma-separated keyterms for boosting domain terms"
    ),
) -> SttResponse:
    """Transcribes an uploaded audio file into text using Sarvam AI saaras:v4."""
    audio_bytes = await file.read()
    return await voice_service.transcribe_speech(
        audio_bytes=audio_bytes,
        filename=file.filename or "recording.mp3",
        content_type=file.content_type or "audio/mpeg",
        language_code=language_code,
        mode=mode,
        keyterms=keyterms_csv,
    )
