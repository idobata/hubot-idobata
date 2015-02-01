Url  = require('url')
Util = require('util')

Request = require('request')
Pusher  = require('pusher-client')
Hubot   = require('hubot')
Package = require('../package')

IDOBATA_URL = process.env.HUBOT_IDOBATA_URL        || 'https://idobata.io/'
PUSHER_KEY  = process.env.HUBOT_IDOBATA_PUSHER_KEY || '44ffe67af1c7035be764'
API_TOKEN   = process.env.HUBOT_IDOBATA_API_TOKEN

class Idobata extends Hubot.Adapter
  send: (envelope, strings...) ->
    @_postMessage {source: string, room_id: @_extractRoomId(envelope)} for string in strings

  reply: (envelope, strings...) ->
    strings = strings.map (string) -> "@#{envelope.user.name} #{string}"
    @send envelope, strings...

  run: ->
    unless API_TOKEN
      @emit 'error', new Error(`'The environment variable \`\033[31mHUBOT_IDOBATA_API_TOKEN\033[39m\` is required.'`)

    options =
      url:     Url.resolve(IDOBATA_URL, '/api/seed')
      headers: @_http_headers

    Request options, (error, response, body) =>
      unless response.statusCode == 200
        console.error `'Idobata returns (status=' + response.statusCode + '). Please check your \`\033[31mHUBOT_IDOBATA_API_TOKEN\033[39m\`.'`

        @emit 'error', error

      seed = JSON.parse(body)
      _bot = seed.records.bot
      bot  = @robot.brain.userForId("bot:#{_bot.id}", _bot)

      Util._extend bot, _bot

      if bot.name != @robot.name
        console.warn """
          Your bot on Idobata is named as '#{bot.name}'.
          But this hubot is named as '#{@robot.name}'.
          To respond to mention correctly, it is recommended that #{`'\033[33mHUBOT_NAME='`}#{bot.name}#{`'\033[39m'`} is configured.
        """

      pusher = new Pusher(PUSHER_KEY,
        encrypted:    /^https/.test(IDOBATA_URL)
        authEndpoint: Url.resolve(IDOBATA_URL, '/pusher/auth')
        auth:
          headers: @_http_headers
      )

      channel = pusher.subscribe(bot.channel_name)

      channel.bind 'message:created', ({message}) =>
        identifier = "#{message.sender_type.toLowerCase()}:#{message.sender_id}"
        _user      = {name: message.sender_name}
        user       = @robot.brain.userForId(identifier, _user)

        Util._extend user, _user

        return if "bot:#{bot.id}" == identifier

        textMessage = new Hubot.TextMessage(user, message.body_plain, message.id)
        textMessage.data = message

        @receive textMessage

      pusher.connection.bind 'disconnected', =>
        # When `pusher.connect` is failed, `disconnected` event is fired. So `setInterval` is not needed.
        setTimeout ->
          do pusher.connect
        , @_reconnectInterval

      @emit 'connected'

  sendHTML: (envelope, htmls...) ->
    for html in htmls
      @_postMessage
        source:  html,
        room_id: @_extractRoomId(envelope),
        format:  'html'

  _extractRoomId: (envelope) ->
    {room, message} = envelope

    if message
      # The payload from Idobata has `room_id` the following path.
      message.data.room_id
    else if room
      # `Robot#messageRoom` call `send` with `{room: room_id}`.
      room
    else
      throw "`envelope` has no room_id: #{Util.inspect(envelope)}"

  _postMessage: (message) ->
    options =
      url:     Url.resolve(IDOBATA_URL, '/api/messages')
      headers: @_http_headers
      form:    {message}

    Request.post(options)

  _http_headers:
    'X-API-Token': API_TOKEN
    'User-Agent':  "hubot-idobata / v#{Package.version}"

  _reconnectInterval: 5 * 1000 # 5s

exports.use = (robot) ->
  new Idobata(robot)
