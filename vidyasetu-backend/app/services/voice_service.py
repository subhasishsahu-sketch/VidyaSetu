"""Voice Service integrating Sarvam AI Text-to-Speech (TTS) and Speech-to-Text (STT)."""

import logging
from typing import Any, List, Optional, Union
from fastapi import HTTPException, status
from sarvamai import AsyncSarvamAI
from sarvamai.core.api_error import ApiError

from app.core.config import settings
from app.schemas.voice_schema import SttResponse, TtsRequest, TtsResponse

logger = logging.getLogger(__name__)

# Reusable client instance
_sarvam_client: Optional[AsyncSarvamAI] = None

MAX_AUDIO_SIZE_BYTES = 25 * 1024 * 1024  # 25 MB
MAX_KEYTERMS = 50
MAX_KEYTERM_LENGTH = 64


def get_sarvam_client() -> AsyncSarvamAI:
    """Retrieves or initializes the cached AsyncSarvamAI client."""
    global _sarvam_client
    if not settings.SARVAM_API_KEY or not settings.SARVAM_API_KEY.strip():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Sarvam AI service is unconfigured or unavailable. Missing SARVAM_API_KEY.",
        )
    if _sarvam_client is None:
        _sarvam_client = AsyncSarvamAI(api_subscription_key=settings.SARVAM_API_KEY)
    return _sarvam_client


def set_sarvam_client(client: Optional[AsyncSarvamAI]) -> None:
    """Sets or resets the client instance (useful for unit testing and mocks)."""
    global _sarvam_client
    _sarvam_client = client


def sanitize_keyterms(
    raw_terms: Optional[Union[List[str], str]]
) -> Optional[List[str]]:
    """Sanitizes, deduplicates, and limits keyterms for Sarvam STT.

    Rules:
    - Strips whitespace and drops empty terms
    - Deduplicates while preserving order
    - Enforces <= 64 characters per term
    - Caps total terms at 50
    """
    if raw_terms is None:
        return None

    if isinstance(raw_terms, str):
        candidates = [t.strip() for t in raw_terms.split(",")]
    elif isinstance(raw_terms, (list, tuple)):
        candidates = [str(t).strip() for t in raw_terms]
    else:
        candidates = []

    sanitized: List[str] = []
    seen = set()

    for term in candidates:
        if not term:
            continue
        trimmed_term = term[:MAX_KEYTERM_LENGTH]
        if trimmed_term not in seen:
            seen.add(trimmed_term)
            sanitized.append(trimmed_term)
        if len(sanitized) >= MAX_KEYTERMS:
            break

    return sanitized if sanitized else None


async def synthesize_speech(req: TtsRequest) -> TtsResponse:
    """Synthesizes speech from text using Sarvam AI bulbul:v4-flash."""
    client = get_sarvam_client()
    speaker = req.speaker or settings.SARVAM_TTS_SPEAKER

    try:
        resp = await client.text_to_speech.convert(
            text=req.text,
            language_code=req.language_code,
            speaker=speaker,
            pace=req.pace,
            speech_sample_rate=req.speech_sample_rate,
            output_audio_codec=req.output_audio_codec,
            model=settings.SARVAM_TTS_MODEL,
        )
    except ApiError as exc:
        logger.error("Sarvam TTS API error: %s", exc)
        status_code = (
            exc.status_code
            if (exc.status_code and 400 <= exc.status_code < 600)
            else status.HTTP_502_BAD_GATEWAY
        )
        raise HTTPException(
            status_code=status_code,
            detail=f"Sarvam AI API error: {exc.body or 'Upstream error'}",
        )
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Unexpected error in Sarvam TTS: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Failed to synthesize speech via Sarvam AI.",
        )

    if not resp.audios:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Sarvam AI returned empty audio response.",
        )

    return TtsResponse(
        audio_base64=resp.audios[0],
        audio_codec=req.output_audio_codec,
        language_code=req.language_code,
        model=settings.SARVAM_TTS_MODEL,
        speaker=speaker,
    )


async def transcribe_speech(
    audio_bytes: bytes,
    filename: str,
    content_type: str,
    language_code: str = "od-IN",
    mode: str = "transcribe",
    keyterms: Optional[Union[List[str], str]] = None,
) -> SttResponse:
    """Transcribes speech to text using Sarvam AI saaras:v4."""
    if not audio_bytes or len(audio_bytes) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Empty audio file provided.",
        )

    if len(audio_bytes) > MAX_AUDIO_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_CONTENT_TOO_LARGE,
            detail="Audio file too large. Maximum allowed size is 25 MB.",
        )

    client = get_sarvam_client()
    sanitized_keyterms = sanitize_keyterms(keyterms)

    stt_kwargs: dict[str, Any] = {
        "file": (filename or "audio.mp3", audio_bytes, content_type or "audio/mpeg"),
        "model": settings.SARVAM_STT_MODEL,
        "mode": mode,
        "language_code": language_code,
    }
    if sanitized_keyterms:
        stt_kwargs["keyterms"] = sanitized_keyterms

    try:
        resp = await client.speech_to_text.transcribe(**stt_kwargs)
    except ApiError as exc:
        logger.error("Sarvam STT API error: %s", exc)
        status_code = (
            exc.status_code
            if (exc.status_code and 400 <= exc.status_code < 600)
            else status.HTTP_502_BAD_GATEWAY
        )
        raise HTTPException(
            status_code=status_code,
            detail=f"Sarvam AI API error: {exc.body or 'Upstream error'}",
        )
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Unexpected error in Sarvam STT: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Failed to transcribe speech via Sarvam AI.",
        )

    return SttResponse(
        transcript=resp.transcript,
        language_code=getattr(resp, "language_code", None),
        language_probability=getattr(resp, "language_probability", None),
        mode=mode,
        model=settings.SARVAM_STT_MODEL,
    )
