url = require('url')

request = require('request')
Pusher  = require('pusher-client')
Hubot   = require('hubot')

pkg = require('../package')

IDOBATA_URL = process.env.IDOBATA_URL || 'https://idobata.io/'
PUSHER_KEY  = process.env.PUSHER_KEY  || '44ffe67af1c7035be764'
AUTH_TOKEN  = process.env.AUTH_TOKEN

class Idobata extends Hubot.Adapter
  send: (envelope, strings...) ->
    @_postMessage string, envelope.message.data.room_id for string in strings

  reply: (envelope, strings...) ->
    strings = strings.map (string) -> "@#{envelope.user.name} #{string}"
    @send envelope, strings...

  run: ->
    options =
      url: url.resolve(IDOBATA_URL, '/api/seed')
      headers: @_http_headers

    request options, (error, response, body) =>
      unless response.statusCode == 200
        console.error "Idobata return status=#{response.statusCode}. Please check your authentication."
        process.exit 1

      seed = JSON.parse(body)
      bot  = @robot.brain.userForId(seed.records.user.id, seed.records.user)

      pusher = new Pusher(PUSHER_KEY,
        encrypted:    /^https/.test(IDOBATA_URL)
        authEndpoint: url.resolve(IDOBATA_URL, '/pusher/auth')
        auth:
          headers: @_http_headers
      )

      channel = pusher.subscribe(bot.channel_name)

      channel.bind 'message_created', (data) =>
        {message} = data

        return if bot.id == message.sender_id

        user = @robot.brain.userForId(message.sender_id, name: message.sender_name)

        textMessage = new Hubot.TextMessage(user, message.body_plain, message.id)
        textMessage.data = message

        @receive textMessage

      @emit 'connected'

  _http_headers:
    AUTH_TOKEN:   AUTH_TOKEN
    'User-Agent': "hubot-idobata / v#{pkg.version}"

  _postMessage: (source, room_id) ->
    options =
      url:     url.resolve(IDOBATA_URL, '/api/messages')
      headers: @_http_headers

    request.post(options).form({message: {room_id, source}})

exports.use = (robot) ->
  new Idobata(robot)
