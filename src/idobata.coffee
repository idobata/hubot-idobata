Hubot = require('hubot')

class Idobata extends Hubot.Adapter

exports.use = (robot) ->
  new Idobata(robot)
