querystring = require('querystring')

assert = require('power-assert')
sinon  = require('sinon')
nock   = require('nock')

Pusher = require('pusher-client')

MockRobot   = require('./mock/robot')
MockPusher  = require('./mock/pusher')
MessageData = require('./mock/message')

# XXX Extract or stub
process.env.HUBOT_IDOBATA_API_TOKEN = 'MY API TOKEN'

Adapter = require('../')

describe 'hubot-idobata', ->
  robot   = null
  adapter = null
  pusher  = null

  beforeEach ->
    nock('https://idobata.io')
      .matchHeader('X-API-Token', 'MY API TOKEN')
      .get('/api/seed')
      .reply 200,
        version: 1
        records:
          bot:
            id:           99
            name:         'Hubot'
            icon_url:     'http://www.gravatar.com/avatar/9fef32520aa08836d774873cb8b7df28.png'
            token:        'API TOKEN'
            status:       'online'
            channel_name: 'presence-guy_99'

    sinon.stub Pusher.prototype, 'initialize', ->
      pusher = new MockPusher(arguments...)

    robot   = new MockRobot(Adapter)
    adapter = robot.adapter

  afterEach ->
    do nock.cleanAll
    do Pusher::initialize.restore

  describe '#run', (done) ->
    # TODO Test error thrown

    beforeEach ->
      do robot.run

    it 'should receive connected event', (done) ->
      adapter.on 'connected', done

    it 'should subscribe own channel', (done) ->
      adapter.on 'connected', ->
        assert pusher.channels['presence-guy_99'].length == 1

        do done

  context 'After connected', ->
    beforeEach (done) ->
      do robot.run

      adapter.on 'connected', done

    describe '#send', ->
      beforeEach ->
        # Echo
        robot.hear /(.*)/, (msg) ->
          msg.send msg.match[1]

      it 'should send message', (done) ->
        nock('https://idobata.io')
          .matchHeader('X-API-Token', 'MY API TOKEN')
          .post('/api/messages')
          .reply 201, (uri, body) ->
            request = querystring.parse(body)

            assert request['message[room_id]'] == '143'
            assert request['message[source]']  == 'hi'

            do done

        pusher.channels['presence-guy_99'][0].trigger 'message:created', MessageData

      it 'should respond with Robot#messageRoom', (done) ->
        nock('https://idobata.io')
          .matchHeader('X-API-Token', 'MY API TOKEN')
          .post('/api/messages')
          .reply 201, (uri, body) ->
            request = querystring.parse(body)

            assert request['message[room_id]'] == '42'
            assert request['message[source]']  == 'hi'

            do done

        robot.messageRoom('42', 'hi')

    describe '#reply', ->
      beforeEach ->
        # Echo
        robot.hear /(.*)/, (msg) ->
          msg.reply msg.match[1]

      it 'should reply mesasge to sender', (done) ->
        nock('https://idobata.io')
          .matchHeader('X-API-Token', 'MY API TOKEN')
          .post('/api/messages')
          .reply 201, (uri, body) ->
            request = querystring.parse(body)

            assert request['message[room_id]'] == '143'
            assert request['message[source]']  == '@homuhomu hi'

            do done

        pusher.channels['presence-guy_99'][0].trigger 'message:created', MessageData

    describe '#sendHTML', ->
      beforeEach ->
        robot.hear /(.*)/, (msg) ->
          {robot: {adapter}, envelope} = msg

          adapter.sendHTML envelope, '<h1>hi</h1>'

      it 'should send message with HTML format', (done) ->
        nock('https://idobata.io')
          .matchHeader('X-API-Token', 'MY API TOKEN')
          .post('/api/messages')
          .reply 201, (uri, body) ->
            request = querystring.parse(body)

            assert request['message[room_id]'] == '143'
            assert request['message[source]']  == '<h1>hi</h1>'
            assert request['message[format]']  == 'html'

            do done

        pusher.channels['presence-guy_99'][0].trigger 'message:created', MessageData

    describe 'User data', ->
      it 'should updated in automatically', ->
        assert robot.brain.userForName('hi') == null

        pusher.channels['presence-guy_99'][0].trigger 'message:created',
          message:
            sender_id:   43
            sender_type: 'User'
            sender_name: 'hi'

        assert robot.brain.userForId('user:43').name == 'hi'

        pusher.channels['presence-guy_99'][0].trigger 'message:created',
          message:
            sender_id:   43
            sender_type: 'User'
            sender_name: 'hihi' # name is updated

        assert robot.brain.userForId('user:43').name == 'hihi'

    context 'when connection is disconnected', ->
      beforeEach ->
        adapter._reconnectInterval = 10

        do pusher.disconnect

      it 'should reconnect automatically', (done) ->
        pusher.connection.bind 'connected', done
