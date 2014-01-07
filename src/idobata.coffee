url = require('url')

request = require('request')
Pusher  = require('pusher-client')
Hubot   = require('hubot')

IDOBATA_URL = process.env.IDOBATA_URL || 'https://idobata.io/'
PUSHER_KEY  = process.env.PUSHER_KEY  || '44ffe67af1c7035be764'

# XXX Get channel name form Idobata after login as bot.
MOCK_CHANNEL_NAME = process.env.CHANNEL_NAME

class Idobata extends Hubot.Adapter
  run: ->
    pusher = new Pusher(PUSHER_KEY,
      encrypted:    /^https/.test(IDOBATA_URL)
      authEndpoint: url.resolve(IDOBATA_URL, '/pusher/auth')
    )
    channel = pusher.subscribe MOCK_CHANNEL_NAME

    channel.bind 'message_created', (data) ->
      # TODO Handle message data
      console.log(data)

exports.use = (robot) ->
  new Idobata(robot)
