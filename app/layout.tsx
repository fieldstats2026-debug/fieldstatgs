import type { Metadata, Viewport } from "next";
import { ProveedorSesion } from "@/lib/sesion";
import "./globals.css";

export const metadata: Metadata = {
  title: "FieldStats MVP",
  description: "Plataforma de gestión deportiva",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="es">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        {/* Fondo dinámico animado - FieldStats Brand */}
        <div className="bg-orb bg-orb-1" />
        <div className="bg-orb bg-orb-2" />
        <div className="bg-orb bg-orb-3" />
        <ProveedorSesion>
          <div className="app-container">{children}</div>
        </ProveedorSesion>
      </body>
    </html>
  );
}
