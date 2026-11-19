# Migración de FieldStats 5.3 (Apps Script) a Next.js

## Etapa 1: copia 1:1, sin base de datos

La versión de fútbol y handball se porta tal como está, con la misma lógica y las mismas fallas de seguridad conocidas (se corrigen en una etapa posterior). No queda en uso real: los datos son de prueba y viven en el navegador.

| Hito | Contenido | Estado |
|---|---|---|
| 1.1 | Estilos, rutas, sesión, capa de datos en memoria, semilla | Hecho |
| 1.2 | Login, activación de jugador, registro y confirmación de padres | Pendiente |
| 1.3 | Panel del profesor: alta de alumno, asistencia, partidos, convocatoria, carga de goles | Pendiente |
| 1.4 | Jugador: convocatorias, estadísticas; fixture, tabla y ranking | Pendiente |
| 1.5 | Build, chequeo de tipos, despliegue en Vercel | Pendiente |

## Estructura

| Archivo | Rol | Origen |
|---|---|---|
| `app/globals.css` | Estilos | `estilos.html`, sin cambios |
| `app/layout.tsx` | Fondo, contenedor, overlay de carga | cabecera de `index.html` |
| `app/**/page.tsx` | Una ruta por pantalla (mapa en `lib/pantallas.ts`) | cada `screen-*` de `index.html` |
| `lib/types.ts` | Una interfaz por hoja de la planilla | Google Sheets |
| `lib/formato.ts` | Fecha, hora, hash de contraseña, categoría | `Code.gs` |
| `lib/sesion.tsx` | Rol, DNI, deporte activo, estado de carga | variables globales de `funcionees.html` |
| `lib/data/almacen.ts` | Base en memoria, persistida en `localStorage` | reemplaza `SpreadsheetApp` |
| `lib/data/semilla.ts` | Datos de prueba ficticios | — |

`/dev` muestra el mapa de pantallas, la cantidad de filas por hoja y un botón para restaurar los datos de prueba.

## Usuarios de prueba

| Usuario | Contraseña | Rol |
|---|---|---|
| `profesor@demo.com` | `profe123` | profesor |
| `padre@demo.com` | `padre123` | externo |
| DNI `90000001` a `90000005` | `jugador123` | jugador |
| DNI `90000006` | se activa con token `JUGADOR2026` | jugador sin activar |

El login del original también acepta `hernan` / `profe123` como profesor; se mantiene en la copia 1:1.

## Etapa 2

La capa de datos se reemplaza por Supabase con el esquema de gimnasia (`Supabase.sql` + `fieldstats_patch_v0_2.sql`), y la sesión por Supabase Auth.
