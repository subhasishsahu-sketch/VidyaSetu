"""Unit and integration tests for Sarvam AI Voice TTS & STT endpoints."""

import base64
from unittest.mock import AsyncMock, MagicMock, patch
import pytest
from httpx import ASGITransport, AsyncClient
from sarvamai.core.api_error import ApiError
from sarvamai.types.speech_to_text_response import SpeechToTextResponse
from sarvamai.types.text_to_speech_response import TextToSpeechResponse

from app.core.config import settings
from app.main import app
from app.services import voice_service


@pytest.fixture(autouse=True)
def reset_voice_client():
    """Ensures voice_service client is reset before and after each test."""
    voice_service.set_sarvam_client(None)
    yield
    voice_service.set_sarvam_client(None)


@pytest.fixture
def mock_sarvam_client():
    """Creates a mock AsyncSarvamAI client."""
    client = MagicMock()
    client.text_to_speech = MagicMock()
    client.text_to_speech.convert = AsyncMock()
    client.speech_to_text = MagicMock()
    client.speech_to_text.transcribe = AsyncMock()
    return client


# ---------------------------------------------------------------------------
# TTS Validation Tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_tts_validation_empty_and_whitespace():
    """Ensures empty and whitespace-only text returns 422 Unprocessable Entity."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Empty string
        resp1 = await ac.post("/api/v1/voice/tts", json={"text": ""})
        assert resp1.status_code == 422

        # Whitespace-only string
        resp2 = await ac.post("/api/v1/voice/tts", json={"text": "   \n\t  "})
        assert resp2.status_code == 422


@pytest.mark.asyncio
async def test_tts_validation_max_length():
    """Ensures text exceeding 2500 characters returns 422."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        long_text = "ଓ" * 2501
        resp = await ac.post("/api/v1/voice/tts", json={"text": long_text})
        assert resp.status_code == 422


@pytest.mark.asyncio
async def test_tts_validation_invalid_pace():
    """Ensures speech pace outside 0.5..2.0 returns 422."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp_low = await ac.post(
            "/api/v1/voice/tts", json={"text": "ନମସ୍କାର", "pace": 0.3}
        )
        assert resp_low.status_code == 422

        resp_high = await ac.post(
            "/api/v1/voice/tts", json={"text": "ନମସ୍କାର", "pace": 2.5}
        )
        assert resp_high.status_code == 422


@pytest.mark.asyncio
async def test_tts_validation_opus_with_22050_sample_rate():
    """Ensures opus codec with 22050 Hz sample rate is rejected with 422."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.post(
            "/api/v1/voice/tts",
            json={
                "text": "ନମସ୍କାର",
                "output_audio_codec": "opus",
                "speech_sample_rate": 22050,
            },
        )
        assert resp.status_code == 422
        assert "Opus codec does not support 22050 Hz" in resp.text


