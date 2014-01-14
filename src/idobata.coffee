url = require('url')

request = require('request')
Pusher  = require('pusher-client')
Hubot   = require('hubot')

IDOBATA_URL = process.env.IDOBATA_URL || 'https://idobata.io/'
PUSHER_KEY  = process.env.PUSHER_KEY  || '44ffe67af1c7035be764'

# XXX Get channel name form Idobata after login as bot.
MOCK_CHANNEL_NAME = process.env.CHANNEL_NAME

class Idobata extends Hubot.Adapter
  send: (envelope, strings...) ->
    @_postMessage string, envelope.message.data.room_id for string in strings

  reply: (envelope, strings...) ->
    strings = strings.map (string) -> "@#{envelope.user.name} #{string}"
    @send envelope, strings...

  run: ->
    pusher = new Pusher(PUSHER_KEY,
      encrypted:    /^https/.test(IDOBATA_URL)
      authEndpoint: url.resolve(IDOBATA_URL, '/pusher/auth')
    )
    channel = pusher.subscribe MOCK_CHANNEL_NAME

    channel.bind 'message_created', (data) =>
      {message} = data

      # XXX Ignore own message

      user = @robot.brain.userForId(message.sender_id, name: message.sender_name)

      textMessage = new Hubot.TextMessage(user, message.body_plain, message.id)
      textMessage.data = message

      @receive textMessage

    @emit 'connected'

  _postMessage: (source, room_id) ->
    request.post(url.resolve(IDOBATA_URL, '/api/messages')).form({message: {room_id, source}})

exports.use = (robot) ->
  new Idobata(robot)
