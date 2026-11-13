
## Instalación y configuración

Para instalar FitAccess v4.1 desde cero en Windows,
consulta el documento:

[Guía completa de instalación](GUIA_INSTALACION_FITACCESS_V4_1_WINDOWS.md)

# FitAccess v4 

## Qué contiene y qué NO contiene

```
fitaccess/
├─ app_movil/              # Flutter/Dart, assets, sonidos, iconos Android
│  ├─ lib/
│  ├─ assets/
│  ├─ android_icons/       # Se instalan después de flutter create
│  └─ pubspec.yaml
├─ backend/                # FastAPI, DeepFace, MTCNN, FaceNet512, autenticación X-API-Key
│  ├─ app/
│  ├─ modelo_exportado/    # Config reconstruida del notebook; SIN galería original
│  ├─ requirements.txt
│  └─ .env.example
├─ database/
│  ├─ schema.sql            # Instalación NUEVA: tablas con cedula UNIQUE
│  └─ migracion_cedula.sql  # Bases antiguas, no necesaria para DB nueva
└─ scripts/
   └─ preparar_android_windows.ps1
```

No incluye `.venv`, `build/`, `.dart_tool/`, Gradle/Android SDK, Python, PostgreSQL, `pgvector`, pesos descargados de FaceNet, APK, ni galería original de 7 personas. Tampoco incluye contraseñas o fotografías biométricas.

La configuración `backend/modelo_exportado/config_reconocimiento.json` incluida es **reconstruida desde las constantes del notebook académico** (FaceNet512, MTCNN, 512 componentes, umbral 0.260, calidad de imagen). Si conservas el archivo original exportado por Jupyter, reemplaza este archivo por el original para reproducir exactamente el experimento. **Esta configuración no recupera la galería original de embeddings**.

## A. Windows 11: preparar solo Flutter + APK

1. Instala o verifica Flutter **3.47.7**, Dart y Android SDK (tu SDK 36 es compatible para compilar Android). No necesitas Chrome, Visual Studio C++, emulador ni cámara externa. Abre PowerShell.
2. Extrae en una **ruta corta sin carpetas sincronizadas**, por ejemplo `C:\dev\fitaccess`. Evita la ruta larga en `Documents\INSTITUTO\Proyecto Final...`.
3. Desde `C:\dev\fitaccess`:

```powershell
flutter --version
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\preparar_android_windows.ps1
cd .\app_movil
flutter pub get
flutter analyze
# Flutter create genera un test de plantilla que busca la clase inexistente MyApp.
# Si aparece ese único error, borra SOLO test/widget_test.dart:
# Remove-Item .\test\widget_test.dart
flutter build apk --release
```

El script crea la carpeta `android/` con `flutter create . --platforms=android --project-name gimnasio_facial` **solo si falta**. Mantiene las soluciones que ya verificaste: `minSdk=24`, permiso CAMERA/INTERNET, HTTP local y R8/minify desactivado (evita el `InputImageConverterError` que sufrimos). No actualiza bibliotecas indiscriminadamente.

APK: `app_movil\build\app\outputs\flutter-apk\app-release.apk`. Pásalo al teléfono Android e instálalo. Como este proyecto genera un APK local firmado con la clave de depuración predeterminada, si cambió la clave respecto al APK instalado puede ser necesario desinstalar la app anterior (pierdes su configuración local; **no** los datos del backend).

**Cámaras:** en reconocimiento automático se inicia **primero la frontal** si el sistema la ofrece, con un icono de **cambiar cámara** arriba a la derecha para alternar con la trasera. Si la frontal no puede inicializarse, la app intenta abrir la trasera. En matriculación se inicia **la trasera** y ya existe un icono para alternar cámaras. Si la frontal está físicamente averiada pero Android igualmente la enumera, utiliza el icono para cambiar a la trasera. Comprueba el reto de parpadeo/giro con la cámara usada, ya que la compatibilidad depende del hardware.

**`flutter doctor`:** los errores para Chrome (web) y Visual Studio/C++ (Windows escritorio) son irrelevantes para compilar `--release` APK Android. `flutter analyze` que termina con `LspByteStreamServerChannel FormatException` suele indicar que el servidor de análisis recibió JSON incompleto, no que el proyecto tenga mil errores. Prueba la ruta corta, reinicia VS Code y ejecuta `flutter pub get` y `flutter analyze` nuevamente.

