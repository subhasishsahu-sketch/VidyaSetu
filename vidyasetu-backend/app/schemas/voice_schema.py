"""Pydantic schemas for Sarvam AI Voice services (TTS & STT)."""

from typing import Literal, Optional
from pydantic import BaseModel, Field, field_validator, model_validator

ValidTtsLanguage = Literal["od-IN", "en-IN", "hi-IN"]
ValidTtsCodec = Literal["mp3", "wav", "aac", "opus"]
ValidSampleRate = Literal[8000, 16000, 22050, 24000, 32000, 44100, 48000]

ValidSttLanguage = Literal["od-IN", "en-IN", "hi-IN", "unknown"]
ValidSttMode = Literal["transcribe", "translate", "verbatim", "translit", "codemix"]


class TtsRequest(BaseModel):
    """Request payload for text-to-speech synthesis."""

    text: str = Field(..., description="Text to synthesize (1..2500 characters)")
    language_code: ValidTtsLanguage = Field(
        default="od-IN", description="Language code for synthesis"
    )
    speaker: Optional[str] = Field(
        default=None, description="Speaker persona ID (defaults to configured model persona)"
    )
    pace: float = Field(
        default=1.0, ge=0.5, le=2.0, description="Speech pace multiplier (0.5 to 2.0)"
    )
    output_audio_codec: ValidTtsCodec = Field(
        default="mp3", description="Audio container codec"
    )
    speech_sample_rate: ValidSampleRate = Field(
        default=24000, description="Audio sample rate in Hz"
    )

    @field_validator("text", mode="before")
    @classmethod
    def validate_and_strip_text(cls, v: str) -> str:
        if not isinstance(v, str):
            raise ValueError("text must be a string")
        stripped = v.strip()
        if len(stripped) < 1:
            raise ValueError("text cannot be empty or whitespace only")
        if len(stripped) > 2500:
            raise ValueError("text length exceeds maximum limit of 2500 characters")
        return stripped

    @model_validator(mode="after")
    def validate_codec_and_sample_rate(self) -> "TtsRequest":
        if self.output_audio_codec == "opus" and self.speech_sample_rate == 22050:
            raise ValueError(
                "Opus codec does not support 22050 Hz sample rate. Use 8000, 16000, 24000, or 48000 Hz."
            )
        return self


class TtsResponse(BaseModel):
    """Response payload containing base64 encoded synthesized speech."""

    audio_base64: str = Field(..., description="Base64 encoded synthesized audio")
    audio_codec: str = Field(..., description="Audio container codec")
    language_code: str = Field(..., description="Language code used for synthesis")
    model: str = Field(..., description="TTS model identifier")
    speaker: str = Field(..., description="Speaker persona used")


class SttResponse(BaseModel):
    """Response payload containing transcribed speech-to-text results."""

    transcript: str = Field(..., description="Transcribed text output")
    language_code: Optional[str] = Field(
        default=None, description="Detected or specified language code"
    )
    language_probability: Optional[float] = Field(
        default=None, description="Confidence score for language detection"
    )
    mode: str = Field(..., description="STT operating mode")
    model: str = Field(..., description="STT model identifier")
