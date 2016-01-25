{Robot} = require('hubot')
Adapter = require('../../')

class MockRobot extends Robot
  loadAdapter: ->
    @adapter = Adapter.use this

module.exports = MockRobot
