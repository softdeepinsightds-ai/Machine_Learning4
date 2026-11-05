import { useState } from 'react'
import heroImg from './assets/hero.png'
import reactLogo from './assets/react.svg'
import viteLogo from './assets/vite.svg'
import './App.css'

function App() {
 const [contador, setContador] = useState(0)
 return (
 <div className="contenedor">
 <h1>Mi Contador Web en React JS</h1>
 <p>El valor actual es: {contador}</p>
 <button onClick={() => setContador(contador + 1)}>
 Sumar +1
 </button>
 </div>
 )
}
export default App
