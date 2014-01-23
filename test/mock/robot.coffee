{Robot} = require('hubot')

class MockRobot extends Robot
  loadAdapter: (Adapter) ->
    @adapter = Adapter.use this

module.exports = MockRobot
