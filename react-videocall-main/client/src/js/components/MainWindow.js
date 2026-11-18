
import React, { useEffect, useState } from 'react'
import PropTypes from 'prop-types'
import { faPhone, faVideo } from '@fortawesome/free-solid-svg-icons'
import ActionButton from './ActionButton'
import { socket } from '../communication'

function useClientID() {
  const [clientID, setClientID] = useState('')

  useEffect(() => {
    const handleInit = ({ id }) => {
      console.log('[CLIENTE] Mi identificador:', id)
      document.title = `${id} - VideoCall`
      setClientID(id)
    }

    socket.on('init', handleInit)
    socket.emit('init')

    return () => {
      socket.off('init', handleInit)
    }
  }, [])

  return clientID
}

function MainWindow({ startCall }) {
  const clientID = useClientID()
  const [friendID, setFriendID] = useState('')

  const callWithVideo = (video) => {
    return () => {
      const targetID = friendID.trim()

      if (!targetID) {
        alert('Ingresa el ID de tu amigo.')
        return
      }

      if (targetID === clientID) {
        alert('No puedes llamarte a ti mismo.')
        return
      }

      const config = {
        audio: true,
        video,
      }

      startCall(true, targetID, config)
    }
  }

  return (
    <div className="container main-window">

      <div>
        <h3>
          Hi, your ID is

          <input
            type="text"
            className="txt-clientId"
            value={clientID}
            readOnly
            autoComplete="off"
          />
        </h3>

        <h4>Get started by calling a friend below</h4>
      </div>

      <div>
        <input
          type="text"
          className="txt-clientId"
          placeholder="Your friend ID"
          value={friendID}
          onChange={(event) => setFriendID(event.target.value)}
          spellCheck={false}
          autoComplete="off"
          autoCapitalize="off"
        />

        <div>
          <ActionButton
            icon={faVideo}
            onClick={callWithVideo(true)}
          />

          <ActionButton
            icon={faPhone}
            onClick={callWithVideo(false)}
          />
        </div>
      </div>

    </div>
  )
}

MainWindow.propTypes = {
  startCall: PropTypes.func.isRequired,
}

export default MainWindow
