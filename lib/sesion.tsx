"use client";
// Estado global de la app, equivalente a las variables globales de funcionees.html:
// rol y DNI del usuario logueado, deporte activo del panel del profesor y overlay de carga.
// Copia 1:1: la sesión vive en el navegador, sin autenticación real (etapa 2: Supabase Auth).
import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";
import type { DeporteId, Rol } from "./types";

interface Sesion {
  rol: Rol | null;
  dni: string; // dniJugadorActual del original
}

interface Contexto {
  sesion: Sesion;
  iniciarSesion: (rol: Rol, dni?: string) => void;
  cerrarSesion: () => void;
  deporteAdmin: DeporteId; // selector-deporte del panel del profesor
  setDeporteAdmin: (d: DeporteId) => void;
  cargando: boolean;
  setCargando: (v: boolean) => void;
}

const CLAVE = "fieldstats-sesion";
const SIN_SESION: Sesion = { rol: null, dni: "" };
const Ctx = createContext<Contexto | null>(null);

export function ProveedorSesion({ children }: { children: ReactNode }) {
  const [sesion, setSesion] = useState<Sesion>(SIN_SESION);
  const [deporteAdmin, setDeporteAdmin] = useState<DeporteId>("DEP1");
  const [cargando, setCargando] = useState(false);

  useEffect(() => {
    try {
      const guardada = window.sessionStorage.getItem(CLAVE);
      if (guardada) setSesion(JSON.parse(guardada) as Sesion);
    } catch {
      // sin sessionStorage: la sesión dura hasta recargar
    }
  }, []);

  const guardar = useCallback((s: Sesion) => {
    setSesion(s);
    try {
      window.sessionStorage.setItem(CLAVE, JSON.stringify(s));
    } catch {
      // ignorar
    }
  }, []);

  const iniciarSesion = useCallback((rol: Rol, dni = "") => guardar({ rol, dni }), [guardar]);
  const cerrarSesion = useCallback(() => guardar(SIN_SESION), [guardar]);

  return (
    <Ctx.Provider value={{ sesion, iniciarSesion, cerrarSesion, deporteAdmin, setDeporteAdmin, cargando, setCargando }}>
      {children}
      <div id="loading-overlay" style={{ display: cargando ? "flex" : "none" }}>
        Cargando...
      </div>
    </Ctx.Provider>
  );
}

export function useSesion(): Contexto {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useSesion debe usarse dentro de ProveedorSesion");
  return ctx;
}