## B. Windows 11: FastAPI nuevo (opcional, si quieres ejecutar backend en PC)

Instala **Python 3.11 x64** y **PostgreSQL 16 + extensión pgvector habilitada en el servidor**. El instalador de Python debe estar disponible por `py -3.11`. La carpeta `.venv` que copiaste desde otra PC no sirve: la eliminamos a propósito.

```powershell
cd C:\dev\fitaccess\backend
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Edita `backend\.env` **sin compartir claves**: sustituye `TU_CLAVE_POSTGRES` y genera una nueva `ADMIN_API_KEY` aleatoria de al menos 32 caracteres. La base del ejemplo es `fitaccess`.

Para crear una base vacía desde PowerShell (si PostgreSQL está instalado y funcionando):

```powershell
$pg = 'C:\Program Files\PostgreSQL\16\bin'
& "$pg\createdb.exe" -U postgres -h 127.0.0.1 fitaccess
& "$pg\psql.exe" -U postgres -h 127.0.0.1 -d fitaccess -f 'C:\dev\fitaccess\database\schema.sql' -v ON_ERROR_STOP=1
```

**Necesitas instalar `pgvector` en PostgreSQL previamente**. Si `CREATE EXTENSION vector` falla, pgvector todavía no está instalado. No abras el puerto 5432 al teléfono. Luego:

```powershell
cd C:\dev\fitaccess\backend
.\.venv\Scripts\Activate.ps1
python -m unittest discover -s tests -v
python -m uvicorn app.api:app --host 0.0.0.0 --port 8000
```

Abre `http://127.0.0.1:8000/health` y `http://127.0.0.1:8000/docs` desde el PC (nunca `0.0.0.0/docs`). La aplicación móvil usa `http://IP_DEL_PC:8000`, con la misma clave de `.env`. El puerto 8000 requiere permitir conexiones entrantes desde la red privada de prueba, si las bloquea el firewall.

**Sin la galería previa:** esta nueva base empieza con cero usuarios. Puedes matricular nuevos voluntarios desde Flutter sin entrenar FaceNet. Si necesitas los siete originales, copia un respaldo PostgreSQL (`pg_dump`/`pg_restore`) de la máquina previa o restaura `backend/modelo_exportado/galeria_embeddings.json` junto con su `config_reconocimiento.json` original y ejecuta `python -m scripts.import_gallery` sobre una base VACÍA. No inventes embeddings. **Nunca ejecutes importación de galería sobre una base que ya tenga matrículas sin comprobar qué contiene.**

## C. Toshiba Xubuntu: solo backend, sin AVD ni Flutter

Es la arquitectura recomendada para esa laptop. Primero comprueba:

```bash
python3 --version
free -h
psql --version
```

Recomiendo **Python 3.11** para las versiones fijadas de TensorFlow/DeepFace. En Xubuntu, instala Python 3.11 desde el gestor de paquetes de tu versión o mediante pyenv si no existe en los repositorios. Usa los paquetes de desarrollo necesarios (`python3.11-venv`, `python3.11-dev`) que correspondan a tu sistema.

Con PostgreSQL 16 y pgvector instalados/habilitados, crea una base vacía `fitaccess` en PostgreSQL y ejecuta `database/schema.sql` con `psql`. **Comprueba primero** qué versión de PostgreSQL ofrece tu Xubuntu: no todas traen PostgreSQL 16 de fábrica; necesitarás paquetes compatibles, y puede ser necesario agregar el repositorio PGDG. No copies archivos internos de PostgreSQL de Windows a Linux.

Para crear el entorno Python de Linux:

```bash
cd ~/fitaccess/backend
python3.11 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
cp .env.example .env
```

Edita `.env` con tus credenciales locales y `DATABASE_URL=postgresql://...@127.0.0.1:5432/fitaccess`, y genera `ADMIN_API_KEY` nueva. Si copiaste el archivo `config_reconocimiento.json` original del notebook, úsalo. Asegúrate de que la extensión `vector` se creó correctamente y el servidor responde.

