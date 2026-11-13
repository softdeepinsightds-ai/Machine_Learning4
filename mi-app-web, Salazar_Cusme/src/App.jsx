import { useState } from 'react'
import './App.css'

const initialSightings = [
  { id: 1, name: 'Colibrí orejivioleta', scientific: 'Colibri coruscans', category: 'Ave', icon: '🐦', color: 'blue', time: 'hace 8 min', place: 'Jardín central', x: 49, y: 35, status: 'Seguimiento activo', author: 'Lucía M.' },
  { id: 2, name: 'Abejas melíferas', scientific: 'Apis mellifera', category: 'Insecto', icon: '🐝', color: 'yellow', time: 'hace 21 min', place: 'Pabellón de ciencias', x: 71, y: 53, status: 'Colonia en observación', author: 'Mateo R.' },
  { id: 3, name: 'Hongo de jardín', scientific: 'Coprinellus micaceus', category: 'Hongo', icon: '🍄', color: 'coral', time: 'hace 1 h', place: 'Sendero norte', x: 30, y: 66, status: 'Misión activa', author: 'Sofía P.' },
  { id: 4, name: 'Lantana', scientific: 'Lantana camara', category: 'Planta', icon: '🌿', color: 'green', time: 'hace 2 h', place: 'Límite del campus', x: 81, y: 29, status: 'Posible invasora', author: 'Diego C.' },
]

const initialAlerts = [
  { id: 1, title: 'Colonia de abejas necesita atención', text: 'Se detectó una colmena cerca del Pabellón de ciencias. Ayuda a monitorear su actividad.', icon: '🐝', time: 'hace 21 min', distance: '0.4 km', tone: 'amber', action: 'Ver misión' },
  { id: 2, title: 'Posible especie invasora', text: 'Lantana camara reportada en el límite norte del campus.', icon: '🌱', time: 'hace 2 h', distance: '1.2 km', tone: 'rose', action: 'Revisar reporte' },
]

const navigation = [
  { id: 'explorar', label: 'Explorar', icon: 'compass' },
  { id: 'misiones', label: 'Mis misiones', icon: 'target', count: '3' },
  { id: 'comunidad', label: 'Comunidad', icon: 'users', count: '2' },
  { id: 'perfil', label: 'Mi perfil', icon: 'user' },
]

function Icon({ name, size = 20 }) {
  const paths = {
    compass: <><circle cx="12" cy="12" r="9" /><path d="m15.8 8.2-2.6 5-5 2.6 2.6-5 5-2.6Z" /></>,
    target: <><circle cx="12" cy="12" r="9" /><circle cx="12" cy="12" r="4" /><path d="M12 2v3m10 7h-3M12 22v-3M2 12h3" /></>,
    users: <><path d="M16 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="10" cy="7" r="4" /><path d="M20 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" /></>,
    user: <><circle cx="12" cy="8" r="4" /><path d="M5 21a7 7 0 0 1 14 0" /></>,
    bell: <><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" /><path d="M10 21h4" /></>,
    plus: <><path d="M12 5v14M5 12h14" /></>,
    search: <><circle cx="11" cy="11" r="7" /><path d="m20 20-4-4" /></>,
    pin: <><path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0Z" /><circle cx="12" cy="10" r="2.5" /></>,
    arrow: <><path d="M7 17 17 7M7 7h10v10" /></>,
    leaf: <><path d="M20 4c-9 0-15 4-15 11a5 5 0 0 0 5 5c7 0 11-6 10-16Z" /><path d="M4 21c3-5 6-8 11-11" /></>,
    camera: <><path d="M14 4h-4L8 7H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2-3Z" /><circle cx="12" cy="13" r="3" /></>,
    clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
    check: <path d="m5 12 4 4L19 6" />,
    close: <><path d="m18 6-12 12M6 6l12 12" /></>,
    menu: <><path d="M4 6h16M4 12h16M4 18h16" /></>,
    locate: <><circle cx="12" cy="12" r="3" /><path d="M12 2v3m0 14v3M2 12h3m14 0h3" /></>,
    chevron: <path d="m9 18 6-6-6-6" />,
    spark: <><path d="m12 3 1.9 5.8L20 11l-6.1 2.2L12 19l-1.9-5.8L4 11l6.1-2.2L12 3Z" /><path d="m19 14 1.2 2.8L23 18l-2.8 1.2L19 22l-1.2-2.8L15 18l2.8-1.2L19 14Z" /></>,
  }
  return <svg aria-hidden="true" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">{paths[name]}</svg>
}

