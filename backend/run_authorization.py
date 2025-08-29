from youtube_uploader import get_authenticated_service

if __name__ == "__main__":
    print("--- Proceso de Autorización para la API de YouTube ---")
    print("\nEste script te guiará para autorizar a la aplicación a subir vídeos en tu nombre.")
    print("1. Se abrirá una pestaña en tu navegador web.")
    print("2. Deberás iniciar sesión con tu cuenta de Google.")
    print("3. Deberás conceder permisos a la aplicación.")
    print("\nIMPORTANTE: Asegúrate de que tu archivo 'client_secret.json' se encuentra en esta misma carpeta ('backend').")
    print("-" * 60)

    try:
        # Al llamar a esta función, se inicia el flujo de autenticación si 'token.pickle' no existe o no es válido.
        # Esto creará el archivo token.pickle para futuras ejecuciones.
        get_authenticated_service()
        print("\n¡Autorización completada con éxito!")
        print("El archivo 'token.pickle' ha sido creado. Ahora la aplicación principal tiene permisos para subir vídeos.")
    except FileNotFoundError as e:
        print(f"\n[ERROR] No se pudo completar la autorización: {e}")
        print("Por favor, sigue las instrucciones en la documentación de Google para crear tus credenciales y guardarlas aquí.")
    except Exception as e:
        print(f"\n[ERROR] Ocurrió un error inesperado durante el proceso de autorización: {e}")
        print("Verifica tu conexión a internet y la validez de tu archivo 'client_secret.json'.")
