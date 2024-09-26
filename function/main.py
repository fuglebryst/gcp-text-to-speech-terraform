import functions_framework
from google.cloud import storage
from google.cloud import texttospeech

@functions_framework.cloud_event
def process_file(event):
    """Cloud Function triggered by Cloud Storage when a file is changed."""
    data = event.data
    file_name = data["name"]
    bucket_name = data["bucket"]

    storage_client = storage.Client()

    # Download the file from GCS
    blob = storage_client.bucket(bucket_name).blob(file_name)
    blob.download_to_filename("/tmp/input.txt")

    # Initialize Text-to-Speech client
    client = texttospeech.TextToSpeechClient()
    with open("/tmp/input.txt", "r") as f:
        text = f.read()

    voices = client.list_voices()
    voice_name = None
    for voice in voices.voices:
        if voice.language_codes[0] == "nb-NO":
            voice_name = voice.name
            break

    if voice_name is None:
        raise ValueError("Voice not found")

    language_code = "nb-NO"
    voice = texttospeech.VoiceSelectionParams(language_code=language_code, name=voice_name)
    audio_config = texttospeech.AudioConfig(audio_encoding=texttospeech.AudioEncoding.MP3)

    response = client.synthesize_speech(
        input=texttospeech.SynthesisInput(text=text), voice=voice, audio_config=audio_config
    )

    # Upload the synthesized speech to GCS
    output_blob = storage_client.bucket(bucket_name).blob(f"{file_name}_output.mp3")
    output_blob.upload_from_string(response.audio_content)

    print(f"Synthesized speech uploaded to {output_blob.name}")
