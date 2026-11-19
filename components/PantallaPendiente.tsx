"use client";
// Marcador temporal para las pantallas que se portan en los hitos 1.2 a 1.4.
import Link from "next/link";
import { pantalla } from "@/lib/pantallas";

export default function PantallaPendiente({ ruta }: { ruta: string }) {
  const p = pantalla(ruta);
  return (
    <div className="screen active">
      <div className="nav-bar">
        {p.volver !== null ? (
          <Link className="nav-btn" href={p.volver}>
            ← Volver
          </Link>
        ) : (
          <span>FieldStats</span>
        )}
        <Link className="nav-btn" href="/dev">
          Mapa
        </Link>
      </div>
      <h2>{p.titulo}</h2>
      <p className="subtitle">
        Pantalla en migración: se porta en el hito {p.hito}.
        <br />
        Origen: <code>{p.original}</code>
      </p>
    </div>
  );
}
