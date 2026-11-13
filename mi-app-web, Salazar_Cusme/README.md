# BioRadar

Prototipo web adaptable a móviles para explorar observaciones de biodiversidad, crear misiones de monitoreo y visualizar alertas comunitarias.

## Iniciar la app

Desde esta carpeta:

```sh
npm install
npm run dev
```

Para generar la compilación de producción:

```sh
npm run build
```

## Funcionalidades del prototipo

- Mapa ilustrativo del campus con observaciones seleccionables, filtros por tipo de especie y búsqueda.
- Formulario para registrar una especie, indicar si necesita atención y crear una misión de seguimiento.
- Alertas de demostración para posibles especies invasoras, fauna en riesgo y avistamientos inusuales; la interfaz indica el radio comunitario de 2 km.
- Vistas de exploración, misiones, comunidad y perfil, con navegación adaptada a pantallas móviles.
- Solicitud opcional de ubicación del dispositivo, solo después de que la persona la active.

## Alcance

La app funciona como prototipo de interfaz: los reportes y alertas se mantienen en el estado local mientras la página está abierta. El mapa es ilustrativo; la identificación automática de especies, el almacenamiento persistente, el monitoreo en vivo y el envío real de alertas geolocalizadas requieren integrar servicios de mapas, una API y un backend de notificaciones.
