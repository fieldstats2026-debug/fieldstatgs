// Modelo de datos de FieldStats 5.3 (fútbol/handball), portado 1:1 desde las hojas del Google Sheets.
// Cada interfaz corresponde a una hoja. Los "Si"/"No" de la planilla pasan a booleanos,
// salvo la confirmación de convocatoria, que tiene tres estados ('' = sin responder).

export type Rol = "jugador" | "externo" | "profesor";
export type DeporteId = "DEP1" | "DEP2";
export type Categoria = "Menores" | "Cadetes" | "Juveniles";
export type EstadoPartido = "Pendiente" | "Finalizado";
export type Confirmacion = "" | "Si" | "No";

export const DEPORTES: Record<DeporteId, string> = {
  DEP1: "Fútbol",
  DEP2: "Handball",
};

export const CATEGORIAS: Categoria[] = ["Menores", "Cadetes", "Juveniles"];

/** Hoja USUARIOS. `id` es el DNI (jugadores) o el email (externos). */
export interface Usuario {
  id: string;
  passwordHash: string; // '' mientras el jugador no activó su cuenta
  rol: Rol;
  confirmado: boolean;
  activado: boolean;
  email: string;
}

/** Hoja JUGADORES_GENERAL. */
export interface JugadorGeneral {
  dni: string;
  nombre: string;
  apellido: string;
  email: string;
  fnac: string; // YYYY-MM-DD
  colegio: string;
}

/** Hoja JUGADORES_DEPORTES. `idj` = `${dni}-${deporte}`. */
export interface JugadorDeporte {
  idj: string;
  dni: string;
  deporte: DeporteId;
  categoria: Categoria;
  camiseta: string;
}

/** Hoja Asistencia. Una fila por jugador, deporte y día. */
export interface RegistroAsistencia {
  fecha: string; // YYYY-MM-DD
  deporte: DeporteId;
  dni: string;
  nombre: string;
  asistio: boolean;
}

/** Hoja PARTIDOS. `idp` = `PAR-${deporte}-${categoria}-${AAAAMMDD}`. */
export interface Partido {
  idp: string;
  local: string;
  visitante: string;
  deporte: DeporteId;
  categoria: Categoria;
  fecha: string; // YYYY-MM-DD
  hora: string; // HH:MM
  golesLocal: number;
  golesVisitante: number;
  estado: EstadoPartido;
}

/** Hoja CONVOCATORIAS. */
export interface Convocatoria {
  idp: string;
  dni: string;
  convocado: boolean;
  titular: boolean;
  confirmado: Confirmacion;
}

/** Hoja ESTADISTICAS_PARTIDOS. Una fila por gol de Goethe. */
export interface EstadisticaGol {
  idp: string;
  idGoleador: string;
  idAsistidor: string; // '' si no hubo asistencia
}

/** Hoja EQUIPOS. Existe en la planilla pero el código original no la usa. */
export interface Equipo {
  id: string;
  nombre: string;
}

export interface Db {
  usuarios: Usuario[];
  jugadoresGeneral: JugadorGeneral[];
  jugadoresDeportes: JugadorDeporte[];
  asistencia: RegistroAsistencia[];
  partidos: Partido[];
  convocatorias: Convocatoria[];
  estadisticasPartidos: EstadisticaGol[];
  equipos: Equipo[];
}
