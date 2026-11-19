"use client";
// Pantalla de desarrollo (no existía en el original): mapa de pantallas migradas
// y estado de los datos de prueba de la etapa 1.
import Link from "next/link";
import { useEffect, useState } from "react";
import { PANTALLAS } from "@/lib/pantallas";
import { obtenerDb, reiniciarDb } from "@/lib/data/almacen";
import type { Db } from "@/lib/types";

const HOJAS: [keyof Db, string][] = [
  ["usuarios", "USUARIOS"],
  ["jugadoresGeneral", "JUGADORES_GENERAL"],
  ["jugadoresDeportes", "JUGADORES_DEPORTES"],
  ["asistencia", "Asistencia"],
  ["partidos", "PARTIDOS"],
  ["convocatorias", "CONVOCATORIAS"],
  ["estadisticasPartidos", "ESTADISTICAS_PARTIDOS"],
  ["equipos", "EQUIPOS"],
];

export default function Dev() {
  const [conteos, setConteos] = useState<Record<string, number> | null>(null);

  const contar = () => {
    const db = obtenerDb();
    setConteos(Object.fromEntries(HOJAS.map(([k]) => [k, db[k].length])));
  };

  useEffect(contar, []);

  return (
    <div className="screen active">
      <div className="nav-bar">
        <span>Mapa de migración</span>
        <Link className="nav-btn" href="/">
          Inicio
        </Link>
      </div>

      <h2>Pantallas</h2>
      <p className="subtitle">Etapa 1: copia 1:1 de FieldStats 5.3 con datos de prueba.</p>
      {PANTALLAS.map((p) => (
        <Link key={p.ruta} href={p.ruta} className="player-row" style={{ color: "inherit", textDecoration: "none" }}>
          <span>{p.titulo}</span>
          <span style={{ fontSize: 12, color: "var(--text-muted)" }}>
            {p.ruta} · hito {p.hito}
          </span>
        </Link>
      ))}

      <h2 style={{ marginTop: 32 }}>Datos de prueba</h2>
      <p className="subtitle" style={{ marginBottom: 16 }}>
        Se guardan en este navegador. Son ficticios.
      </p>
      {conteos &&
        HOJAS.map(([k, hoja]) => (
          <div key={k} className="player-row">
            <span>{hoja}</span>
            <span>{conteos[k]} filas</span>
          </div>
        ))}
      <button
        className="btn btn-outline"
        style={{ marginTop: 20 }}
        onClick={() => {
          reiniciarDb();
          contar();
        }}
      >
        Restaurar datos de prueba
      </button>
    </div>
  );
}
