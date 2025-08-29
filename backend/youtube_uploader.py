import os
import pickle
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.auth.exceptions import RefreshError

# Este archivo debe ser descargado desde la Google Cloud Console y colocado en la carpeta 'backend'
CLIENT_SECRETS_FILE = os.path.join(os.path.dirname(__file__), 'client_secret.json')
# Este archivo almacenará los tokens de acceso del usuario
TOKEN_PICKLE_FILE = os.path.join(os.path.dirname(__file__), 'token.pickle')

# Este 'scope' permite el acceso completo para subir vídeos a la cuenta del usuario
SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]
API_SERVICE_NAME = "youtube"
API_VERSION = "v3"

def get_authenticated_service():
    """
    Autentica con la API de YouTube y devuelve un objeto de servicio.
    Maneja el flujo OAuth 2.0 y el almacenamiento de tokens.
    """
    credentials = None

    # Comprueba si tenemos credenciales almacenadas
    if os.path.exists(TOKEN_PICKLE_FILE):
        with open(TOKEN_PICKLE_FILE, "rb") as token:
            credentials = pickle.load(token)

    # Si no hay credenciales (válidas), permite que el usuario inicie sesión.
    if not credentials or not credentials.valid:
        if credentials and credentials.expired and credentials.refresh_token:
            try:
                print("Refrescando token de acceso...")
                credentials.refresh(Request())
            except RefreshError:
                print("El token de actualización ha expirado o es inválido. Se requiere nueva autenticación.")
                credentials = None # Forza la re-autenticación

        if not credentials:
            if not os.path.exists(CLIENT_SECRETS_FILE):
                raise FileNotFoundError(
                    f"No se encontró '{CLIENT_SECRETS_FILE}'. "
                    "Por favor, descarga tus credenciales de la Google Cloud Console y guárdalas como "
                    "'client_secret.json' en la carpeta 'backend'."
                )

            print("Iniciando flujo de autenticación...")
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRETS_FILE, SCOPES)
            # run_local_server abrirá una pestaña en el navegador para la autorización
            credentials = flow.run_local_server(port=0)
            print("Autenticación completada.")

        # Guarda las credenciales para la próxima ejecución
        with open(TOKEN_PICKLE_FILE, "wb") as token:
            print(f"Guardando credenciales en {TOKEN_PICKLE_FILE}")
            pickle.dump(credentials, token)

    return build(API_SERVICE_NAME, API_VERSION, credentials=credentials)

def upload_video(youtube, file_path, title, description, category_id="22", privacy_status="private"):
    """
    Sube un vídeo a YouTube.

    Args:
        youtube: El objeto de servicio de YouTube autenticado.
        file_path: Ruta al archivo de vídeo.
        title: El título del vídeo.
        description: La descripción del vídeo.
        category_id: El ID de la categoría para el vídeo (22 = People & Blogs).
        privacy_status: 'public', 'private', o 'unlisted'.

    Returns:
        La respuesta de la API de YouTube.
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"El archivo de vídeo no se encontró en: {file_path}")

    body = {
        "snippet": {
            "title": title,
            "description": description,
            "tags": ["cortador-youtube", "python", "automatizacion"],
            "categoryId": category_id
        },
        "status": {
            "privacyStatus": privacy_status
        }
    }

    print(f"Iniciando subida de '{file_path}' con título '{title}'...")
    media = MediaFileUpload(file_path, chunksize=-1, resumable=True)

    request = youtube.videos().insert(
        part=",".join(body.keys()),
        body=body,
        media_body=media
    )

    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            print(f"Subido {int(status.progress() * 100)}%.")

    print(f"¡Subida completada! ID del vídeo: {response.get('id')}")
    return response
