from flask import Flask, request, jsonify
import os
import yt_dlp
from moviepy import VideoFileClip
import math
from flask_cors import CORS
from youtube_uploader import get_authenticated_service, upload_video

app = Flask(__name__)
CORS(app)

# --- Directorios de trabajo ---
DOWNLOADS_DIR = 'downloads'
CLIPS_DIR = 'clips'

def create_dirs():
    """Asegura que los directorios de trabajo existan."""
    if not os.path.exists(DOWNLOADS_DIR):
        os.makedirs(DOWNLOADS_DIR)
    if not os.path.exists(CLIPS_DIR):
        os.makedirs(CLIPS_DIR)

def download_video(url):
    """
    Descarga un vídeo de YouTube y lo guarda en el directorio 'downloads'.
    Devuelve la ruta del archivo descargado.
    """
    ydl_opts = {
        'format': 'best[ext=mp4]',
        'outtmpl': os.path.join(DOWNLOADS_DIR, '%(title)s.%(ext)s'),
        'http_headers': {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
        },
        'quiet': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=True)
        filename = ydl.prepare_filename(info)
        return filename

def split_video(filepath, clip_duration=30):
    """
    Divide un vídeo en clips de una duración determinada.
    Los clips se guardan en el directorio 'clips'.
    Devuelve una lista con las rutas de los clips.
    """
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"El archivo de vídeo no se encontró en {filepath}")

    video = VideoFileClip(filepath)
    duration = video.duration

    clip_paths = []

    for i in range(math.ceil(duration / clip_duration)):
        start_time = i * clip_duration
        end_time = min((i + 1) * clip_duration, duration)

        # Evitar crear clips de duración cero al final
        if start_time >= end_time:
            continue

        clip = video.subclipped(start_time, end_time)

        base_filename = os.path.splitext(os.path.basename(filepath))[0]
        clip_filename = f"{base_filename}_clip_{i+1}.mp4"
        clip_path = os.path.join(CLIPS_DIR, clip_filename)

        clip.write_videofile(clip_path, codec="libx264", audio_codec="aac")
        clip_paths.append(clip_path)

    video.close()
    return clip_paths

@app.route('/process', methods=['POST'])
def process_video_endpoint():
    data = request.get_json()
    if not data or 'url' not in data:
        return jsonify({'error': 'La URL es requerida'}), 400

    url = data['url']

    try:
        create_dirs()

        # Paso 1: Descargar el vídeo
        print(f"Descargando vídeo de: {url}")
        video_path = download_video(url)
        print(f"Vídeo descargado en: {video_path}")

        # Paso 2: Dividir el vídeo
        print(f"Dividiendo vídeo: {video_path}")
        clips = split_video(video_path, clip_duration=30)
        print(f"Clips generados: {clips}")

        # Paso 3: Subir los clips a YouTube
        print("Iniciando subida a YouTube...")
        try:
            youtube = get_authenticated_service()
            uploaded_videos = []

            original_video_title = os.path.splitext(os.path.basename(video_path))[0]

            for i, clip_path in enumerate(clips):
                title = f"Clip {i+1} de '{original_video_title}'"
                description = f"Este es el clip número {i+1} del vídeo original '{original_video_title}'."

                upload_response = upload_video(
                    youtube=youtube,
                    file_path=clip_path,
                    title=title,
                    description=description
                )
                uploaded_videos.append(upload_response)

            return jsonify({
                'message': '¡Vídeo procesado y subido exitosamente!',
                'downloaded_video': video_path,
                'clips_generated': clips,
                'uploaded_video_ids': [uv.get('id') for uv in uploaded_videos]
            })

        except FileNotFoundError as e:
            return jsonify({'error': f'Error de autenticación de YouTube: {e}. Ejecuta el script "python backend/run_authorization.py" en tu terminal para autorizar la aplicación.'}), 500
        except Exception as e:
            return jsonify({'error': f'Ocurrió un error durante la subida a YouTube: {e}'}), 500

    except Exception as e:
        print(f"Error durante el procesamiento: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
