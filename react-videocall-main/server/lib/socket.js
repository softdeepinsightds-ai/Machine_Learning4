const io = require('socket.io')
const users = require('./users')

function initSocket(socket) {
  let id

  socket
    .on('init', async () => {
      console.log('[SERVIDOR] Solicitud INIT recibida:', socket.id)

      id = await users.create(socket)

      if (id) {
        console.log('[SERVIDOR] ID generado:', id)
        socket.emit('init', { id })
      }
      else {
        console.log('[SERVIDOR] Error generando ID')
        socket.emit('error', {
          message: 'Failed to generating user id',
        })
      }
    })
    .on('request', (data) => {
      const receiver = users.get(data.to)

      if (receiver) {
        receiver.emit('request', { from: id })
      }
    })
    .on('call', (data) => {
      const receiver = users.get(data.to)

      if (receiver) {
        receiver.emit('call', { ...data, from: id })
      }
      else {
        socket.emit('failed')
      }
    })
    .on('end', (data) => {
      const receiver = users.get(data.to)

      if (receiver) {
        receiver.emit('end')
      }
    })
    .on('disconnect', () => {
      users.remove(id)
      console.log('[DISCONNECT]', id)
    })
}

module.exports = (server) => {
  io({ path: '/bridge', serveClient: false })
    .listen(server, { log: true })
    .on('connection', (socket) => {
      console.log('[SOCKET] Cliente conectado:', socket.id)
      initSocket(socket)
    })
}