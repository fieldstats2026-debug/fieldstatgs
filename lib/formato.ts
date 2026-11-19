// Utilidades portadas 1:1 desde Code.gs.
import type { Categoria } from "./types";

/** YYYY-MM-DD (o Date) -> DD/MM/AAAA, como formatearFecha() del original. */
export function formatearFecha(fecha: string | Date | null | undefined): string {
  if (!fecha) return "";
  if (fecha instanceof Date) {
    const dia = String(fecha.getDate()).padStart(2, "0");
    const mes = String(fecha.getMonth() + 1).padStart(2, "0");
    return `${dia}/${mes}/${fecha.getFullYear()}`;
  }
  const iso = /^(\d{4})-(\d{2})-(\d{2})$/.exec(fecha);
  return iso ? `${iso[3]}/${iso[2]}/${iso[1]}` : fecha;
}

/** HH:MM, como formatearHora() del original. */
export function formatearHora(hora: string | Date | null | undefined): string {
  if (!hora) return "";
  if (hora instanceof Date) {
    return `${String(hora.getHours()).padStart(2, "0")}:${String(hora.getMinutes()).padStart(2, "0")}`;
  }
  return hora;
}

/** Fecha local de hoy en YYYY-MM-DD. */
export function hoyIso(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

// Copia 1:1 del original: SHA-256 con sal fija. Se reemplaza por Supabase Auth en la etapa 2.
const SALT = "GoetheFieldStats_2026_MVP!";

export async function hashPassword(password: string): Promise<string> {
  const datos = new TextEncoder().encode(password + SALT);
  const digest = await crypto.subtle.digest("SHA-256", datos);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Categoría por fecha de nacimiento, igual que calcularCategoria() del original
 * (incluido su comportamiento: el ajuste por corte de julio del comentario original no
 * modifica el año escolar; solo cambia los límites entre categorías).
 */
export function calcularCategoria(fnac: string | Date | null | undefined): Categoria {
  if (!fnac) return "Cadetes";
  const fecha = fnac instanceof Date ? fnac : new Date(`${fnac}T00:00:00`);
  if (isNaN(fecha.getTime())) return "Cadetes";

  const mesNac = fecha.getMonth() + 1;
  const anioNac = fecha.getFullYear();
  const anioEscolar = new Date().getFullYear() - anioNac - 11;
  const esGrande = mesNac >= 7;

  if (anioEscolar < 1) return "Menores";
  if (anioEscolar > 6) return "Juveniles";

  if (esGrande) {
    if (anioEscolar <= 2) return "Menores";
    if (anioEscolar <= 4) return "Cadetes";
    return "Juveniles";
  }
  if (anioEscolar <= 3) return "Menores";
  if (anioEscolar <= 5) return "Cadetes";
  return "Juveniles";
}
