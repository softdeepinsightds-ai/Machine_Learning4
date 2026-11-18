import io from 'socket.io-client'

const socket = io({
    path: '/bridge',
})

socket.on('connect', () => {
    console.log('[SOCKET CLIENT] Conectado:', socket.id)
})

socket.on('connect_error', (error) => {
    console.error('[SOCKET CLIENT] Error:', error.message)
})

socket.on('disconnect', (reason) => {
    console.log('[SOCKET CLIENT] Desconectado:', reason)
})

export default socket