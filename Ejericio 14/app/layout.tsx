import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Forma — Generative UI Studio",
  description: "Convierte una idea en una interfaz útil y personal, en segundos.",
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