function App() {
  const [activeTab, setActiveTab] = useState('explorar')
  const [activeFilter, setActiveFilter] = useState('Todas')
  const [selectedId, setSelectedId] = useState(1)
  const [sightings, setSightings] = useState(initialSightings)
  const [alerts, setAlerts] = useState(initialAlerts)
  const [isReportOpen, setIsReportOpen] = useState(false)
  const [toast, setToast] = useState('')
  const [location, setLocation] = useState('Campus universitario')
  const [locationEnabled, setLocationEnabled] = useState(false)
  const [query, setQuery] = useState('')
  const [zoom, setZoom] = useState(1)

  const selectedSighting = sightings.find((item) => item.id === selectedId) ?? sightings[0]
  const visibleSightings = sightings.filter((item) => {
    const matchesFilter = activeFilter === 'Todas' || item.category === activeFilter
    const matchesQuery = `${item.name} ${item.place} ${item.category}`.toLowerCase().includes(query.toLowerCase())
    return matchesFilter && matchesQuery
  })

  function showToast(message) {
    setToast(message)
    window.setTimeout(() => setToast(''), 3500)
  }

  function enableLocation() {
    if (!navigator.geolocation) {
      showToast('Este navegador no permite compartir la ubicación.')
      return
    }
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        setLocation(`${coords.latitude.toFixed(3)}°, ${coords.longitude.toFixed(3)}°`)
        setLocationEnabled(true)
        showToast('Ubicación activada para esta sesión.')
      },
      () => showToast('No se pudo acceder a tu ubicación. Revisa los permisos del navegador.'),
      { enableHighAccuracy: true, timeout: 10000 },
    )
  }

  function submitReport(event) {
    event.preventDefault()
    const formData = new FormData(event.currentTarget)
    const name = String(formData.get('species')).trim()
    const category = String(formData.get('category'))
    const concern = String(formData.get('concern'))
    const report = {
      id: Date.now(),
      name,
      scientific: 'Identificación pendiente de revisión',
      category,
      icon: { Ave: '🐦', Insecto: '🐝', Planta: '🌿', Hongo: '🍄', Otro: '🦋' }[category],
      color: 'green',
      time: 'ahora',
      place: locationEnabled ? 'Tu ubicación' : 'Campus universitario',
      x: 52,
      y: 47,
      status: concern === 'normal' ? 'Misión activa' : 'Alerta comunitaria',
      author: 'Tú',
    }
    setSightings((current) => [report, ...current])
    setSelectedId(report.id)
    setActiveTab('explorar')
    setIsReportOpen(false)
    if (concern !== 'normal') {
      setAlerts((current) => [{
        id: report.id,
        title: concern === 'invasora' ? 'Posible especie invasora' : concern === 'colonia' ? 'Fauna que necesita atención' : 'Avistamiento inusual',
        text: `${name} reportada en ${report.place}. Se ha creado una misión de seguimiento.`,
        icon: report.icon,
        time: 'ahora',
        distance: 'cerca de ti',
        tone: concern === 'invasora' ? 'rose' : 'amber',
        action: 'Ver misión',
      }, ...current])
      showToast('Misión creada. Alerta de prueba preparada para un radio de 2 km.')
    } else {
      showToast('Reporte guardado y misión de monitoreo creada.')
    }
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <a className="brand" href="#" onClick={(event) => { event.preventDefault(); setActiveTab('explorar') }}>
          <span className="brand-mark"><Icon name="leaf" size={23} /></span>
          <span className="brand-copy"><strong>bio<span>radar</span></strong><small>CIENCIA EN COMUNIDAD</small></span>
        </a>
        <div className="campus-select"><span className="campus-avatar">U</span><span><strong>Mi comunidad</strong><small>{location}</small></span><Icon name="chevron" size={15} /></div>
        <span className="nav-caption">ESPACIO DE CAMPO</span>
        <nav className="side-nav" aria-label="Navegación principal">
          {navigation.map((item) => (
            <button key={item.id} className={`nav-item ${activeTab === item.id ? 'active' : ''}`} onClick={() => setActiveTab(item.id)}>
              <Icon name={item.icon} size={19} /><span>{item.label}</span>
              {item.count && <span className={`nav-count ${item.id === 'comunidad' ? 'alert-count' : ''}`}>{item.id === 'comunidad' ? alerts.length : item.count}</span>}
            </button>
          ))}
        </nav>
        <div className="sidebar-spacer" />
        <div className="impact-card"><div className="impact-icon"><Icon name="spark" size={19} /></div><strong>Pequeñas observaciones,<br />grandes descubrimientos.</strong><p>Ya formas parte de una comunidad que cuida la biodiversidad.</p><div className="impact-progress"><span /></div><small>Tu impacto este mes <b>68%</b></small></div>
        <button className="profile-button" onClick={() => setActiveTab('perfil')}><span className="profile-avatar">LM</span><span><strong>Lucía Martínez</strong><small>Exploradora nivel 2</small></span><span className="profile-dots">···</span></button>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <div className="breadcrumb"><span>Comunidad</span><Icon name="chevron" size={14} /><strong>{navigation.find((item) => item.id === activeTab)?.label}</strong></div>
          <div className="top-actions">
            <span className="prototype-label"><span /> PROTOTIPO</span>
            <button className="icon-button notification-button" aria-label="Ver alertas" onClick={() => setActiveTab('comunidad')}><Icon name="bell" size={19} /><i>{alerts.length}</i></button>
            <button className="top-avatar" aria-label="Abrir perfil" onClick={() => setActiveTab('perfil')}>LM</button>
          </div>
        </header>

        <div className="page-content">
          {activeTab === 'explorar' && (
            <>
              <section className="welcome-row">
                <div><div className="eyebrow"><span className="live-dot" /> TU CAMPUS, EN TIEMPO REAL</div><h1>Hola, Lucía <span>✳</span></h1><p className="page-subtitle">Cada observación cuenta. ¿Qué descubrimos hoy?</p></div>
                <button className="primary-button" onClick={() => setIsReportOpen(true)}><Icon name="plus" size={18} /> Registrar hallazgo</button>
              </section>
              <section className="stats-row" aria-label="Resumen de la comunidad">
                <div className="stat-card"><span className="stat-icon mint"><Icon name="leaf" size={18} /></span><span className="stat-copy"><small>Especies registradas</small><strong>{String(128 + sightings.length - initialSightings.length).padStart(3, '0')} <em>+12 esta semana</em></strong></span><span className="stat-spark">⌁</span></div>
                <div className="stat-card"><span className="stat-icon lilac"><Icon name="target" size={18} /></span><span className="stat-copy"><small>Misiones activas</small><strong>{3 + Math.max(0, sightings.length - initialSightings.length)} <em>en seguimiento</em></strong></span><span className="stat-spark">⌁</span></div>
                <div className="stat-card"><span className="stat-icon peach"><Icon name="users" size={18} /></span><span className="stat-copy"><small>Exploradores cerca</small><strong>24 <em>en tu comunidad</em></strong></span><span className="stat-spark">⌁</span></div>
              </section>
              <div className="dashboard-grid">
                <section className="panel map-panel">
                  <div className="panel-heading map-heading"><div><div className="section-title-line"><h2>Mapa de observaciones</h2><span className="live-pill"><span /> EN VIVO</span></div><p>Descubrimientos alrededor de {location}</p></div><button className="subtle-button" onClick={enableLocation}><Icon name="locate" size={16} /> Mi ubicación</button></div>
                  <div className="map-filters" role="group" aria-label="Filtrar por categoría">
                    {['Todas', 'Ave', 'Insecto', 'Planta', 'Hongo'].map((filter) => <button key={filter} onClick={() => setActiveFilter(filter)} className={activeFilter === filter ? 'selected' : ''}>{filter}</button>)}
                    <label className="map-search"><Icon name="search" size={15} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Buscar especie" aria-label="Buscar especie" /></label>
                  </div>
                  <div className="map-canvas" aria-label="Mapa ilustrado con observaciones del campus">
                    <div className="map-label map-label-a">JARDÍN CENTRAL</div><div className="map-label map-label-b">PABELLÓN DE CIENCIAS</div><div className="map-label map-label-c">SENDERO NORTE</div><div className="map-label map-label-d">CAMPUS</div>
                    <svg className="map-streets" viewBox="0 0 800 400" preserveAspectRatio="none" aria-hidden="true">
                      <path d="M-20 93 C140 77 176 172 332 152 S557 77 826 126" /><path d="M-20 263 C147 243 244 287 391 270 S631 197 826 228" /><path d="M190 -20 C236 80 192 159 257 231 S358 313 345 420" /><path d="M580 -20 C516 67 611 147 570 220 S526 334 613 420" /><path className="street-thin" d="M20 14 280 390M770 22 433 392M20 358 797 40M44 210 784 184" />
                    </svg>
                    <div className="park park-one" /><div className="park park-two" /><div className="park park-three" />
                    {visibleSightings.map((item) => <button key={item.id} className={`map-marker ${item.color} ${selectedId === item.id ? 'focused' : ''}`} style={{ left: `${item.x}%`, top: `${item.y}%`, '--marker-scale': zoom }} onClick={() => setSelectedId(item.id)} aria-label={`${item.name}, ${item.place}`}><span>{item.icon}</span></button>)}
                    {locationEnabled && <span className="you-marker" style={{ left: '51%', top: '48%' }} title="Tu ubicación"><i /></span>}
                    <div className="map-zoom"><button onClick={() => setZoom((value) => Math.min(1.3, value + 0.1))} aria-label="Acercar">+</button><button onClick={() => setZoom((value) => Math.max(0.8, value - 0.1))} aria-label="Alejar">−</button></div>
                    <span className="map-attribution">Mapa ilustrativo · BioRadar</span>
                  </div>
                  <div className="map-legend"><span><i className="legend-dot green-dot" /> Plantas</span><span><i className="legend-dot blue-dot" /> Aves</span><span><i className="legend-dot yellow-dot" /> Insectos</span><span><i className="legend-dot coral-dot" /> Hongos</span><span className="map-total">{visibleSightings.length} observaciones visibles</span></div>
                </section>

                <section className="panel selected-panel">
                  <div className="panel-heading"><div><div className="section-title-line"><h2>En el radar</h2><span className="count-badge">{visibleSightings.length}</span></div><p>Observaciones recientes</p></div><button className="text-button" onClick={() => setActiveTab('misiones')}>Ver todo <Icon name="chevron" size={15} /></button></div>
                  {selectedSighting ? <div className="selected-card"><div className={`species-visual ${selectedSighting.color}`}><span>{selectedSighting.icon}</span><span className="species-spark">✳</span></div><div className="selected-info"><span className="status-tag"><i /> {selectedSighting.status}</span><h3>{selectedSighting.name}</h3><p className="latin-name">{selectedSighting.scientific}</p><div className="sighting-meta"><span><Icon name="pin" size={14} />{selectedSighting.place}</span><span><Icon name="clock" size={14} />{selectedSighting.time}</span></div><div className="observer-row"><span className="observer-avatar">{selectedSighting.author === 'Tú' ? 'LM' : selectedSighting.author.slice(0, 1)}</span><span>Reportado por <b>{selectedSighting.author}</b></span><button aria-label="Ver detalle de la misión" onClick={() => setActiveTab('misiones')}><Icon name="arrow" size={16} /></button></div></div></div> : <div className="empty-state">No hay observaciones para este filtro. Prueba otra categoría.</div>}
                  <div className="panel-divider" />
                  <div className="mini-alert-heading"><span className="alert-heading-icon"><Icon name="bell" size={15} /></span><span>Alerta en tu comunidad</span><b>{alerts.length}</b></div>
                  {alerts.length > 0 ? <button className={`mini-alert ${alerts[0].tone}`} onClick={() => setActiveTab('comunidad')}><span className="mini-alert-emoji">{alerts[0].icon}</span><span><strong>{alerts[0].title}</strong><small>{alerts[0].distance} de ti · {alerts[0].time}</small></span><Icon name="chevron" size={16} /></button> : <p className="empty-alert">Todo tranquilo por aquí. Las nuevas alertas aparecerán aquí.</p>}
                  <button className="community-link" onClick={() => setActiveTab('comunidad')}>Ver alertas de la comunidad <Icon name="arrow" size={14} /></button>
                </section>
              </div>
              <section className="mission-strip"><span className="mission-icon"><Icon name="target" size={19} /></span><span className="mission-copy"><small>MONITOREO CONTINUO</small><strong>Tu campus está lleno de vida. ¿Nos ayudas a observar?</strong></span><span className="mission-progress"><i /><i /><i /><i /><i /><small>3 misiones activas</small></span><button className="text-button" onClick={() => setActiveTab('misiones')}>Explorar misiones <Icon name="arrow" size={15} /></button></section>
            </>
          )}

          {activeTab === 'misiones' && <section className="subpage"><div className="welcome-row"><div><div className="eyebrow"><span className="live-dot" /> OBSERVACIÓN CONTINUA</div><h1>Misiones de campo</h1><p className="page-subtitle">Seguimos cada hallazgo, juntos y en tiempo real.</p></div><button className="primary-button" onClick={() => setIsReportOpen(true)}><Icon name="plus" size={18} /> Nuevo hallazgo</button></div><div className="mission-list">{sightings.map((item, index) => <article className="mission-card" key={item.id}><div className={`mission-species ${item.color}`}>{item.icon}</div><div className="mission-details"><span className="status-tag"><i /> {item.status}</span><h3>{item.name}</h3><p>{item.scientific}</p><div className="sighting-meta"><span><Icon name="pin" size={14} />{item.place}</span><span><Icon name="clock" size={14} />Última observación: {item.time}</span></div></div><div className="mission-card-progress"><span className="progress-ring">{index % 2 === 0 ? '3' : '2'}</span><small>observaciones<br />esta semana</small></div><button className="text-button" onClick={() => { setSelectedId(item.id); setActiveTab('explorar') }}>Ver en mapa <Icon name="arrow" size={15} /></button></article>)}</div></section>}

          {activeTab === 'comunidad' && <section className="subpage"><div className="welcome-row"><div><div className="eyebrow"><span className="live-dot" /> RED DE ALERTAS GEOLOCALIZADAS</div><h1>Comunidad cercana</h1><p className="page-subtitle">Avisos importantes dentro de un radio de 2 km.</p></div><span className="radius-chip"><Icon name="pin" size={15} /> Radio de 2 km</span></div><div className="community-banner"><span className="banner-icon"><Icon name="users" size={22} /></span><div><strong>La naturaleza nos necesita en equipo.</strong><p>Cuando alguien reporta una especie que requiere atención, la comunidad cercana puede ayudar a observar y cuidar.</p></div><span className="nearby-count">24 <small>exploradores<br />cerca</small></span></div><div className="alert-list">{alerts.length ? alerts.map((alert) => <article className={`alert-card ${alert.tone}`} key={alert.id}><span className="alert-emoji">{alert.icon}</span><div className="alert-content"><span className="alert-kicker"><i /> ALERTA COMUNITARIA · {alert.time}</span><h3>{alert.title}</h3><p>{alert.text}</p><div className="alert-footer"><span><Icon name="pin" size={15} />{alert.distance} de tu comunidad</span><button onClick={() => setActiveTab('misiones')}>{alert.action} <Icon name="arrow" size={14} /></button></div></div></article>) : <div className="empty-state">No hay alertas activas. Gracias por cuidar tu comunidad.</div>}</div><p className="privacy-note"><Icon name="locate" size={15} /> Las alertas se muestran a estudiantes dentro de 2 km. Tu ubicación solo se comparte con tu permiso.</p></section>}

          {activeTab === 'perfil' && <section className="subpage profile-page"><div className="welcome-row"><div><div className="eyebrow">TU HUELLA EN LA COMUNIDAD</div><h1>Mi perfil</h1><p className="page-subtitle">Cada pequeño descubrimiento suma.</p></div></div><div className="profile-summary"><div className="profile-large-avatar">LM</div><div><h2>Lucía Martínez</h2><p>Exploradora de biodiversidad · Nivel 2</p><span className="profile-school">Comunidad del campus</span></div><span className="profile-joined">Miembro desde septiembre 2025</span></div><div className="profile-stats"><div><strong>12</strong><span>observaciones</span></div><div><strong>3</strong><span>misiones activas</span></div><div><strong>8</strong><span>ayudas comunitarias</span></div></div><div className="location-card"><span className="location-card-icon"><Icon name="locate" size={20} /></span><div><strong>Tu ubicación</strong><p>{locationEnabled ? `Activa para esta sesión · ${location}` : 'Actívala para ubicar tus reportes y recibir alertas cercanas.'}</p></div><button className="subtle-button" onClick={enableLocation}>{locationEnabled ? 'Actualizar' : 'Activar ubicación'}</button></div><div className="privacy-note"><Icon name="check" size={16} /> La ubicación solo se utiliza con tu permiso. Puedes desactivarla cuando quieras.</div></section>}
        </div>
        <footer className="app-footer"><span>BioRadar <span>·</span> Ciencia ciudadana para un planeta vivo</span><span>Prototipo educativo · Las observaciones de esta sesión son de prueba</span></footer>
      </main>

      <nav className="mobile-nav" aria-label="Navegación móvil">
        {navigation.slice(0, 3).map((item) => <button key={item.id} className={activeTab === item.id ? 'active' : ''} onClick={() => setActiveTab(item.id)}><Icon name={item.icon} size={20} /><span>{item.label === 'Mis misiones' ? 'Misiones' : item.label}</span></button>)}
        <button className="mobile-add" aria-label="Registrar hallazgo" onClick={() => setIsReportOpen(true)}><Icon name="plus" size={22} /></button>
        <button className={activeTab === 'perfil' ? 'active' : ''} onClick={() => setActiveTab('perfil')}><Icon name="user" size={20} /><span>Perfil</span></button>
      </nav>

      {isReportOpen && <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) setIsReportOpen(false) }}><section className="report-modal" role="dialog" aria-modal="true" aria-labelledby="report-title"><div className="modal-heading"><div><span className="eyebrow"><Icon name="spark" size={13} /> NUEVA OBSERVACIÓN</span><h2 id="report-title">¿Qué encontraste?</h2><p>Tu reporte crea una misión de monitoreo para este lugar.</p></div><button className="icon-button" onClick={() => setIsReportOpen(false)} aria-label="Cerrar"><Icon name="close" size={20} /></button></div><form onSubmit={submitReport}><label className="form-label">Nombre de la especie<input autoFocus name="species" placeholder="Ej. Colibrí, mariposa..." required maxLength={70} /></label><label className="form-label">¿Qué tipo de ser vivo es?<select name="category" defaultValue="Ave"><option>Ave</option><option>Insecto</option><option>Planta</option><option>Hongo</option><option>Otro</option></select></label><label className="form-label">¿Algo necesita atención?<select name="concern" defaultValue="normal"><option value="normal">No, solo quiero observar</option><option value="invasora">Posible especie invasora</option><option value="colonia">Colonia o fauna en riesgo</option><option value="inusual">Avistamiento inusual o migratorio</option></select></label><label className="form-label">Notas de campo <textarea name="notes" placeholder="¿Dónde la viste? ¿Qué estaba haciendo?" rows="3" maxLength={300} /></label><div className="form-location"><Icon name="pin" size={17} /><span><strong>{location}</strong><small>{locationEnabled ? 'Ubicación compartida para este reporte' : 'Ubicación aproximada del campus'}</small></span><button type="button" onClick={enableLocation}>{locationEnabled ? 'Actualizada' : 'Usar GPS'}</button></div><label className="photo-upload"><Icon name="camera" size={17} /><span>Agregar una foto <small>Opcional · identifica visualmente tu observación</small></span><input type="file" accept="image/*" capture="environment" /></label><button className="primary-button submit-report" type="submit"><Icon name="plus" size={18} /> Registrar y crear misión</button><p className="form-footnote">Si requiere atención, se preparará una alerta para estudiantes en un radio de 2 km.</p></form></section></div>}
      {toast && <div className="toast" role="status"><span className="toast-check"><Icon name="check" size={16} /></span>{toast}</div>}
    </div>
  )
}

export default App
