# hubot-idobata

[![Build Status](https://travis-ci.org/idobata/hubot-idobata.png)](https://travis-ci.org/idobata/hubot-idobata)

Idobata adapter for GitHub's Hubot

## Setup

1. Install dependency modules:
  ``` sh
  $ npm install --global coffee-script hubot
  ```

2. Create a new hubot:
  ``` sh
  $ hubot --create <path>
  $ cd <path>
  ```

3. Install the [hubot-idobata][]:
  ``` sh
  $ npm install --save hubot-idobata
  ```

4. Create your bot on [Idobata][]:

5. Configure it:

  This adapter requires the following environment variable:
  * `HUBOT_IDOBATA_API_TOKEN`: the API token of bot's account.

  This token is came from:
  ![bot API Token](https://raw.github.com/idobata/hubot-idobata/master/bot_api_token.png)

6. Run your hubot using the [hubot-idobata][]:
  ``` sh
  $ ./bin/hubot --adapter idobata
  ```

## Adapter specified API

### Send message as HTML

You can use `Adapter#sendHTML` instead of `Robot#send` to create message as HTML.

``` coffee
module.exports = (robot) ->
  robot.respond /PING$/i, (msg) ->
    # This API creates the palin text message.
    # msg.send "PONG"

    adapter  = msg.robot.adapter
    envelope = msg.envelope

    # This API creates the HTML message.
    adapter.sendHTML envelope, '<h1>PONG</hi>'
```

## Deploying to heroku

1. First, setup your hubot to deploy to heroku:
  * [Deploying Hubot to Heroku](https://github.com/github/hubot/blob/master/docs/deploying/heroku.md)

2. Add config to heroku:
  * `HUBOT_IDOBATA_API_TOKEN`
  ```
  $ heroku config:set HUBOT_IDOBATA_API_TOKEN=<your bot api token>
  ```

  * `HUBOT_NAME`
  ```
  $ heroku config:set HUBOT_NAME=<your bot name>
  ```

3. Edit `Procfile`:

  ```
  web: bin/hubot -a idobata
  ```

## Development

### Install

To customize hubot-idobata, it is recommended to work in your bot.<br>
After clone, you can install it from your local path.

``` sh
$ git clone https://github.com/idobata/hubot-idobata.git
$ cd /path/to/your/pretty/bot
$ npm install /path/to/hubot-idobata
```

You need to re-install it every time you edit `/path/to/hubot-idobata/*`.

**Caution**
If you clone hubot-idobata to under `node_modules/`, hubot *couldn't respond* your message.<br>
(see: [idobata/hubot-idobata#1](https://github.com/idobata/hubot-idobata/issues/1))

### Test

``` sh
$ npm test
```

## Links

* [Idobata][]
* [Hubot][]

[Idobata]: https://idobata.io/
[Hubot]: http://hubot.github.com/
[hubot-idobata]: https://github.com/idobata/hubot-idobata

## License

(The MIT License)

Copyright (c) 2014 Eiwa System Management, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
