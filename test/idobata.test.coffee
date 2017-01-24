# XXX Extract or stub
process.env.HUBOT_IDOBATA_API_TOKEN = 'MY API TOKEN'

querystring = require('querystring')

assert  = require('power-assert')
sinon   = require('sinon')
nock    = require('nock')
streams = require('memory-streams')

MockRobot   = require('./mock/robot')
MessageData = require('./mock/message')

Adapter = require('../')

describe 'hubot-idobata', ->
  robot   = null
  adapter = null
  pusher  = null
  stream  = null

  beforeEach ->
    seed =
      version: 1
      last_event_id: 42
      records:
        bot:
          id:           99
          name:         'Hubot'
          icon_url:     'http://www.gravatar.com/avatar/9fef32520aa08836d774873cb8b7df28.png'
          token:        'API TOKEN'
          status:       'online'
          channel_name: 'presence-guy_99'

    stream = new streams.ReadableStream """
      event: seed
      data: #{JSON.stringify(seed)}


    """

    nock('https://idobata.io')
      .get('/api/stream')
      .query(access_token: 'MY API TOKEN')
      .reply 200, -> stream

    robot   = new MockRobot
    adapter = robot.adapter

  afterEach ->
    do nock.cleanAll

  describe '#run', (done) ->
    # TODO Test error thrown

    beforeEach ->
      do robot.run

    it 'should receive connected event', (done) ->
      adapter.on 'connected', done

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

        stream.append """
          event: event
          data: #{JSON.stringify(type: 'message:created', data: MessageData)}


        """

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

        stream.append """
          event: event
          data: #{JSON.stringify(type: 'message:created', data: MessageData)}


        """

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

        stream.append """
          event: event
          data: #{JSON.stringify(type: 'message:created', data: MessageData)}


        """

    describe 'User data', ->
      it 'should updated in automatically', ->
        assert robot.brain.userForName('hi') == null

        stream.append """
          event: event
          data: #{JSON.stringify(type: 'message:created', data: {message: {sender_id: 43, sender_type: 'User', sender_name: 'hi'}})}


        """

        assert robot.brain.userForId('user:43').name == 'hi'

        stream.append """
          event: event
          data: #{JSON.stringify(type: 'message:created', data: {message: {sender_id: 43, sender_type: 'User', sender_name: 'hihi'}})}


        """

        assert robot.brain.userForId('user:43').name == 'hihi'
