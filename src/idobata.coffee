{Adapter, TextMessage} = require("../../hubot")

Url = require('url')

Request = require('request')
Pusher  = require('pusher-client')
Package = require('../package')

IDOBATA_URL = process.env.HUBOT_IDOBATA_URL        || 'https://idobata.io/'
PUSHER_KEY  = process.env.HUBOT_IDOBATA_PUSHER_KEY || '44ffe67af1c7035be764'
API_TOKEN   = process.env.HUBOT_IDOBATA_API_TOKEN

class Idobata extends Adapter
  constructor: (robot) ->
    super robot

  send: (envelope, strings...) ->
    @_postMessage string, envelope.message.data.room_id for string in strings

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
      bot  = @robot.brain.userForId(seed.records.bot.id, seed.records.bot)

      if seed.records.bot.name != @robot.name
        console.warn """
          Your bot on Idobata is named as '#{seed.records.bot.name}'.
          But this hubot is named as '#{@robot.name}'.
          To respond to mention correctly, it is recommended that #{`'\033[33mHUBOT_NAME='`}#{seed.records.bot.name}#{`'\033[39m'`} is configured.
        """

      pusher = new Pusher(PUSHER_KEY,
        encrypted:    /^https/.test(IDOBATA_URL)
        authEndpoint: Url.resolve(IDOBATA_URL, '/pusher/auth')
        auth:
          headers: @_http_headers
      )

      channel = pusher.subscribe(bot.channel_name)

      channel.bind 'message_created', (data) =>
        {message} = data

        return if bot.id == message.sender_id

        user = @robot.brain.userForId(message.sender_id, name: message.sender_name)

        textMessage = new TextMessage(user, message.body_plain, message.id)
        textMessage.data = message

        @receive textMessage

      @emit 'connected'

  _http_headers:
    'X-API-Token': API_TOKEN
    'User-Agent':  "hubot-idobata / v#{Package.version}"

  _postMessage: (source, room_id) ->
    options =
      url:     Url.resolve(IDOBATA_URL, '/api/messages')
      headers: @_http_headers
      form:
        message: {room_id, source}

    Request.post(options)

exports.use = (robot) ->
  new Idobata(robot)
