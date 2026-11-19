// Mapa de pantallas: cada <div class="screen" id="screen-..."> del index.html original
// pasa a ser una ruta de Next.js. `hito` indica en qué hito de la etapa 1 se porta.

export interface Pantalla {
  ruta: string;
  original: string; // id de la pantalla en index.html
  titulo: string;
  volver: string | null; // destino del botón "← Volver" del original
  hito: string;
}

export const PANTALLAS: Pantalla[] = [
  { ruta: "/", original: "screen-login", titulo: "Iniciar sesión", volver: null, hito: "1.2" },
  { ruta: "/registro/jugador", original: "screen-registro-jugador", titulo: "Activar cuenta de jugador", volver: "/", hito: "1.2" },
  { ruta: "/registro/externo", original: "screen-registro-externo", titulo: "Registro padres", volver: "/", hito: "1.2" },
  { ruta: "/confirmar", original: "doGet(?confirmar=)", titulo: "Confirmación de correo", volver: "/", hito: "1.2" },
  { ruta: "/admin", original: "screen-admin", titulo: "Panel de control", volver: "/", hito: "1.3" },
  { ruta: "/admin/alta-alumno", original: "screen-registro", titulo: "Alta de alumno", volver: "/admin", hito: "1.3" },
  { ruta: "/admin/asistencia", original: "screen-asistencia", titulo: "Asistencia", volver: "/admin", hito: "1.3" },
  { ruta: "/admin/partidos", original: "screen-partidos-menu", titulo: "Gestión de partidos", volver: "/admin", hito: "1.3" },
  { ruta: "/admin/partidos/nuevo", original: "screen-añadir-partido", titulo: "Nuevo partido", volver: "/admin/partidos", hito: "1.3" },
  { ruta: "/admin/convocatoria", original: "screen-convocar", titulo: "Convocatoria", volver: "/admin", hito: "1.3" },
  { ruta: "/admin/cargar-datos", original: "screen-cargar-datos", titulo: "Cargar resultado", volver: "/admin/partidos", hito: "1.3" },
  { ruta: "/admin/estadisticas", original: "screen-estadisticas-profe", titulo: "Estadísticas generales", volver: "/admin", hito: "1.4" },
  { ruta: "/jugador", original: "screen-jugador", titulo: "Panel del jugador", volver: "/", hito: "1.4" },
  { ruta: "/jugador/convocatorias", original: "screen-mis-convocatorias", titulo: "Mis convocatorias", volver: "/jugador", hito: "1.4" },
  { ruta: "/jugador/estadisticas", original: "screen-mis-estadisticas", titulo: "Mis estadísticas", volver: "/jugador", hito: "1.4" },
  { ruta: "/jugador/dashboard", original: "screen-dashboard-general-jugador", titulo: "Dashboard general", volver: "/jugador", hito: "1.4" },
  { ruta: "/externo", original: "screen-externo", titulo: "Dashboard público", volver: "/", hito: "1.4" },
];

export function pantalla(ruta: string): Pantalla {
  const p = PANTALLAS.find((x) => x.ruta === ruta);
  if (!p) throw new Error(`Pantalla no registrada: ${ruta}`);
  return p;
}
