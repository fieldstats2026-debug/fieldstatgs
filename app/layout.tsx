
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "FieldStats",
  description: "Plataforma de gestión deportiva"
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}
