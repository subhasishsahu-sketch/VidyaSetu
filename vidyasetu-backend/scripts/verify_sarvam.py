"""Verification script for Sarvam AI TTS (bulbul:v4-flash) and STT (saaras:v4)."""

import base64
import os
import sys
from dotenv import load_dotenv
from sarvamai import SarvamAI

def main():
    load_dotenv(".env")
    api_key = os.getenv("SARVAM_API_KEY")
    if not api_key:
        print("ERROR: SARVAM_API_KEY not found in .env", file=sys.stderr)
        sys.exit(1)

    client = SarvamAI(api_subscription_key=api_key)
    mp3_path = "tmp_test_odia.mp3"

    print("Step 1.1: Testing Text-to-Speech (bulbul:v4-flash)...")
    odia_text = "ଯୋଜନା ଆୟୋଗ ବା Planning Commission ୧୯୫୦ ମସିହାରେ ଗଠିତ ହୋଇଥିଲା।"
    
    tts_resp = client.text_to_speech.convert(
        text=odia_text,
        language_code="od-IN",
        speaker="simran_en_customer",
        output_audio_codec="mp3",
        model="bulbul:v4-flash",
    )

    if not tts_resp.audios:
        print("ERROR: No audio returned from TTS", file=sys.stderr)
        sys.exit(1)

    audio_bytes = base64.b64decode(tts_resp.audios[0])
    with open(mp3_path, "wb") as f:
        f.write(audio_bytes)
    print(f"TTS succeeded! Audio saved to {mp3_path} ({len(audio_bytes)} bytes)")

    print("\nStep 1.2: Testing Speech-to-Text (saaras:v4)...")
    with open(mp3_path, "rb") as audio_file:
        stt_resp = client.speech_to_text.transcribe(
            file=("tmp_test_odia.mp3", audio_file.read(), "audio/mpeg"),
            model="saaras:v4",
            mode="transcribe",
            language_code="od-IN",
            keyterms=["Planning Commission"],
        )

    print(f"STT Transcript: {stt_resp.transcript}")
    print(f"Language Code: {stt_resp.language_code}")
    if hasattr(stt_resp, "language_probability") and stt_resp.language_probability is not None:
        print(f"Language Probability: {stt_resp.language_probability}")

    print("\nCleaning up temporary test audio...")
    if os.path.exists(mp3_path):
        os.remove(mp3_path)
        print("Temporary file cleaned up successfully.")

    print("\nStep 1 Live API Verification PASSED 100%!")

if __name__ == "__main__":
    main()
