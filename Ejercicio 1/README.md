# TipCalculator Express

Calculadora de propinas en español, adaptable a teléfonos y computadoras. No requiere instalar paquetes ni herramientas de desarrollo: funciona en un navegador moderno y actualiza los resultados al cambiar cualquier entrada.

## Ejecutar

Abre `index.html` en el navegador. Si el navegador bloquea recursos al abrir archivos locales, inicia un servidor estático desde esta carpeta:

```powershell
py -m http.server 8000
```

Después visita `http://localhost:8000`.

## Funcionalidades

- Monto de cuenta con entrada decimal; admite punto o coma.
- Porcentajes rápidos de propina del 10 %, 15 % y 20 %.
- Número de personas con control para sumar o restar.
- Cálculo reactivo de la propina, el total y el importe por persona.
- Validación de montos y del número de personas para evitar divisiones inválidas.
- Conversión entre USD, EUR, MXN, COP, CAD, GBP y JPY con tasas fijas demostrativas; el campo de entrada y los resultados usan la moneda seleccionada.
- Diseño adaptable y etiquetas accesibles para lectores de pantalla.

Las tasas incluidas en `app.js` son valores de demostración editables, no cotizaciones
actuales. Al cambiar la moneda, el campo de entrada cambia su código y símbolo. El
monto se convierte internamente a USD para calcular la propina, y los resultados
se convierten de vuelta a la moneda seleccionada. Cambiar la moneda también
convierte el valor del campo para conservar el mismo valor económico de la cuenta.

## Abrir la aplicación desde un teléfono

1. Conecta el teléfono a la misma red local que la computadora.
2. En Windows, abre PowerShell en la carpeta del proyecto y ejecuta:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\start-mobile-server.ps1
   ```

3. Usa en el teléfono la dirección que el script imprime, por ejemplo
   `http://192.168.1.31:8000`.
4. Si Windows Firewall pregunta, permite el acceso en redes privadas. Mantén
   abierta la ventana de PowerShell mientras uses la aplicación y pulsa `Ctrl+C`
   para detener el servidor.

El servidor solo entrega los archivos estáticos necesarios de la aplicación y
está pensado para uso temporal en una red privada de confianza.

## Estructura

- `index.html`: interfaz y campos de entrada.
- `styles.css`: presentación adaptable.
- `app.js`: estado local, validaciones y lógica de cálculo.
- `assets/icon.svg`: icono de la aplicación.
- `start-mobile-server.ps1`: servidor local temporal para probarla desde el teléfono.
