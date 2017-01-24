Url  = require('url')
Util = require('util')

Request     = require('request')
EventSource = require('eventsource')
Package     = require('../package')

try
  {Adapter, TextMessage} = require('hubot')
catch
  {Adapter, TextMessage} = require('parent-require')('hubot')

IDOBATA_URL        = process.env.HUBOT_IDOBATA_URL        || 'https://idobata.io/'
IDOBATA_EVENTD_URL = process.env.HUBOT_IDOBATA_EVENTD_URL || IDOBATA_URL
API_TOKEN          = process.env.HUBOT_IDOBATA_API_TOKEN

class Idobata extends Adapter
  send: (envelope, strings...) ->
    @_postMessage {source: string, room_id: @_extractRoomId(envelope)} for string in strings

  reply: (envelope, strings...) ->
    strings = strings.map (string) -> "@#{envelope.user.name} #{string}"
    @send envelope, strings...

  run: ->
    unless API_TOKEN
      @emit 'error', new Error(`'The environment variable \`\033[31mHUBOT_IDOBATA_API_TOKEN\033[39m\` is required.'`)

    endpoint = Url.resolve(IDOBATA_EVENTD_URL, "/api/stream")
    stream   = new EventSource("#{endpoint}?access_token=#{API_TOKEN}", headers: @_http_headers)

    stream.on 'open', =>
      @robot.logger.info 'hubot-idobata: Established streaming connection'

    stream.on 'seed', (e) =>
      @robot.logger.info 'hubot-idobata: Received seed'

      seed = JSON.parse(e.data)
      _bot = seed.records.bot
      bot  = @robot.brain.userForId("bot:#{_bot.id}", _bot)

      Util._extend bot, _bot

      if bot.name != @robot.name
        @robot.logger.warning """
          Your bot on Idobata is named as '#{bot.name}'.
          But this hubot is named as '#{@robot.name}'.
          To respond to mention correctly, it is recommended that #{`'\033[33mHUBOT_NAME='`}#{bot.name}#{`'\033[39m'`} is configured.
        """

      stream.on 'event', (e) =>
        {type, data} = JSON.parse(e.data)

        return unless type == 'message:created'

        {message} = data

        identifier = "#{message.sender_type.toLowerCase()}:#{message.sender_id}"
        _user      = {name: message.sender_name}
        user       = @robot.brain.userForId(identifier, _user)

        Util._extend user, _user

        return if "bot:#{bot.id}" == identifier

        textMessage = new TextMessage(user, message.body_plain, message.id)
        textMessage.data = message

        @receive textMessage

      @emit 'connected'

    stream.on 'error', (e) =>
      if e.status
        @robot.logger.error `'hubot-idobata: Idobata returns (status=' + e.status + '). Please check your \`\033[31mHUBOT_IDOBATA_API_TOKEN\033[39m\`.'`

        @emit 'error', e
      else
        @robot.logger.info 'hubot-idobata: The connection seems to have been temporarily lost. Reconnecting...'

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
    'Authorization': "Bearer #{API_TOKEN}"
    'User-Agent':    "hubot-idobata / v#{Package.version}"

exports.use = (robot) ->
  new Idobata(robot)
