// Datos de prueba FICTICIOS para la etapa 1. No contienen datos reales de alumnos.
// Contraseñas de prueba (hash SHA-256 con la sal del original):
//   profesor@demo.com / profe123     padre@demo.com / padre123
//   jugadores activados (DNI 90000001 a 90000005) / jugador123
//   DNI 90000006: jugador sin activar (token JUGADOR2026)
import type { Db } from "../types";

const HASH_PROFE = "f17506421fbfabd36500f2b4f6ae23ee2ba82b8475e0563e878e81b26667b051";
const HASH_JUGADOR = "19641b21af171ae9c0dbab6fcd02aa43fb5739d5a0ea229098e4a3c2fb07a36a";
const HASH_PADRE = "c3b7733f6e5c687dbe64e66be4c150c7b298dd1ae496b85655a9d1328df7eca4";

const jugador = (dni: string, email: string, activado = true) => ({
  id: dni,
  passwordHash: activado ? HASH_JUGADOR : "",
  rol: "jugador" as const,
  confirmado: true,
  activado,
  email,
});

export function crearSemilla(): Db {
  return {
    usuarios: [
      { id: "profesor@demo.com", passwordHash: HASH_PROFE, rol: "profesor", confirmado: true, activado: true, email: "profesor@demo.com" },
      { id: "padre@demo.com", passwordHash: HASH_PADRE, rol: "externo", confirmado: true, activado: true, email: "padre@demo.com" },
      jugador("90000001", "juan@demo.com"),
      jugador("90000002", "martin@demo.com"),
      jugador("90000003", "hernan@demo.com"),
      jugador("90000004", "ignacio@demo.com"),
      jugador("90000005", "bautista@demo.com"),
      jugador("90000006", "lautaro@demo.com", false),
    ],
    jugadoresGeneral: [
      { dni: "90000001", nombre: "Juan", apellido: "Pérez", email: "juan@demo.com", fnac: "2011-03-10", colegio: "Goethe" },
      { dni: "90000002", nombre: "Martín", apellido: "González", email: "martin@demo.com", fnac: "2012-08-21", colegio: "Goethe" },
      { dni: "90000003", nombre: "Hernán", apellido: "Rodríguez", email: "hernan@demo.com", fnac: "2011-05-02", colegio: "Goethe" },
      { dni: "90000004", nombre: "Ignacio", apellido: "Fagiani", email: "ignacio@demo.com", fnac: "2013-02-14", colegio: "Goethe" },
      { dni: "90000005", nombre: "Bautista", apellido: "Álvarez", email: "bautista@demo.com", fnac: "2009-11-30", colegio: "Goethe" },
      { dni: "90000006", nombre: "Lautaro", apellido: "Díaz", email: "lautaro@demo.com", fnac: "2011-01-20", colegio: "Goethe" },
    ],
    jugadoresDeportes: [
      { idj: "90000001-DEP1", dni: "90000001", deporte: "DEP1", categoria: "Cadetes", camiseta: "10" },
      { idj: "90000001-DEP2", dni: "90000001", deporte: "DEP2", categoria: "Cadetes", camiseta: "7" },
      { idj: "90000002-DEP1", dni: "90000002", deporte: "DEP1", categoria: "Cadetes", camiseta: "9" },
      { idj: "90000003-DEP1", dni: "90000003", deporte: "DEP1", categoria: "Cadetes", camiseta: "5" },
      { idj: "90000004-DEP1", dni: "90000004", deporte: "DEP1", categoria: "Menores", camiseta: "3" },
      { idj: "90000005-DEP1", dni: "90000005", deporte: "DEP1", categoria: "Juveniles", camiseta: "8" },
      { idj: "90000005-DEP2", dni: "90000005", deporte: "DEP2", categoria: "Juveniles", camiseta: "11" },
      { idj: "90000006-DEP1", dni: "90000006", deporte: "DEP1", categoria: "Cadetes", camiseta: "11" },
    ],
    asistencia: [
      { fecha: "2026-11-10", deporte: "DEP1", dni: "90000001", nombre: "Juan Pérez", asistio: true },
      { fecha: "2026-11-10", deporte: "DEP1", dni: "90000002", nombre: "Martín González", asistio: true },
      { fecha: "2026-11-10", deporte: "DEP1", dni: "90000003", nombre: "Hernán Rodríguez", asistio: false },
      { fecha: "2026-11-10", deporte: "DEP1", dni: "90000004", nombre: "Ignacio Fagiani", asistio: true },
      { fecha: "2026-11-10", deporte: "DEP1", dni: "90000005", nombre: "Bautista Álvarez", asistio: true },
    ],
    partidos: [
      { idp: "PAR-DEP1-Cadetes-20261003", local: "Goethe", visitante: "Colegio Norte", deporte: "DEP1", categoria: "Cadetes", fecha: "2026-10-03", hora: "15:00", golesLocal: 2, golesVisitante: 1, estado: "Finalizado" },
      { idp: "PAR-DEP1-Cadetes-20261017", local: "Goethe", visitante: "Colegio Sur", deporte: "DEP1", categoria: "Cadetes", fecha: "2026-10-17", hora: "15:00", golesLocal: 0, golesVisitante: 0, estado: "Finalizado" },
      { idp: "PAR-DEP1-Cadetes-20261205", local: "Goethe", visitante: "Colegio Norte", deporte: "DEP1", categoria: "Cadetes", fecha: "2026-12-05", hora: "10:00", golesLocal: 0, golesVisitante: 0, estado: "Pendiente" },
      { idp: "PAR-DEP1-Menores-20261205", local: "Goethe", visitante: "Colegio Norte", deporte: "DEP1", categoria: "Menores", fecha: "2026-12-05", hora: "11:30", golesLocal: 0, golesVisitante: 0, estado: "Pendiente" },
      { idp: "PAR-DEP2-Cadetes-20261212", local: "Goethe", visitante: "Colegio Sur", deporte: "DEP2", categoria: "Cadetes", fecha: "2026-12-12", hora: "09:00", golesLocal: 0, golesVisitante: 0, estado: "Pendiente" },
    ],
    convocatorias: [
      { idp: "PAR-DEP1-Cadetes-20261003", dni: "90000001", convocado: true, titular: true, confirmado: "Si" },
      { idp: "PAR-DEP1-Cadetes-20261003", dni: "90000002", convocado: true, titular: true, confirmado: "Si" },
      { idp: "PAR-DEP1-Cadetes-20261003", dni: "90000003", convocado: true, titular: false, confirmado: "Si" },
      { idp: "PAR-DEP1-Cadetes-20261017", dni: "90000001", convocado: true, titular: true, confirmado: "Si" },
      { idp: "PAR-DEP1-Cadetes-20261017", dni: "90000002", convocado: true, titular: false, confirmado: "Si" },
      { idp: "PAR-DEP1-Cadetes-20261017", dni: "90000003", convocado: false, titular: false, confirmado: "No" },
      { idp: "PAR-DEP1-Cadetes-20261205", dni: "90000001", convocado: true, titular: true, confirmado: "" },
      { idp: "PAR-DEP1-Cadetes-20261205", dni: "90000002", convocado: true, titular: true, confirmado: "Si" },
      { idp: "PAR-DEP1-Cadetes-20261205", dni: "90000003", convocado: true, titular: false, confirmado: "" },
    ],
    estadisticasPartidos: [
      { idp: "PAR-DEP1-Cadetes-20261003", idGoleador: "90000001", idAsistidor: "90000002" },
      { idp: "PAR-DEP1-Cadetes-20261003", idGoleador: "90000002", idAsistidor: "" },
    ],
    equipos: [
      { id: "1", nombre: "Goethe" },
      { id: "2", nombre: "Colegio Norte" },
    ],
  };
}