```bash
python -m unittest discover -s tests -v
python -m uvicorn app.api:app --host 0.0.0.0 --port 8000
```

La Toshiba (Core i5 3.ª generación, 8 GB RAM) puede ejecutar el backend en CPU, pero **FaceNet512+MTCNN puede consumir bastante RAM y tardar más**. Antes de transferir todo definitivamente, cronometra unas 5–10 verificaciones con el teléfono. El uso de TensorFlow en ese equipo debe comprobarse realmente. Si falla por memoria o librerías, conserva el backend en el equipo de escritorio.

## D. Conectar teléfono Android y red Wi-Fi

1. Ejecuta PostgreSQL + Uvicorn en la misma máquina donde corre el backend.
2. PC y Android deben estar en una red local que permita comunicación mutua.
3. Determina la IPv4: Windows `ipconfig`; Xubuntu `hostname -I` (elige la IP de Wi-Fi, no Docker/loopback).
4. En FitAccess escribe `http://IP_DEL_BACKEND:8000` y la clave del operador, no `127.0.0.1` ni `0.0.0.0`.
5. Primero prueba `http://IP_DEL_BACKEND:8000/health` desde el navegador del móvil.
6. Para el futuro ESP32, conéctalo a la **misma LAN de pruebas**. Requiere desarrollar todavía la API de eventos/firmware, no está incluido en esta versión.

## E. Seguridad y datos

- No subas `backend/.env`, dumps SQL, fotos de rostros ni JSON de embeddings a repositorios públicos o chats.
- El sistema usa HTTP en red local porque es **prototipo académico**. No publiques el puerto a Internet.
- Las verificaciones de gesto no son un sistema completo de anti-suplantación.
- En una migración entre Windows y Linux los datos reales de PostgreSQL requieren respaldo/restauración, no `Copy-Item` de la carpeta backend.
- Los siete socios anteriores no aparecen automáticamente si no recuperas el respaldo o galería original.

## F. Errores y comprobaciones rápidos

| Problema | Qué revisar |
| --- | --- |
| `Target of URI doesn't exist` | `flutter pub get`, ruta corta, SDK de Dart/Flutter correcto en VS Code |
| `flutter analyze FormatException Lsp...` | Reiniciar VS Code/servidor, ruta corta y `flutter analyze` otra vez. No es necesariamente error del código Dart |
| `.venv` apunta a Python viejo | El entorno se crea de cero en `backend/.venv`. Nunca copiar de Windows a Linux |
| `No Python at ...Python311` | Instalar Python 3.11 x64, abrir terminal nueva, crear entorno nuevo; **no** basta con cambiar de carpeta |
| Error `InputImageConverterError` | Verificar `isMinifyEnabled = false` y `isShrinkResources = false` en Android Kotlin Gradle |
| `HTTP 500`, `connection timeout :5432` | PostgreSQL apagado, IP DB, puerto o credenciales en `.env` |
| `REJECTED` en socio correcto | Control de calidad o umbral 0.260, comparar modelos y condiciones de captura |

## G. Qué no necesitas instalar aún

No necesitas emulador, cámara externa, Chrome ni Visual Studio C++ para la compilación de APK Android. Tampoco necesitas Docker. Para la demostración con ESP32 más adelante, sí compraremos y programaremos el microcontrolador, pero no es un requisito para restaurar esta versión.

## H. Recuperar la galería original de siete identidades

Si tienes los dos JSON exportados del notebook (`galeria_embeddings.json` y `config_reconocimiento.json`), cópialos localmente a `backend/modelo_exportado/`. **No van dentro del paquete de código**, porque contienen representaciones biométricas personales. Con consentimiento de los participantes, realiza la recuperación únicamente en una base nueva y vacía, tras ejecutar `database/schema.sql` y confirmar la configuración de PostgreSQL. Valida primero el archivo de configuración: 7 personas, 109 embeddings, 512 dimensiones, distancia coseno, umbral 0.260. El importador `backend/scripts/import_gallery.py` utiliza ese formato. Desde `backend` y con el entorno Python activo, ejecuta `python -m scripts.import_gallery`, después verifica las tablas (7 usuarios, 109 vectores). No conserva las asistencias anteriores, porque estas no están en la galería exportada.
