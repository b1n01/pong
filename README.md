# Pong

A pong-like written in Lua with [LÖVE](https://love2d.org/) in less than 300 lines.

Try it in your browser [here](https://b1n01-pong.netlify.app).

## Run on browser

Build pong for the web using [Love.js](https://github.com/Davidobot/love.js) on a Linux / macOS system with:

```bash
cd /path/to/pong/folder
zip -9 -r pong.love .
npx love.js pong.love pong.js -c
```

Now the `pong.js` fonder should contain a browser ready pong version. Serve it locally with something like `npx serve pong.js` to try it out.

## Run on your machine

Download and install [LÖVE](https://love2d.org/#download) then run:

```bash
git clone https://github.com/b1n01/pong.git
love pong
```

## License

Included sound effects are under the [Mixkit Sound Effects Free License](https://mixkit.co/license/#sfxFree).