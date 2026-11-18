
import MediaDevice from './MediaDevice'
import Emitter from './Emitter'
import socket from './socket'

const PC_CONFIG = {
  iceServers: [
    { urls: ['stun:stun.l.google.com:19302'] },
  ],
}

class PeerConnection extends Emitter {
  constructor(friendID) {
    super()

    this.pc = new RTCPeerConnection(PC_CONFIG)
    this.friendID = friendID
    this.mediaDevice = new MediaDevice()

    this.pendingCandidates = []
    this.remoteDescriptionReady = false

    this.pc.onicecandidate = (event) => {
      if (event.candidate) {
        socket.emit('call', {
          to: this.friendID,
          candidate: event.candidate,
        })
      }
    }

    this.pc.ontrack = (event) => {
      console.log('[WEBRTC] Video remoto recibido')

      const stream = event.streams?.[0]

      if (stream) {
        this.emit('peerStream', stream)
      }
    }

    this.pc.onconnectionstatechange = () => {
      console.log(
        '[WEBRTC] Estado de conexión:',
        this.pc.connectionState
      )
    }

    this.pc.oniceconnectionstatechange = () => {
      console.log(
        '[WEBRTC] Estado ICE:',
        this.pc.iceConnectionState
      )
    }
  }

  start(isCaller) {
    this.mediaDevice
      .on('stream', (stream) => {
        stream.getTracks().forEach((track) => {
          this.pc.addTrack(track, stream)
        })

        console.log('[WEBRTC] Cámara local activada')

        this.emit('localStream', stream)

        if (isCaller) {
          socket.emit('request', {
            to: this.friendID,
          })
        } else {
          this.createOffer().catch((error) => {
            console.error('[WEBRTC] Error creando oferta:', error)
          })
        }
      })
      .start()

    return this
  }

  async createOffer() {
    const offer = await this.pc.createOffer()

    await this.pc.setLocalDescription(offer)

    socket.emit('call', {
      to: this.friendID,
      sdp: this.pc.localDescription,
    })
  }

  async createAnswer() {
    const answer = await this.pc.createAnswer()

    await this.pc.setLocalDescription(answer)

    socket.emit('call', {
      to: this.friendID,
      sdp: this.pc.localDescription,
    })
  }

  async setRemoteDescription(sdp) {
    await this.pc.setRemoteDescription(
      new RTCSessionDescription(sdp)
    )

    this.remoteDescriptionReady = true

    console.log('[WEBRTC] Descripción remota establecida:', sdp.type)

    // Procesar candidatos ICE que llegaron antes de la descripción.
    while (this.pendingCandidates.length > 0) {
      const candidate = this.pendingCandidates.shift()

      await this.pc.addIceCandidate(
        new RTCIceCandidate(candidate)
      )
    }

    // Si recibimos una oferta, respondemos después de establecerla.
    if (sdp.type === 'offer') {
      await this.createAnswer()
    }
  }

  async addIceCandidate(candidate) {
    if (!candidate) return

    if (!this.remoteDescriptionReady) {
      this.pendingCandidates.push(candidate)
      return
    }

    await this.pc.addIceCandidate(
      new RTCIceCandidate(candidate)
    )
  }

  stop(isStarter) {
    if (isStarter) {
      socket.emit('end', {
        to: this.friendID,
      })
    }

    this.mediaDevice.stop()

    if (this.pc) {
      this.pc.close()
      this.pc = null
    }

    this.off()

    return this
  }
}

export default PeerConnection
