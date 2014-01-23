{EventEmitter} = require('events')

class MockPusher
  constructor: (@apiKey, @options) ->
    @channels = {}

  subscribe: (channelName) ->
    @channels[channelName] ||= []

    channel =
      name:   channelName
      events: new EventEmitter()

      bind: (name, callback) ->
        @events.on name, callback

      trigger: (name, payload...) ->
        @events.emit name, payload...

    @channels[channelName].push channel

    channel

module.exports = MockPusher
