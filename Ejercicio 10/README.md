# Login XML

Aplicación Android nativa de ejemplo que presenta un formulario de inicio de sesión
con `ConstraintLayout`, `ImageView`, `TextView`, `EditText` y `Button`.

## Abrir y ejecutar

1. Abre esta carpeta en Android Studio.
2. Espera a que Gradle sincronice el proyecto.
3. Ejecuta la configuración `app` en un emulador o dispositivo Android.

También se puede compilar desde la raíz con `gradle assembleDebug` si Gradle y
Android SDK están instalados.

## Validación

El botón comprueba que el correo tenga formato válido y que la contraseña no esté
vacía. Los errores aparecen junto a sus campos. El mensaje de éxito solo confirma
que el formulario es válido: esta aplicación no valida credenciales ni se conecta
a un servicio de autenticación.

## Estructura principal

- `app/src/main/res/layout/activity_main.xml`: diseño de la pantalla.
- `app/src/main/java/com/example/loginxml/MainActivity.java`: eventos y validación.
- `app/src/main/res/values/`: textos, colores y tema de la aplicación.
