"use client";

import { useState, useTransition, type FormEvent } from "react";
import {
  generateExperience,
  type GeneratedExperience,
} from "@/app/actions";

const examples = [
  { icon: "↗", label: "Finanzas personales", prompt: "Crea un panel para organizar mis finanzas personales y ahorrar para un viaje" },
  { icon: "✳", label: "Rutina de bienestar", prompt: "Diseña una rutina de bienestar para cuidar mis hábitos y hacer ejercicio" },
  { icon: "⌁", label: "Planear un viaje", prompt: "Ayúdame a planear un viaje de cuatro días a la playa" },
  { icon: "▤", label: "Organizar mi semana", prompt: "Ayúdame a organizar mi semana con tareas y bloques de enfoque" },
];

function Sparkle({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M12 2.8 14.3 9.7 21.2 12l-6.9 2.3-2.3 6.9-2.3-6.9L2.8 12l6.9-2.3L12 2.8Z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
      <path d="m19 2 .8 2.2L22 5l-2.2.8L19 8l-.8-2.2L16 5l2.2-.8L19 2Z" fill="currentColor" />
    </svg>
  );
}

function ArrowIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M5 12h14m-6-6 6 6-6 6" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" /></svg>;
}

function DownloadIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M12 3v12m0 0 4-4m-4 4-4-4M5 17v3h14v-3" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" /></svg>;
}

