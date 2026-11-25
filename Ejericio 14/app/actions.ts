"use server";

export type Archetype =
  | "finance"
  | "productivity"
  | "travel"
  | "wellness"
  | "commerce"
  | "general";

export type GeneratedExperience = {
  title: string;
  category: string;
  description: string;
  archetype: Archetype;
  stats: { label: string; value: string; change: string }[];
  items: string[];
};

export async function generateExperience(
  prompt: string,
): Promise<GeneratedExperience> {
  const request = prompt.trim();

  if (request.length < 8) {
    throw new Error("Escribe una petición un poco más detallada para empezar.");
  }

  if (request.length > 500) {
    throw new Error("La petición debe tener menos de 500 caracteres.");
  }

  const normalized = request.toLocaleLowerCase("es");

  if (/finanz|presupuest|gasto|ahorr|invers|dinero|expense|budget/.test(normalized)) {
    return {
      title: "Tu dinero, más claro",
      category: "Panel financiero",
      description: "Una vista sencilla para entender tus hábitos y avanzar hacia tus objetivos.",
      archetype: "finance",
      stats: [
        { label: "Balance disponible", value: "$4,820", change: "+8.2%" },
        { label: "Gastos del mes", value: "$1,240", change: "−12.4%" },
        { label: "Meta de ahorro", value: "68%", change: "+6.0%" },
      ],
      items: ["Supermercado · $86.40", "Suscripción · $12.99", "Café de especialidad · $8.50"],
    };
  }

  if (/viaj|viaje|vacacion|escapad|playa|itiner|destino|trip|travel/.test(normalized)) {
    return {
      title: "Una escapada a tu medida",
      category: "Planificador de viaje",
      description: "Un itinerario ligero con lo esencial para disfrutar cada momento.",
      archetype: "travel",
      stats: [
        { label: "Días de aventura", value: "4 días", change: "18–21 jun" },
        { label: "Presupuesto", value: "$680", change: "Dentro del plan" },
        { label: "Lugares guardados", value: "12", change: "3 imperdibles" },
      ],
      items: ["09:00 · Desayuno en el mercado local", "11:30 · Recorrido por el centro histórico", "16:00 · Atardecer junto al mar"],
    };
  }

  if (/salud|bienestar|rutina|habito|hábito|ejercicio|fitness|agua|wellness/.test(normalized)) {
    return {
      title: "Pequeños pasos, gran energía",
      category: "Panel de bienestar",
      description: "Un espacio amable para cuidar tu ritmo y celebrar el progreso.",
      archetype: "wellness",
      stats: [
        { label: "Movimiento", value: "32 min", change: "Objetivo: 45 min" },
        { label: "Agua hoy", value: "1.6 L", change: "4 vasos más" },
        { label: "Racha actual", value: "6 días", change: "¡Vas genial!" },
      ],
      items: ["Paseo consciente · 15 min", "Pausa para estirar · 5 min", "Preparar una cena nutritiva"],
    };
  }

  if (/tienda|producto|catalog|compr|venta|shop|e-?commerce/.test(normalized)) {
    return {
      title: "Una tienda que se siente tuya",
      category: "Escaparate digital",
      description: "Descubre una selección cuidada, pensada para encontrar algo especial.",
      archetype: "commerce",
      stats: [
        { label: "Selección curada", value: "24", change: "Nuevas piezas" },
        { label: "Favoritos", value: "8", change: "Para después" },
        { label: "Envío", value: "Gratis", change: "Desde $50" },
      ],
      items: ["Lámpara de cerámica · $48", "Bolso tejido · $72", "Set de escritorio · $36"],
    };
  }

  return {
    title: "Un día con más intención",
    category: "Espacio de productividad",
    description: "Una vista enfocada que convierte tus ideas en próximos pasos alcanzables.",
    archetype: "productivity",
    stats: [
      { label: "Enfoque de hoy", value: "3 h 20", change: "+24 min" },
      { label: "Tareas listas", value: "8 de 12", change: "Buen ritmo" },
      { label: "Siguiente pausa", value: "14:30", change: "En 25 min" },
    ],
    items: ["Preparar la presentación del proyecto", "Responder mensajes importantes", "Reservar un momento para aprender"],
  };
}