# ---------------------------------------------------------------------------
# TTS Successful Execution Tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_tts_json_endpoint_success(mock_sarvam_client):
    """Verifies POST /api/v1/voice/tts returns JSON with base64 audio."""
    fake_audio_base64 = base64.b64encode(b"FAKE_AUDIO_BYTES").decode("utf-8")
    mock_sarvam_client.text_to_speech.convert.return_value = TextToSpeechResponse(
        request_id="req-tts-1",
        audios=[fake_audio_base64],
    )
    voice_service.set_sarvam_client(mock_sarvam_client)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.post(
            "/api/v1/voice/tts",
            json={
                "text": "ଯୋଜନା ଆୟୋଗ ଗଠିତ ହୋଇଥିଲା।",
                "language_code": "od-IN",
                "output_audio_codec": "mp3",
            },
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["audio_base64"] == fake_audio_base64
        assert data["audio_codec"] == "mp3"
        assert data["language_code"] == "od-IN"
        assert data["model"] == "bulbul:v4-flash"
        assert data["speaker"] == settings.SARVAM_TTS_SPEAKER

        mock_sarvam_client.text_to_speech.convert.assert_awaited_once_with(
            text="ଯୋଜନା ଆୟୋଗ ଗଠିତ ହୋଇଥିଲା।",
            language_code="od-IN",
            speaker=settings.SARVAM_TTS_SPEAKER,
            pace=1.0,
            speech_sample_rate=24000,
            output_audio_codec="mp3",
            model="bulbul:v4-flash",
        )


@pytest.mark.asyncio
async def test_tts_audio_raw_endpoint_success(mock_sarvam_client):
    """Verifies POST /api/v1/voice/tts/audio streams raw binary audio."""
    raw_bytes = b"MP3_RAW_HEADER_DATA_12345"
    fake_audio_base64 = base64.b64encode(raw_bytes).decode("utf-8")
    mock_sarvam_client.text_to_speech.convert.return_value = TextToSpeechResponse(
        request_id="req-tts-2",
        audios=[fake_audio_base64],
    )
    voice_service.set_sarvam_client(mock_sarvam_client)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.post(
            "/api/v1/voice/tts/audio",
            json={
                "text": "ପ୍ରକାଶ ସଂଶ୍ଳେଷଣ ପ୍ରକ୍ରିୟା",
                "language_code": "od-IN",
                "output_audio_codec": "wav",
                "speech_sample_rate": 16000,
            },
        )
        assert resp.status_code == 200
        assert resp.content == raw_bytes
        assert resp.headers["content-type"].startswith("audio/wav")
        assert 'filename="speech.wav"' in resp.headers["content-disposition"]


# ---------------------------------------------------------------------------
# STT Tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_stt_endpoint_success(mock_sarvam_client):
    """Verifies POST /api/v1/voice/stt transcribes uploaded audio."""
    mock_sarvam_client.speech_to_text.transcribe.return_value = SpeechToTextResponse(
        request_id="req-stt-1",
        transcript="ଯୋଜନା ଆୟୋଗ ବା Planning Commission",
        language_code="od-IN",
        language_probability=0.97,
    )
    voice_service.set_sarvam_client(mock_sarvam_client)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        files = {"file": ("student_answer.mp3", b"FAKE_AUDIO_DATA", "audio/mpeg")}
        data = {
            "language_code": "od-IN",
            "mode": "transcribe",
            "keyterms_csv": "Planning Commission, NITI Aayog",
        }
        resp = await ac.post("/api/v1/voice/stt", files=files, data=data)
        assert resp.status_code == 200
        result = resp.json()
        assert result["transcript"] == "ଯୋଜନା ଆୟୋଗ ବା Planning Commission"
        assert result["language_code"] == "od-IN"
        assert result["language_probability"] == 0.97
        assert result["mode"] == "transcribe"
        assert result["model"] == "saaras:v4"

        # Verify keyterms were passed sanitized
        _, kwargs = mock_sarvam_client.speech_to_text.transcribe.call_args
        assert kwargs["keyterms"] == ["Planning Commission", "NITI Aayog"]
        assert kwargs["language_code"] == "od-IN"
        assert kwargs["mode"] == "transcribe"


@pytest.mark.asyncio
async def test_stt_empty_file_rejected_400():
    """Ensures 0-byte uploaded file returns HTTP 400."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        files = {"file": ("empty.mp3", b"", "audio/mpeg")}
        resp = await ac.post("/api/v1/voice/stt", files=files)
        assert resp.status_code == 400
        assert "Empty audio file" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_stt_oversized_file_rejected_413():
    """Ensures uploaded audio > 25 MB returns HTTP 413."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        oversized_bytes = b"X" * (25 * 1024 * 1024 + 10)
        files = {"file": ("huge.mp3", oversized_bytes, "audio/mpeg")}
        resp = await ac.post("/api/v1/voice/stt", files=files)
        assert resp.status_code == 413
        assert "Maximum allowed size is 25 MB" in resp.json()["detail"]


def test_keyterms_sanitization():
    """Directly tests keyterms sanitization rules."""
    # Duplicates, whitespace, empty items
    raw_csv = "  Photosynthesis , Chlorophyll, , Photosynthesis ,  "
    sanitized = voice_service.sanitize_keyterms(raw_csv)
    assert sanitized == ["Photosynthesis", "Chlorophyll"]

    # Term longer than 64 characters
    long_term = "A" * 80
    sanitized_long = voice_service.sanitize_keyterms([long_term])
    assert sanitized_long == ["A" * 64]

    # More than 50 terms capped at 50
    many_terms = [f"term_{i}" for i in range(70)]
    sanitized_many = voice_service.sanitize_keyterms(many_terms)
    assert len(sanitized_many) == 50
    assert sanitized_many[0] == "term_0"
    assert sanitized_many[49] == "term_49"


# ---------------------------------------------------------------------------
# Error Handling Tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_missing_api_key_503():
    """Ensures HTTP 503 is returned when SARVAM_API_KEY is not configured."""
    with patch.object(settings, "SARVAM_API_KEY", ""):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            resp = await ac.post("/api/v1/voice/tts", json={"text": "ପରୀକ୍ଷା"})
            assert resp.status_code == 503
            assert "Missing SARVAM_API_KEY" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_upstream_api_error_mapping(mock_sarvam_client):
    """Ensures upstream Sarvam ApiError is cleanly translated without leaking secrets."""
    mock_sarvam_client.text_to_speech.convert.side_effect = ApiError(
        status_code=400,
        body="Unsupported language request",
    )
    voice_service.set_sarvam_client(mock_sarvam_client)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.post("/api/v1/voice/tts", json={"text": "ନମସ୍କାର"})
        assert resp.status_code == 400
        assert "Unsupported language request" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_empty_audio_list_from_sarvam_502(mock_sarvam_client):
    """Ensures empty audios list from Sarvam raises HTTP 502 instead of IndexError."""
    mock_sarvam_client.text_to_speech.convert.return_value = TextToSpeechResponse(
        request_id="req-empty",
        audios=[],
    )
    voice_service.set_sarvam_client(mock_sarvam_client)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.post("/api/v1/voice/tts", json={"text": "ପରୀକ୍ଷା"})
        assert resp.status_code == 502
        assert "Sarvam AI returned empty audio response" in resp.json()["detail"]
