// Almacén en memoria que reemplaza al Google Sheets durante la etapa 1.
// Vive en el navegador y se guarda en localStorage para sobrevivir a una recarga.
// En la etapa 2 se reemplaza por Supabase; las pantallas no acceden a este módulo
// directamente sino a través de la API de datos (lib/data/api.ts, hitos 1.2 a 1.4).
import type { Db } from "../types";
import { crearSemilla } from "./semilla";

const CLAVE = "fieldstats-demo-db-v1";

let db: Db | null = null;

function cargar(): Db {
  try {
    const guardado = window.localStorage.getItem(CLAVE);
    if (guardado) return JSON.parse(guardado) as Db;
  } catch {
    // localStorage no disponible o datos corruptos: se usa la semilla.
  }
  return crearSemilla();
}

/** Devuelve la base en memoria (la carga en el primer uso). Solo en el navegador. */
export function obtenerDb(): Db {
  if (typeof window === "undefined") {
    throw new Error("El almacén de datos de la etapa 1 solo funciona en el navegador.");
  }
  if (!db) db = cargar();
  return db;
}

/** Persiste los cambios hechos sobre la base devuelta por obtenerDb(). */
export function guardarDb(): void {
  if (!db) return;
  try {
    window.localStorage.setItem(CLAVE, JSON.stringify(db));
  } catch {
    // Sin persistencia: los datos siguen en memoria hasta recargar.
  }
}

/** Vuelve a los datos de prueba originales. */
export function reiniciarDb(): void {
  db = crearSemilla();
  guardarDb();
}

/** Simula la latencia de google.script.run para que las pantallas manejen el estado de carga. */
export function demora<T>(valor: T, ms = 150): Promise<T> {
  return new Promise((resolve) => setTimeout(() => resolve(valor), ms));
}
