# hubot-idobata

## Setup

1. Install dependency modules:
```
$ npm install --global coffee-script hubot
```

2. Create a new hubot if necessary:
```
$ hubot --create <path>
$ cd <path>
```

3. Install the [Idobata][] adapter:
```
$ npm install --save hubot-idobata
```

4. Configure it:
This adapter requires the following environment variable:
  * `HUBOT_IDOBATA_AUTH_TOKEN`: the authentication token of bot's account.

5. Run your hubot using the [Idobata][] adapter:
```
$ ./bin/hubot --adapter idobata
```

[Idobata]: https://idobata.io
