# FitAccess v4.1 — Guía de instalación, configuración y puesta en marcha en Windows

> **Proyecto académico:** Machine Learning II — Sistema de reconocimiento facial para control de asistencia de un gimnasio  
> **Metodología:** CRISP-DM — **Fase 6: Despliegue**  
> **Versión documentada:** FitAccess v4.1 (Flutter Android + FastAPI + PostgreSQL 16 + pgvector + MTCNN + FaceNet512)  
> **Entorno de referencia probado por el equipo:** Windows 11, Python 3.11 de 64 bits, PostgreSQL 16, Flutter 3.47.7, Android SDK 36 y un dispositivo Android real.  
> **Estado:** El prototipo fue verificado funcionando con el backend en una PC conectada por Ethernet al router y la aplicación móvil en un Huawei conectado por Wi-Fi a la misma red. Otros equipos deben realizar sus propias comprobaciones.

**Objetivo de esta guía.** Permitir que los integrantes del equipo recuperen el proyecto desde un ZIP limpio, conozcan su estructura, configuren su entorno de desarrollo, compilen la aplicación móvil y, cuando corresponda, instalen y ejecuten también el backend y la base de datos. Se documentan los errores reales encontrados durante la recuperación del proyecto.

**Antes de empezar:** no hace falta instalar PostgreSQL y FaceNet512 en **todas** las laptops para probar una app Android. Es suficiente que **una computadora funcione como servidor**, y que los demás dispositivos estén conectados a esa misma red y utilicen la IP del servidor. Para mostrar el código en VS Code, todos pueden conservar la carpeta completa `fitaccess/` en sus equipos. Quien necesite ejecutar todo de forma independiente puede seguir los apartados de instalación completa.

---

## Índice