export default function GenerativeStudio() {
  const [prompt, setPrompt] = useState("");
  const [experience, setExperience] = useState<GeneratedExperience | null>(null);
  const [error, setError] = useState("");
  const [completedItems, setCompletedItems] = useState<number[]>([]);
  const [view, setView] = useState<"desktop" | "mobile">("desktop");
  const [isPending, startTransition] = useTransition();

  function submitPrompt(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");

    startTransition(async () => {
      try {
        const result = await generateExperience(prompt);
        setExperience(result);
        setCompletedItems([]);
      } catch (caught) {
        setError(caught instanceof Error ? caught.message : "No se pudo generar la interfaz. Inténtalo otra vez.");
      }
    });
  }

  function setExample(examplePrompt: string) {
    setPrompt(examplePrompt);
    setError("");
  }

  function downloadExperience() {
    if (!experience) return;
    const file = new Blob([JSON.stringify(experience, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(file);
    const link = document.createElement("a");
    link.href = url;
    link.download = "mi-interfaz-forma.json";
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }

  return (
    <main className="app-shell">
      <aside className="sidebar">
        <a className="brand" href="#" aria-label="Forma inicio">
          <span className="brand-mark"><Sparkle size={19} /></span>
          <span>forma<span className="brand-period">.</span></span>
        </a>

        <div className="workspace-label">WORKSPACE</div>
        <button className="workspace-switcher">
          <span className="workspace-avatar">S</span>
          <span className="workspace-name">Mi espacio</span>
          <span className="chevron">⌄</span>
        </button>

        <div className="nav-section-label">CREAR</div>
        <button className="nav-item active"><span className="nav-icon">✳</span> Generador <span className="nav-count">⌘ K</span></button>
        <button className="nav-item" onClick={() => document.getElementById("prompt-box")?.focus()}><span className="nav-icon">◷</span> Historial</button>

        <div className="nav-section-label templates-label">EXPLORAR</div>
        <button className="nav-item" onClick={() => setExample(examples[0].prompt)}><span className="nav-icon">▦</span> Plantillas</button>
        <button className="nav-item" onClick={() => setView(view === "desktop" ? "mobile" : "desktop")}><span className="nav-icon">◇</span> Componentes</button>

        <div className="sidebar-bottom">
          <div className="upgrade-card">
            <div className="upgrade-orb"><Sparkle size={15} /></div>
            <strong>Las ideas toman forma.</strong>
            <p>Explora nuevas posibilidades, una interfaz a la vez.</p>
            <button onClick={() => setExample(examples[3].prompt)}>Probar una idea <ArrowIcon /></button>
          </div>
          <button className="profile-button">
            <span className="profile-avatar">M</span>
            <span><strong>María Fernanda</strong><small>Plan gratuito</small></span>
            <span className="profile-menu">···</span>
          </button>
        </div>
      </aside>

      <section className="main-area">
        <header className="topbar">
          <div className="breadcrumb"><span>Mi espacio</span><span className="breadcrumb-slash">/</span><strong>Generador</strong></div>
          <div className="topbar-right">
            <span className="engine-status"><span className="status-dot" /> Motor local</span>
            <button className="help-button" aria-label="Ayuda">?</button>
          </div>
        </header>

        <div className="studio-content">
          <section className="welcome">
            <div className="eyebrow"><span className="eyebrow-line" /> TU LIENZO, EN BLANCO</div>
            <h1>¿Qué te gustaría<br /><span>hacer realidad?</span></h1>
            <p className="welcome-copy">Cuéntame tu idea. Le daré forma a una experiencia hecha para ti.</p>
          </section>

          <form className="prompt-card" onSubmit={submitPrompt}>
            <label htmlFor="prompt-box" className="sr-only">Describe la interfaz que quieres crear</label>
            <textarea
              id="prompt-box"
              maxLength={500}
              placeholder="Por ejemplo: crea un panel para organizar mis finanzas y ahorrar para un viaje..."
              value={prompt}
              onChange={(event) => setPrompt(event.target.value)}
            />
            <div className="prompt-footer">
              <span className="prompt-hint"><span className="sparkle-small"><Sparkle size={13} /></span> Sé tan específico como quieras</span>
              <div className="prompt-actions">
                <span className="character-count">{prompt.length}/500</span>
                <button className="generate-button" type="submit" disabled={isPending || prompt.trim().length < 8}>
                  {isPending ? <span className="spinner" /> : <Sparkle size={15} />}
                  {isPending ? "Creando..." : "Generar interfaz"}
                  {!isPending && <ArrowIcon />}
                </button>
              </div>
            </div>
            {error && <p className="form-error" role="alert">{error}</p>}
          </form>

          <div className="suggestions">
            <span className="suggestions-label">PARA INSPIRARTE</span>
            <div className="suggestion-list">
              {examples.map((example) => (
                <button className="suggestion-chip" key={example.label} onClick={() => setExample(example.prompt)}>
                  <span>{example.icon}</span>{example.label}
                </button>
              ))}
            </div>
          </div>

          <section className={`preview-section${experience ? " has-experience" : ""}`}>
            <div className="preview-toolbar">
              <div className="preview-heading">
                <span className="preview-label">VISTA PREVIA</span>
                {experience && <span className="preview-name">{experience.category}</span>}
              </div>
              {experience && (
                <div className="preview-controls">
                  <div className="device-switch" aria-label="Tamaño de vista">
                    <button className={view === "desktop" ? "selected" : ""} onClick={() => setView("desktop")} aria-label="Vista escritorio">▰</button>
                    <button className={view === "mobile" ? "selected" : ""} onClick={() => setView("mobile")} aria-label="Vista móvil">▯</button>
                  </div>
                  <button className="export-button" onClick={downloadExperience}><DownloadIcon /> Exportar</button>
                </div>
              )}
            </div>

            {experience ? (
              <div className={`generated-canvas ${view === "mobile" ? "mobile-canvas" : ""}`}>
                <div className="canvas-topline">
                  <span className="canvas-logo"><Sparkle size={14} /></span>
                  <span>{experience.category}</span>
                  <span className="canvas-live"><span /> LISTO PARA TI</span>
                </div>
                <div className="canvas-intro">
                  <div><p className="canvas-overline">UN ESPACIO DISEÑADO PARA TI</p><h2>{experience.title}</h2><p>{experience.description}</p></div>
                  <div className="canvas-date">MIÉRCOLES, 18 JUN <span>⌄</span></div>
                </div>
                <div className="stat-grid">
                  {experience.stats.map((stat, index) => (
                    <article className="stat-card" key={stat.label}>
                      <span className="stat-decoration">{["↗", "◌", "✳"][index]}</span>
                      <span className="stat-label">{stat.label}</span>
                      <strong>{stat.value}</strong>
                      <span className="stat-change">{stat.change}</span>
                    </article>
                  ))}
                </div>
                <div className="canvas-lower">
                  <article className="activity-card">
                    <div className="activity-heading"><div><span className="section-eyebrow">TU SIGUIENTE PASO</span><h3>{experience.archetype === "travel" ? "Un día para recordar" : experience.archetype === "finance" ? "Movimientos recientes" : experience.archetype === "commerce" ? "Selección para ti" : "A tu propio ritmo"}</h3></div><button aria-label="Más opciones">···</button></div>
                    <div className="activity-list">
                      {experience.items.map((item, index) => (
                        <button className={`activity-row ${completedItems.includes(index) ? "item-complete" : ""}`} key={item} onClick={() => setCompletedItems((current) => current.includes(index) ? current.filter((entry) => entry !== index) : [...current, index])}>
                          <span className="activity-check">{completedItems.includes(index) ? "✓" : String(index + 1).padStart(2, "0")}</span>
                          <span>{item}</span>
                          <span className="activity-arrow">↗</span>
                        </button>
                      ))}
                    </div>
                  </article>
                  <article className="note-card">
                    <span className="note-sparkle"><Sparkle size={15} /></span>
                    <span className="section-eyebrow">UNA NOTA PARA TI</span>
                    <p>{experience.archetype === "finance" ? "Cada pequeño hábito cuenta. Vas por buen camino con tus metas." : experience.archetype === "travel" ? "Deja un espacio en blanco en el itinerario. A veces ahí sucede lo mejor." : experience.archetype === "wellness" ? "No hace falta hacerlo todo. Un paso amable también es progreso." : "Empieza por lo que más importa. Lo demás puede esperar."}</p>
                    <span className="note-signoff">con cariño, forma <Sparkle size={12} /></span>
                  </article>
                </div>
                <div className="canvas-footnote"><span><span className="status-dot" /> Tu espacio está listo</span><span>CREADO CON FORMA</span></div>
              </div>
            ) : (
              <div className="empty-canvas">
                <div className="empty-art">
                  <span className="art-sun" />
                  <span className="art-card art-card-back"><i /><i /><i /></span>
                  <span className="art-card art-card-front"><i /><i /><i /><i /></span>
                  <span className="art-sparkle"><Sparkle size={20} /></span>
                  <span className="art-dot" />
                </div>
                <h3>Tu próxima gran idea empieza aquí</h3>
                <p>Describe lo que necesitas y aparecerá aquí, lista para explorar.</p>
                <span className="empty-caption">UN LIENZO LLENO DE POSIBILIDADES</span>
              </div>
            )}
          </section>

          <footer className="page-footer"><span>Hecho para imaginar en grande <span className="footer-heart">✳</span></span><span>FORMA STUDIO · 2025</span></footer>
        </div>
      </section>
    </main>
  );
}
