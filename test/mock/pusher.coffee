{EventEmitter} = require('events')

class MockPusher
  constructor: (@apiKey, @options) ->
    @channels = {}

    @connection = new MockConnection()

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

  connect: ->
    @connection.emit 'connected'

  disconnect: ->
    @connection.emit 'disconnected'

class MockConnection extends EventEmitter
  bind:   EventEmitter::addListener
  unbind: EventEmitter::removeListener

module.exports = MockPusher