1. [Qué construimos y cómo funciona](#1-qué-construimos-y-cómo-funciona)
2. [Modalidades de instalación](#2-modalidades-de-instalación)
3. [Preparar los archivos y herramientas](#3-preparar-los-archivos-y-herramientas)
4. [Configurar Flutter y compilar el APK Android](#4-configurar-flutter-y-compilar-el-apk-android)
5. [Instalar Python 3.11 y preparar el backend](#5-instalar-python-311-y-preparar-el-backend)
6. [Instalar y comprobar PostgreSQL 16](#6-instalar-y-comprobar-postgresql-16)
7. [Instalar pgvector en PostgreSQL de Windows](#7-instalar-pgvector-en-postgresql-de-windows)
8. [Crear la base `fitaccess` y sus tablas](#8-crear-la-base-fitaccess-y-sus-tablas)
9. [Configurar `.env` e importar las identidades originales](#9-configurar-env-e-importar-las-identidades-originales)
10. [Iniciar y comprobar FastAPI](#10-iniciar-y-comprobar-fastapi)
11. [Conectar la aplicación móvil por Wi-Fi](#11-conectar-la-aplicación-móvil-por-wi-fi)
12. [Pruebas funcionales y verificación final](#12-pruebas-funcionales-y-verificación-final)
13. [Errores frecuentes y soluciones](#13-errores-frecuentes-y-soluciones)
14. [Trabajo en equipo, respaldos y traslado a Xubuntu](#14-trabajo-en-equipo-respaldos-y-traslado-a-xubuntu)
15. [Fuentes y documentación técnica](#15-fuentes-y-documentación-técnica)

---

## 1. Qué construimos y cómo funciona

El proyecto utiliza una arquitectura **cliente-servidor**. El teléfono no ejecuta FaceNet512: **Flutter** controla la cámara y envía imágenes a **FastAPI**, que realiza la inferencia y consulta **PostgreSQL**.

```text
┌──────────────────────────┐
│ Android / FitAccess      │
│ Flutter + cámara + ML Kit│
└─────────────┬────────────┘
              │ HTTP en red local, cabecera X-API-Key
              │ Foto capturada / solicitudes REST
              ▼
┌──────────────────────────┐
│ FastAPI (Python 3.11)    │
│ MTCNN: detección facial  │
│ FaceNet512: embedding    │
│ Comparación coseno       │
└─────────────┬────────────┘
              │ SQL / pgvector
              ▼
┌──────────────────────────┐
│ PostgreSQL 16            │
│ usuarios                 │
│ face_embeddings          │
│ asistencias              │
└──────────────────────────┘
```

**Conceptos básicos:**

- **MTCNN:** modelo para detectar y localizar el rostro antes de extraer sus características.
- **FaceNet512:** variante de un modelo preentrenado que convierte el rostro en un **embedding** de **512 números**. No entrenamos esta red desde cero.
- **Embedding:** representación numérica del rostro. Se almacenan varios embeddings por usuario para cubrir diferentes fotografías y condiciones de captura.
- **pgvector:** extensión de PostgreSQL que permite guardar vectores, aquí como `VECTOR(512)`, y comparar su distancia.
- **Distancia coseno:** medida de diferencia entre embeddings; en nuestra regla, se acepta una coincidencia cuando su distancia mínima es **menor o igual a 0,260**.
- **ML Kit en Android:** ayuda a detectar y seguir el rostro para la captura automática y un desafío básico de gesto. **No es una prueba de vida antifraude certificada**.

**Resultados de acceso:** `ACCEPTED` (ingreso reconocido), `REJECTED` (no aceptado) y `DUPLICATE` (socio reconocido, pero ya registró un acceso en la ventana de **5 minutos**). La API registra la fecha y hora del evento.

**Cédula:** la tabla `usuarios` incluye `cedula VARCHAR(10) UNIQUE`. Las nuevas matrículas requieren una cédula de 10 dígitos que pase la validación ecuatoriana de módulo 10 del backend. Esa validación comprueba el formato y el dígito verificador; **no confirma la identidad real** ante una fuente oficial.

## 2. Modalidades de instalación

| Necesidad | Qué instalar | Qué se ejecuta |
|---|---|---|
| **A. Solo instalar la app en un Android** | Archivo APK | FitAccess en el teléfono; usa el backend de otro integrante |
| **B. Editar y compilar la app en una laptop Windows** | Código Flutter, Flutter SDK, Android SDK, VS Code | `flutter build apk --release`; no exige PostgreSQL local |
| **C. Servidor completo en una laptop/PC Windows** | Python 3.11, PostgreSQL 16, pgvector, dependencias del backend | Uvicorn/FastAPI, FaceNet512, PostgreSQL; todos los móviles pueden conectarse |
| **D. Solo estudiar el código en Xubuntu** | VS Code y archivos fuente | Visualización del frontend y backend; sin necesidad de emulador Android |

**Recomendación para el equipo:** mantengan **una sola base de datos de demostración y un solo backend encendido**; distribuyan el APK y el código a los compañeros. Las instalaciones individuales solo se requieren para quienes deban demostrar el entorno de desarrollo completo.

## 3. Preparar los archivos y herramientas

### 3.1. Obtener el paquete limpio correcto

Usar **FitAccess v4.1 portable**, no una copia de Google Drive con `.venv`, `build`, `.dart_tool`, cachés y otras dependencias del equipo anterior. El ZIP limpio debe contener:

```text
fitaccess/
├── app_movil/
│   ├── lib/
│   ├── assets/
│   ├── android_icons/
│   └── pubspec.yaml
├── backend/
│   ├── app/
│   ├── scripts/
│   ├── tests/
│   ├── modelo_exportado/
│   ├── .env.example
│   └── requirements.txt
├── database/
│   ├── schema.sql
│   └── migracion_cedula.sql
├── scripts/
│   └── preparar_android_windows.ps1
└── README.md
```

**No compartir:** `.env`, contraseñas, claves de operador, fotografías de participantes, `galeria_embeddings.json` ni respaldos con información biométrica en carpetas públicas. La galería original se distribuye solo de manera autorizada y privada.

### 3.2. Utilizar una ruta corta

Extraer el archivo ZIP en `C:\dev`, de modo que la estructura resultante sea:

```text
C:\dev\fitaccess\app_movil
C:\dev\fitaccess\backend
C:\dev\fitaccess\database
C:\dev\fitaccess\scripts
```

Evitar rutas muy largas dentro de carpetas sincronizadas (por ejemplo, directorios extensos de `Documents`, Google Drive o OneDrive). En la recuperación anterior esto complicó el análisis de Dart.

### 3.3. Instalar VS Code

Descargar e instalar desde <https://code.visualstudio.com/>. En VS Code: **Archivo > Abrir carpeta** y abrir `C:\dev\fitaccess`. Instalar las extensiones oficiales **Flutter** y **Dart** para el frontend, y **Python** para el backend. VS Code es el editor; no reemplaza los SDK de Flutter, Android y Python.

### 3.4. Requisitos de instalación completa en Windows

- Windows de 64 bits, conexión a Internet y espacio libre suficiente para Flutter/Android SDK, Python, PostgreSQL y pesos de los modelos.
- **Python 3.11 x64**; en el entorno que funcionó se usó Python 3.11, no Python 3.13.
- **PostgreSQL 16** ejecutándose como servicio y la extensión **pgvector**.
- **Flutter 3.47.7** y **Android SDK 36** en la máquina de referencia. Para reproducir la configuración conviene mantener versiones compatibles, no actualizar todos los paquetes sin probar.
- Para compilar **pgvector nativamente en Windows**: Git y **Visual Studio 2022** con la carga de trabajo **Desarrollo para el escritorio con C++**, compilador MSVC x64 y Windows SDK. **MSVC v142 de Visual Studio 2019 no es obligatorio**.
- Un teléfono **Android físico** con cámara. No usamos AVD para las pruebas del prototipo. Un iPhone no puede instalar un APK Android.

> **Importante:** Para **solo compilar el APK** no hace falta PostgreSQL, Python ni Visual Studio C++. Para **solo ejecutar FastAPI** no hace falta Flutter ni Android Studio.

---

## 4. Configurar Flutter y compilar el APK Android

### 4.1. Instalar Flutter y el Android SDK

1. Instalar Flutter usando la extensión Flutter de VS Code o la guía oficial: <https://docs.flutter.dev/install/with-vs-code>.
2. Instalar Android Studio o al menos el **Android SDK** con las herramientas de compilación necesarias. Android Studio facilita administrarlas, **pero no es obligatorio crear un emulador**.
3. Abrir una nueva terminal **PowerShell** y ejecutar:

```powershell
flutter --version
flutter doctor -v
```

El entorno de referencia informó **Flutter 3.47.7** y **Android SDK 36.0.0**. Si `flutter` no se reconoce, configurar el SDK en el `PATH` y reiniciar la terminal. En la paleta de comandos de VS Code (`Ctrl + Shift + P`) se puede utilizar **Flutter: Change SDK** para señalar la carpeta correcta.

Para revisar las licencias Android:

```powershell
flutter doctor --android-licenses
```

Dependiendo de la versión del SDK, puede indicarse que `--licenses` ya no es necesario; eso no es un error. **Los avisos de Chrome o de Visual Studio C++ para desarrollo de escritorio no impiden compilar un APK Android.**

### 4.2. Preparar la plataforma Android del proyecto portable

Abrir **PowerShell normal**, no hace falta ejecutar como administrador:

```powershell
cd C:\dev\fitaccess
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\preparar_android_windows.ps1
```

El script `preparar_android_windows.ps1`:

1. Ejecuta `flutter create . --platforms=android --project-name gimnasio_facial` **si falta** la estructura `android/`.
2. Activa permisos Android para **INTERNET** y **CAMERA**.
3. Permite `usesCleartextTraffic="true"` para el **HTTP local de demostración**. **No usar esa configuración en producción pública**.
4. Ajusta `minSdk = 24`.
5. Desactiva `isMinifyEnabled` e `isShrinkResources` en `release` para evitar el fallo de ML Kit que sufrimos (`InputImageConverterError` tras optimización R8).
6. Ajusta Gradle y copia los íconos de FitAccess.
7. Puede eliminar el test automático de plantilla `test/widget_test.dart` si todavía utiliza la clase inexistente `MyApp`.

**No ejecutar `flutter create .` manualmente una y otra vez sobre un proyecto ya configurado**. Si se parte del ZIP portable, usar el script anterior una sola vez y volver a utilizarlo solo para comprobar/aplicar sus ajustes.

### 4.3. Restaurar dependencias y analizar código

```powershell
cd C:\dev\fitaccess\app_movil
flutter pub get
flutter analyze
```

En la prueba anterior aparecieron **cinco incidencias**: cuatro avisos de estilo (`info`) y un error del test de plantilla (`MyApp`). Si el script no eliminó ese test y ese es el único error, ejecutar:

```powershell
Remove-Item .\test\widget_test.dart
flutter analyze
```

Los mensajes `13 packages have newer versions incompatible with dependency constraints` son **avisos**, no indican que las dependencias hayan fallado: `Got dependencies!` es la comprobación de instalación correcta. **No ejecutar `flutter pub upgrade --major-versions` por iniciativa propia**: debemos conservar la combinación de librerías que ya funcionó.

### 4.4. Generar el archivo APK

Desde `C:\dev\fitaccess\app_movil`:

```powershell
flutter build apk --release
```

Ruta de salida:

```text
C:\dev\fitaccess\app_movil\build\app\outputs\flutter-apk\app-release.apk
```

El APK puede enviarse al Android por USB, almacenamiento compartido o mensajería; luego abrirlo e instalarlo en el teléfono. Es posible que Android pida **autorizar la instalación desde esa fuente**; autorizar únicamente el APK generado por el equipo. **No requiere AVD ni cámara externa del PC.**

Si Android rechaza una actualización porque el APK anterior se firmó con otra clave, puede ser necesario desinstalar primero la versión instalada. Esto borra los ajustes **locales de esa instalación**, pero no elimina los usuarios o asistencias almacenados en PostgreSQL. La versión portátil utiliza una configuración de firma de demostración: no distribuirla como producto final de producción.

### 4.5. Funcionamiento de las cámaras en FitAccess v4.1

- **Reconocimiento automático:** intenta usar **cámara frontal** primero y muestra un control para cambiar a la **trasera**.
- **Matriculación:** inicia con **cámara trasera** y también ofrece cambiar de cámara.
- Si la frontal no puede inicializarse, el código intenta utilizar la trasera. **En teléfonos con la cámara frontal averiada físicamente no se garantiza que Android permita recuperar el proceso si el controlador provoca el cierre de la app.** En ese caso hay que configurar el inicio directamente en trasera antes de abrir el escáner.
- La cámara y el procesamiento local de ML Kit dependen del hardware; comprobar orientación, enfoque y reconocimiento de gestos en el teléfono real.

---

## 5. Instalar Python 3.11 y preparar el backend

### 5.1. Instalar Python 3.11 x64

Abrir PowerShell y ejecutar:

```powershell
winget install --id Python.Python.3.11 --exact --source winget
```

Alternativa manual: <https://www.python.org/downloads/release/python-3119/> (Python 3.11.9 con instalador x64 tradicional). Las versiones posteriores 3.11.x orientadas a mantenimiento de seguridad no necesariamente incluyen instaladores tradicionales para Windows; **la versión de mantenimiento mostrada por `py -3.11 --version` puede variar**.

Cerrar y abrir nuevamente PowerShell. Comprobar:

```powershell
py -3.11 --version
```

Si devuelve `No suitable Python runtime found`, Python 3.11 no está instalado o el lanzador no lo detecta. No continuar con el entorno hasta resolverlo.

### 5.2. Crear el entorno virtual en la carpeta correcta

```powershell
cd C:\dev\fitaccess\backend
py -3.11 -m venv .venv
```

**¿Qué es `.venv`?** Un entorno aislado con las librerías de este backend, que evita conflictos con otros proyectos Python. **No copiar la carpeta `.venv` entre computadoras:** puede contener rutas absolutas al Python original.

Para instalar dependencias sin problemas de permisos de scripts:

```powershell
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m pip check
```

Resultado correcto de la última comprobación:

```text
No broken requirements found.
```

Las dependencias del archivo `requirements.txt` incluyen `fastapi`, `uvicorn`, `psycopg`, `pgvector`, `opencv-python`, `deepface==0.0.101`, `tensorflow==2.17.0`, `tf-keras==2.17.0` y otras bibliotecas. La instalación puede descargar archivos pesados. **El paquete Python `pgvector` no sustituye la extensión `pgvector` del servidor PostgreSQL**, que instalaremos aparte.

**Corrección de un error que experimentamos:** ejecutar `Rename-Item .venv .venv_respaldo` desde `app_movil` falla porque el entorno pertenece a `backend/.venv`. En una nueva instalación limpia simplemente se crea el entorno desde cero.

---

## 6. Instalar y comprobar PostgreSQL 16

Descargar PostgreSQL 16 para Windows desde <https://www.postgresql.org/download/windows/>. Durante la instalación conservar la contraseña del usuario administrador `postgres` en un gestor seguro; recordar el puerto predeterminado **5432**. No es necesario abrir ese puerto hacia teléfonos o Internet.

Si ya está instalado, **no reinstalarlo**. Desde PowerShell:

```powershell
Get-Service *postgres* -ErrorAction SilentlyContinue
```

Resultado esperado de la experiencia real:

```text
Running  postgresql-x64-16
```

Si el servicio aparece detenido, desde una terminal **elevada** (administrador), cuando su nombre sea exactamente `postgresql-x64-16`:

```powershell
Start-Service postgresql-x64-16
```

Definir la ruta de utilidades PostgreSQL en **cada nueva sesión de PowerShell** donde se necesite:

```powershell
$pg = "C:\Program Files\PostgreSQL\16\bin"
Test-Path "$pg\psql.exe"
Test-NetConnection 127.0.0.1 -Port 5432
```

Si `TcpTestSucceeded` es `True`, el puerto responde. Comprobar credenciales:

```powershell
& "$pg\psql.exe" -U postgres -h 127.0.0.1 -p 5432 -d postgres -c "SELECT version();"
```

**No compartir la contraseña de PostgreSQL con los demás integrantes ni exponer el servicio de base de datos a una LAN abierta.** Los móviles solo hablan con FastAPI por el puerto 8000.

---

## 7. Instalar pgvector en PostgreSQL de Windows

> Si la extensión ya está instalada en el servidor, **omitir la compilación** y pasar al capítulo 8. La instalación nativa de pgvector se realizó una vez en la PC de referencia; no se necesita Docker.

### 7.1. Comprobar si ya existe

```powershell
$pg = "C:\Program Files\PostgreSQL\16\bin"
& "$pg\psql.exe" -U postgres -h 127.0.0.1 -d postgres -c "SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'vector';"
```

- Si aparece **una fila `vector`**, PostgreSQL conoce la extensión; no es necesario recompilarla. `installed_version` vacío solo indica que no está habilitada **en esa base específica**.
- Si aparece **`(0 rows)`**, instalar los archivos de pgvector como se indica abajo.

### 7.2. Preparar compilador C++ y Git

1. Instalar **Visual Studio Community 2022** o Build Tools equivalente.
2. En **Visual Studio Installer > Modificar**, marcar la carga de trabajo **Desarrollo para el escritorio con C++** y asegurarse de incluir compilador MSVC de x64 y **Windows SDK**. Se pueden conservar las herramientas CMake. **No es necesario instalar MSVC v142** exclusivamente para esto; utilizamos las herramientas de Visual Studio 2022.
3. Instalar **Git for Windows**: <https://git-scm.com/downloads/win>, o:

```powershell
winget install --id Git.Git --exact
```

4. En el menú Inicio buscar y abrir **como administrador**: `x64 Native Tools Command Prompt for VS 2022`.

**IMPORTANTE: los comandos de compilación siguientes se escriben en ese CMD especial, NO en PowerShell.**

### 7.3. Confirmar que la herramienta x64 funciona

```cmd
cl
nmake /?
git --version
```

En el equipo de referencia funcionaron `cl` (MSVC 19.44 x64) y `nmake` (14.44). El mensaje de `cl` mostrando su sintaxis sin archivos para compilar es normal.

### 7.4. Descargar, compilar e instalar pgvector 0.8.6

En **x64 Native Tools Command Prompt**, como administrador:

```cmd
set "PGROOT=C:\Program Files\PostgreSQL\16"
cd /d "%TEMP%"
git clone --branch v0.8.6 --depth 1 https://github.com/pgvector/pgvector.git pgvector-fitaccess
cd pgvector-fitaccess
nmake /F Makefile.win
nmake /F Makefile.win install
```

Solo ejecutar `install` si `nmake /F Makefile.win` termina correctamente. Se utiliza el **tag 0.8.6** de la instalación del proyecto, aunque pueden existir versiones más recientes; no cambiar versiones a mitad de una demostración ya probada.

Si la carpeta `%TEMP%\pgvector-fitaccess` ya existe por otro intento, **no ejecutar `git clone` encima**; entrar a esa carpeta si contiene el repositorio correcto o utilizar otra carpeta temporal.

Regresar a **PowerShell** y repetir la consulta de `pg_available_extensions` del apartado 7.1. Debe aparecer `vector`.

**Errores frecuentes de compilación:**

| Mensaje | Posible causa / acción |
|---|---|
| `nmake` no se reconoce | No estás en `x64 Native Tools Command Prompt` o falta la carga C++ |
| `Cannot open include file 'postgres.h'` | `PGROOT` incorrecto o faltan archivos de desarrollo de PostgreSQL |
| `Access is denied` en `nmake install` | Abrir el CMD x64 como administrador |
| Error de arquitectura 32 bits | Usar `x64 Native Tools...`, no x86 |
| `git` no se reconoce | Instalar Git y abrir una consola nueva |

Fuentes de instalación oficial: <https://github.com/pgvector/pgvector#installation>.

---

## 8. Crear la base `fitaccess` y sus tablas

### 8.1. No sobrescribir bases existentes

Desde PowerShell:

```powershell
$pg = "C:\Program Files\PostgreSQL\16\bin"
& "$pg\psql.exe" -U postgres -h 127.0.0.1 -d postgres -c "SELECT datname FROM pg_database WHERE datname = 'fitaccess';"
```

Si **no existe**, crearla:

```powershell
& "$pg\createdb.exe" -U postgres -h 127.0.0.1 -p 5432 fitaccess
```

Si existe, **no eliminarla ni ejecutar restauraciones destructivas**; primero revisar qué contiene. Las bases de los compañeros pueden tener datos diferentes.

### 8.2. Aplicar el esquema actualizado

Solo para una base nueva o cuya estructura haya sido revisada:

```powershell
& "$pg\psql.exe" -U postgres -h 127.0.0.1 -p 5432 -d fitaccess -v ON_ERROR_STOP=1 -f "C:\dev\fitaccess\database\schema.sql"
```

El archivo instala/habilita `vector` en la base `fitaccess` y crea las tablas:

| Tabla | Campos relevantes |
|---|---|
| `usuarios` | `id`, `codigo` único, `nombre`, `cedula` única, `activo`, `creado_en` |
| `face_embeddings` | `id`, `usuario_id`, `origen`, `embedding VECTOR(512)`, `creado_en` |
| `asistencias` | `id`, `usuario_id`, `estado`, `distancia`, `motivo`, `fecha_hora` |

El campo `cedula` acepta temporalmente `NULL` para las personas importadas del antiguo notebook. En las nuevas matrículas la API exige cédula válida. **`migracion_cedula.sql` es para bases anteriores, no para la base nueva que se crea con `schema.sql`.**

### 8.3. Verificar la base

```powershell
& "$pg\psql.exe" -U postgres -h 127.0.0.1 -d fitaccess -c "\dt"
& "$pg\psql.exe" -U postgres -h 127.0.0.1 -d fitaccess -c "SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';"
& "$pg\psql.exe" -U postgres -h 127.0.0.1 -d fitaccess -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'usuarios' ORDER BY ordinal_position;"
```

Deberían existir `usuarios`, `face_embeddings` y `asistencias`, además de la extensión `vector` y la columna `cedula`.

---

## 9. Configurar `.env` e importar las identidades originales

### 9.1. Crear el archivo local de configuración

```powershell
cd C:\dev\fitaccess\backend
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
notepad .env
```

Contenido de referencia (reemplazar los valores de ejemplo; **no copiarlos literalmente**):

```dotenv
DATABASE_URL=postgresql://postgres:TU_CONTRASENA@127.0.0.1:5432/fitaccess
ADMIN_API_KEY=TU_CLAVE_ALEATORIA_SEGURA
MODEL_CONFIG_PATH=modelo_exportado/config_reconocimiento.json
WINDOW_DUPLICATE_MINUTES=5
MAX_IMAGE_MB=8
```

- `DATABASE_URL`: conexión **del servidor FastAPI a PostgreSQL local**, no dirección para la app Android.
- `ADMIN_API_KEY`: clave privada de operador; Flutter la envía a FastAPI en la cabecera `X-API-Key`. No es la contraseña del usuario `postgres`.
- `MODEL_CONFIG_PATH`: ubicación local de la configuración original del notebook.
- `WINDOW_DUPLICATE_MINUTES`: ventana de cinco minutos.
- `MAX_IMAGE_MB`: tamaño máximo aceptado de la fotografía.

Para generar una clave aleatoria desde `backend`:

```powershell
.\.venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(32))"
```

Copiar su salida a `ADMIN_API_KEY`. **No enviar claves por capturas o repositorios públicos.** Si la contraseña de PostgreSQL contiene `@`, `#`, `/`, `:` u otros símbolos especiales, se debe **codificar correctamente en una URL**; no pegarla sin escapar.

**Atención:** si una terminal tiene definida una variable de entorno `DATABASE_URL` de pruebas, puede tener precedencia sobre `.env`. Para una sesión donde no se quiere forzar esa variable: `Remove-Item Env:DATABASE_URL -ErrorAction SilentlyContinue`. No ejecutarlo si se utiliza deliberadamente otro servidor.

### 9.2. Recuperar los datos del notebook (opcional y restringido)

La exportación original que recuperamos consta de:

- `config_reconocimiento.json`: FaceNet512, MTCNN, distancia coseno, umbral **0,260**, `embedding_dim=512`, estrategia `todos_min`.
- `galeria_embeddings.json`: **7 personas** y **109 embeddings** exportados de Jupyter.

**Estos dos JSON contienen información biométrica o metadatos de identidad. **

Ubicar ambos archivos en (YA ESTAN UBICADOS YA LOS PUSE XD):

```text
C:\dev\fitaccess\backend\modelo_exportado\config_reconocimiento.json
C:\dev\fitaccess\backend\modelo_exportado\galeria_embeddings.json
```

**Importante:** el paquete limpio tiene una configuración reconstruida para demostrar la estructura. Si se cuenta con el archivo **original** exportado desde Jupyter, reemplazarla por ese archivo antes de recuperar la galería. No se pueden reconstruir identidades reales solo a partir de la configuración.

Antes de importar, comprobar que la base está vacía:

```powershell
$pg = "C:\Program Files\PostgreSQL\16\bin"
& "$pg\psql.exe" -U postgres -h 127.0.0.1 -d fitaccess -c "SELECT COUNT(*) AS usuarios FROM usuarios; SELECT COUNT(*) AS embeddings FROM face_embeddings;"
```

Si los conteos son cero y ya se creó el esquema:

```powershell
cd C:\dev\fitaccess\backend
.\.venv\Scripts\python.exe -m scripts.import_gallery
```

Salida esperada en la primera importación correcta:

```text
Importación terminada: 109 registros leídos; 109 nuevos embeddings.
```

El importador valida que cada vector tenga 512 componentes y norma L2 aproximada a 1. Al reejecutarlo, evita duplicar el mismo origen de foto; **aun así no debe ejecutarse sobre bases con matrículas nuevas sin analizar posibles coincidencias**.

### 9.3. Confirmar la recuperación

```powershell
& "$pg\psql.exe" -U postgres -h 127.0.0.1 -d fitaccess -c "SELECT COUNT(*) AS usuarios FROM usuarios; SELECT COUNT(*) AS embeddings FROM face_embeddings;"
```

Resultado de referencia: **7 usuarios y 109 embeddings**. **El historial antiguo de asistencias no está contenido en esos JSON**: para recuperarlo se necesita un respaldo real de PostgreSQL.

### 9.4. Si no se dispone de los JSON originales

Se puede continuar con la **base vacía**, crear usuarios con el formulario de Flutter y **matricularlos desde la cámara**. No se debe inventar una galería o copiar los datos biométricos de los compañeros sin consentimiento. FaceNet512 se utiliza preentrenado: la matrícula agrega nuevos embeddings a PostgreSQL, no reentrena el modelo.

---

## 10. Iniciar y comprobar FastAPI

Desde una terminal nueva de **PowerShell**:

```powershell
cd C:\dev\fitaccess\backend
.\.venv\Scripts\python.exe -m uvicorn app.api:app --host 0.0.0.0 --port 8000
```

**Dejar esta terminal abierta.** La API dejará de atender solicitudes si se cierra o si se presiona `Ctrl + C`.

El arranque correcto suele mostrar:

```text
INFO: Application startup complete.
INFO: Uvicorn running on http://0.0.0.0:8000
```

**Diferencia importante:** `0.0.0.0` significa *escuchar en las interfaces de red*, **no** es una URL válida para escribir en el navegador. En el mismo PC abrir:

- Estado: <http://127.0.0.1:8000/health>
- Documentación Swagger: <http://127.0.0.1:8000/docs>

`/health` devuelve un JSON con `db: "ok"` cuando la conexión a PostgreSQL funciona, además del modelo, detector y umbral. Que `/docs` cargue no significa necesariamente que PostgreSQL esté disponible: hay que comprobar `/health` y probar una solicitud autenticada.

Rutas principales documentadas en `backend/app/api.py`:

| Endpoint | Función | Requiere `X-API-Key` |
|---|---|---|
| `GET /health` | Estado general y conexión a PostgreSQL | No |
| `GET /usuarios` | Listado de socios | Sí |
| `POST /usuarios` | Crear socio (nombre, código, cédula) | Sí |
| `PATCH /usuarios/{usuario_id}/cedula` | Completar cédula faltante de un socio importado | Sí |
| `POST /usuarios/{usuario_id}/matricular` | Guardar entre 3 y 10 fotografías de matrícula | Sí |
| `POST /accesos/verificar` | Reconocer y registrar una entrada | Sí |
| `GET /asistencias` | Consultar eventos recientes | Sí |

**Para comprobar API y BD juntas sin usar el teléfono**, ejecutar desde otra terminal PowerShell **en `backend`**, sin imprimir la clave por pantalla:

```powershell
.\.venv\Scripts\python.exe -c "from app.settings import ADMIN_API_KEY; import urllib.request; req=urllib.request.Request('http://127.0.0.1:8000/usuarios', headers={'X-API-Key': ADMIN_API_KEY}); print('HTTP:', urllib.request.urlopen(req, timeout=30).status)"
```

Resultado esperado: `HTTP: 200`. El listado será vacío si no se ha importado/matriculado nadie.

---

## 11. Conectar la aplicación móvil por Wi-Fi

### 11.1. Red correcta

El teléfono Android puede conectarse al router por **Wi-Fi** mientras la PC servidor lo hace por **Ethernet**. Funciona siempre que ambos puedan comunicarse dentro de la misma LAN y no exista aislamiento entre clientes.

Ejemplo de la prueba real del proyecto:

```text
Router / puerta de enlace: 192.168.100.1
PC servidor (Ethernet):   192.168.100.21
Huawei (Wi-Fi):           dirección del mismo segmento
Puerto FastAPI:           8000
```

En **el Huawei se escribió por error `http://192.168.100.1:8000`**, que señalaba al router y provocó `Connection refused`. Al cambiar a **`http://192.168.100.21:8000`** se conectó correctamente y el equipo confirmó que la aplicación funcionaba. **Estas IP son solo un ejemplo histórico, no las direcciones de los demás compañeros.**

### 11.2. Encontrar la IP actual del servidor

En **la PC donde corre FastAPI**, abrir **otra** terminal PowerShell y ejecutar:

```powershell
ipconfig
```

Localizar la **Dirección IPv4** del adaptador conectado al router (Ethernet o Wi-Fi). **No copiar la Puerta de enlace predeterminada**: esa IP pertenece al router. Tampoco utilizar `127.0.0.1`, `localhost`, `0.0.0.0` o adaptadores virtuales de Docker/VM si no son el camino de red real.

### 11.3. Probar primero desde el navegador del Android

En el teléfono, abrir:

```text
http://IP_DEL_SERVIDOR:8000/health
```

Sustituir `IP_DEL_SERVIDOR` por la IPv4 real. Si responde con JSON y `db: "ok"`, la conexión básica funciona.

### 11.4. Configurar el acceso en FitAccess

Abrir la aplicación Android. En la pantalla **Conexión a red local** ingresar:

```text
Dirección de FastAPI: http://IP_DEL_SERVIDOR:8000
Clave de operador:    el valor de ADMIN_API_KEY del backend
```

Pulsar **Ingresar al sistema**. La aplicación consulta `GET /usuarios` y, si la clave y conexión son correctas, permite entrar a la interfaz principal. No escribir en este campo `DATABASE_URL`: **PostgreSQL no se conecta directamente al teléfono**.

### 11.5. Abrir el firewall solo cuando sea necesario

Si `/health` funciona en el PC, pero **no** desde el teléfono, primero revisar IP, red y si el router aísla clientes Wi-Fi. Si se confirma que el firewall bloquea el puerto, abrir **PowerShell como administrador**:

```powershell
Get-NetConnectionProfile
```

Comprobar que la red de pruebas es **de confianza y privada**. En redes públicas o institucionales, no abrir el servicio indiscriminadamente. Para una red privada confiable:

```powershell
New-NetFirewallRule -DisplayName "FitAccess API LAN Privada TCP 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Private -RemoteAddress LocalSubnet
```

Esta regla limita la conexión a equipos de la subred local en el perfil privado; **no desactiva todo Windows Defender Firewall**. Antes de ejecutarla más de una vez, comprobar si ya existe:

```powershell
Get-NetFirewallRule -DisplayName "FitAccess API LAN Privada TCP 8000" -ErrorAction SilentlyContinue
```

Si la red tiene categoría `Public`, **no cambiarla a `Private` sin confirmar que sea realmente tu red confiable**. No se debe abrir el puerto 8000 a Internet ni exponer PostgreSQL en 5432.

---

## 12. Pruebas funcionales y verificación final

Checklist sugerido para cada equipo:

- [ ] `flutter --version` y `flutter doctor` muestran Android toolchain disponible, si se compilará el APK.
- [ ] `flutter pub get` funciona y `flutter analyze` no tiene errores de compilación.
- [ ] Se genera e instala `app-release.apk` en Android.
- [ ] Python 3.11 y `pip check` funcionan en el backend, si se instalará servidor local.
- [ ] El servicio PostgreSQL 16 está `Running`.
- [ ] `pg_available_extensions` muestra `vector`.
- [ ] Existe la base `fitaccess` con `usuarios`, `face_embeddings` y `asistencias`.
- [ ] `usuarios` contiene la columna `cedula`.
- [ ] `/health` indica `db: "ok"`.
- [ ] El Android puede abrir `/health` usando la IPv4 de la PC.
- [ ] El inicio de la aplicación con `ADMIN_API_KEY` recupera la lista de usuarios.
- [ ] La matriculación crea un usuario nuevo con cédula válida y guarda sus fotografías/embeddings.
- [ ] Una persona matriculada recibe `ACCEPTED` cuando su rostro es reconocido.
- [ ] Una persona no registrada puede recibir `REJECTED` de acuerdo con el umbral.
- [ ] Un segundo acceso consecutivo dentro de cinco minutos genera `DUPLICATE`.
- [ ] Se registra y consulta el historial de asistencias con fecha y hora.

**Prueba recomendada de cámara:** en v4.1 el reconocimiento automático inicia con la frontal y permite cambiar a la trasera; probar ambas cuando estén disponibles. El desafío de gesto es básico y no garantiza seguridad contra fotos o pantallas.

---

## 13. Errores frecuentes y soluciones

| Error/síntoma observado | Significado y solución |
|---|---|
| `Target of URI doesn't exist: package:flutter/material.dart` o `camera.dart` | Las dependencias de Flutter/SDK no se están resolviendo: `flutter --version`, `flutter pub get`, revisar SDK en VS Code y usar una ruta corta |
| Cerca de 1.000 problemas en VS Code | A menudo son **errores en cascada** por el SDK Flutter faltante, no mil fallos distintos de la aplicación |
| `FormatException: Unexpected end of input` en `flutter analyze` / `LspByteStreamServerChannel` | Fallo del servidor de análisis Dart (mensaje incompleto), no necesariamente error del código. Reiniciar VS Code/servidor de análisis, usar ruta corta, repetir `flutter pub get` y `flutter analyze` |
| `The name 'MyApp' isn't a class` en `test/widget_test.dart` | Test generado por `flutter create` para una plantilla distinta. Eliminar **solo ese test de plantilla**, no `lib/main.dart` |
| `13 packages have newer versions...` | Aviso informativo. Si termina con `Got dependencies!`, no actualizar masivamente |
| `No suitable Python runtime found` | Instalar Python 3.11 x64, reabrir terminal, comprobar `py -3.11 --version` |
| `No Python at C:\...\Python311\python.exe` | `.venv` copiado de otro equipo y dañado: crear **uno nuevo dentro de `backend`** |
| `Rename-Item .venv ...` no encuentra la carpeta | Se está ejecutando desde `app_movil`; el entorno Python es `backend/.venv` |
| `ModuleNotFoundError` al iniciar Uvicorn | Instalar dependencias con **el Python del entorno** y ejecutar desde la carpeta `backend` |
| `pg_available_extensions` devuelve `(0 rows)` para `vector` | La extensión no está instalada en el servidor PostgreSQL; seguir capítulo 7 |
| `CREATE EXTENSION vector` falla | Revisar compilación, PostgreSQL 16 y `PGROOT`; no seguir creando tablas si la extensión falla |
| `psycopg.errors.ConnectionTimeout` a `localhost:5432` | PostgreSQL detenido, puerto incorrecto, bloqueo local o `DATABASE_URL` equivocada |
| `HTTP 500` en `/usuarios` | Revisar inmediatamente el **traceback de Uvicorn** y el estado de PostgreSQL/schema; no asumir que es fallo del APK |
| `/docs` abre pero `/usuarios` falla | `/docs` no verifica por sí mismo conexión a BD; usar `/health`, revisar clave y logs |
| `ClientException ... Connection refused` a `192.168.100.1:8000` | En la prueba real se utilizó **IP del router**, no del PC. Usar IPv4 del servidor (`ipconfig`) |
| El PC responde en `127.0.0.1` pero el Android no | Revisar `--host 0.0.0.0`, IP correcta, perfil del firewall y aislamiento Wi-Fi |
| `HTTP 401` | `ADMIN_API_KEY` introducida en la app no coincide con la del backend |
| `HTTP 409`: cédula o código registrado | Se intenta duplicar un dato único; revisar matrícula, **no desactivar la restricción** |
| `HTTP 422`: cédula inválida | Comprobar formato de 10 dígitos, provincia, tercer dígito y módulo 10 |
| `InputImageConverterError` de ML Kit tras compilar APK release | Comprobar `isMinifyEnabled = false`, `isShrinkResources = false` y plataforma Android del paquete |
| La cámara frontal averiada cierra la app | Si Android falla incluso en cámara nativa, puede fallar antes del cambio de cámara. Adaptar la app para seleccionar trasera **antes** de inicializar frontal |
| `404 /favicon.ico` en Uvicorn | Normal; el navegador busca un ícono que la API no publica |
| El usuario aparece como `REJECTED` | Revisar calidad de la toma, detección, iluminación y umbral 0,260. No bajar el umbral sin reevaluar científicamente |

---

## 14. Trabajo en equipo, respaldos y traslado a Xubuntu

### 14.1. Qué enviamos a los compañeros

Enviar por Drive privado o repositorio con permisos adecuados:

1. El **ZIP limpio de FitAccess v4.1**, con `app_movil`, `backend`, `database`, `scripts` y `README.md`.
2. **Este archivo Markdown** en la raíz: `GUIA_INSTALACION_FITACCESS_V4_1_WINDOWS.md`.
3. El **APK** previamente generado, si un compañero solo quiere instalar la app en Android.
4. La **dirección IP y clave de un backend de demostración** únicamente por un canal privado y controlado, si se va a compartir el servidor entre compañeros. Rotar esa clave cuando termine la demostración.

No enviar `.venv`, `node_modules` (no aplicable aquí), `build/`, `.dart_tool/`, carpetas temporales, credenciales ni datos biométricos dentro del ZIP general.

### 14.2. Si una sola laptop actúa como servidor

La laptop o PC servidor debe permanecer **encendida**, con PostgreSQL `Running` y Uvicorn abierto. Los teléfonos Android usan `http://IP_DEL_SERVIDOR:8000`. Si la IP cambia al moverse de red, actualizarla en FitAccess. Es posible dejar todo el código fuente en las otras laptops sin ejecutar su backend.

### 14.3. Realizar un respaldo de PostgreSQL

Después de matricular usuarios y registrar asistencias, conviene producir un respaldo privado de la base. En PowerShell, en el servidor:

```powershell
$pg = "C:\Program Files\PostgreSQL\16\bin"
& "$pg\pg_dump.exe" -U postgres -h 127.0.0.1 -p 5432 -d fitaccess -F c -f "C:\dev\fitaccess_respaldo.dump"
```

Este respaldo contiene **usuarios, embeddings y asistencias**; debe custodiarse con controles de acceso. No subirlo a un repositorio público. Para restaurarlo en otro sistema hay que crear una base de destino compatible, disponer de pgvector y **planificar la restauración para evitar duplicados o sobrescritura**. Se recomienda ensayar primero en una base de pruebas y usar `pg_restore` de la versión compatible de PostgreSQL. **No copiar los directorios internos de datos de PostgreSQL desde Windows a Linux.**

### 14.4. Preparación para Toshiba con Xubuntu

La laptop Toshiba puede conservar la carpeta **completa** para enseñar el código Flutter y backend al docente, aunque **solo ejecute** PostgreSQL, FastAPI, MTCNN y FaceNet512. No se necesitan Android Studio, AVD, Visual Studio Community, `cl` ni `nmake` allí.

**Diferencias principales de Linux** (la instalación detallada se hará y validará por separado):

- PostgreSQL y pgvector se instalan con paquetes compatibles de Linux (APT/PGDG o compilación GCC si hace falta), **no** con herramientas de Visual Studio.
- El entorno virtual se crea en Linux con `python3.11 -m venv .venv` y se activa con `source .venv/bin/activate`; no se copia el `.venv` de Windows.
- El backend se inicia con `python -m uvicorn app.api:app --host 0.0.0.0 --port 8000` desde `backend`.
- El teléfono usa la IPv4 real del equipo Xubuntu (`ip -4 addr` o `hostname -I` con selección del adaptador correcto).
- En CPU Intel Core i5 de tercera generación y **8 GB RAM**, TensorFlow/FaceNet512 puede ser lento. Verificar compatibilidad de instrucciones del procesador y RAM; no dar por hecho que alcanzará tiempo real sin pruebas.
- Si se desea mover **todos** los datos ya generados en Windows, utilizar **`pg_dump` y `pg_restore`** con PostgreSQL/pgvector compatibles; si se desea solamente la galería original, se puede importar el par de JSON autorizado en una base nueva vacía.
- El ESP32 y los LED rojo/verde **todavía son una integración pendiente**: el firmware y el endpoint/eventos para comunicar el resultado físico no forman parte de la versión v4.1 documentada aquí.

### 14.5. Criterios de privacidad y seguridad

Los embeddings faciales son **datos biométricos sensibles**. Conservarlos únicamente con autorización de los participantes, limitar su distribución y eliminarlos cuando ya no sean necesarios para el proyecto. El prototipo usa **HTTP dentro de una LAN de pruebas** y una clave compartida de operador; **no es un sistema de producción expuesto a Internet**. Evitar registrar o transmitir claves en capturas de pantalla. No desactivar el firewall para facilitar una demostración.

---

## 15. Fuentes y documentación técnica

**Documentación del proyecto (fuente directa de los comandos específicos):**

- `scripts/preparar_android_windows.ps1` — configuración Android, manifest, Gradle e íconos.
- `app_movil/pubspec.yaml` — dependencias Flutter.
- `app_movil/lib/auto_recognition_screen.dart` y `camera_screen.dart` — selección de cámaras.
- `backend/requirements.txt` — dependencias Python.
- `backend/app/api.py`, `settings.py`, `db.py` — endpoints, configuración y PostgreSQL.
- `backend/scripts/import_gallery.py` — importación controlada de la galería.
- `database/schema.sql` — esquema actualizado de usuarios, embeddings y asistencias.
- `config_reconocimiento.json` **original exportado del notebook** — parámetros del modelo, umbral, estrategia y conteos.

**Documentación externa verificada:**

- Flutter. *Install and set up Flutter*. <https://docs.flutter.dev/install>
- Flutter. *Install Flutter with VS Code*. <https://docs.flutter.dev/install/with-vs-code>
- pgvector. *Repositorio oficial y procedimiento de instalación*. <https://github.com/pgvector/pgvector>
- PostgreSQL Global Development Group. *Windows downloads*. <https://www.postgresql.org/download/windows/>
- Python Software Foundation. *Python 3.11.9 (instalador Windows x64)*. <https://www.python.org/downloads/release/python-3119/>

---

**Fin de la guía — FitAccess v4.1.**  
**Siguiente etapa del proyecto:** reproducir y validar el backend en la Toshiba con Xubuntu; después desarrollar la integración de respuesta visual por ESP32.  
**Estado CRISP-DM:** Fase 6 — Despliegue, validación en dispositivo físico y documentación técnica.
