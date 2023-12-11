WINDOW_WIDTH = 500
WINDOW_HEIGHT = 500
WINDOW_PADDING = 10

PADDLE_HEIGHT = 50
PADDLE_WIDTH = 10

BALL_SIZE = 8
BALL_INITIAL_X = WINDOW_WIDTH / 2
BALL_INITIAL_Y = WINDOW_HEIGHT / 2
BALL_SPEED = 600

PLAYER_INITIAL_X = 20 + PADDLE_WIDTH / 2
PLAYER_INITIAL_Y = WINDOW_HEIGHT / 2 
PLAYER_SPEED = 500
PLAYER_DEFLECTION_RATE = 200

OPPONENT_INITIAL_X = WINDOW_WIDTH - 20 - PADDLE_WIDTH / 2
OPPONENT_INITIAL_Y = WINDOW_HEIGHT / 2
OPPONENT_SPEED = PLAYER_SPEED / 1.8
OPPONENT_DELAY = 20

MATCH_TOP_SCORE = 5
MATCH_STATUS_PLAYING = 'playing'
MATCH_STATUS_POINT = 'point'
MATCH_STATUS_WON = 'won'
MATCH_STATUS_LOST = 'lost'

local sound = {
	bounce = love.audio.newSource("sounds/bounce.mp3", "static"),
	point = love.audio.newSource("sounds/point.mp3", "static"),
	failure = love.audio.newSource("sounds/failure.mp3", "static"),
	won = love.audio.newSource("sounds/won.mp3", "static"),
	lost = love.audio.newSource("sounds/lost.mp3", "static"),
	playBounceSound = function (self)
		self.bounce:stop()
		self.bounce:setPitch(math.random(8, 12) / 10)
		self.bounce:play()
	end
}

local state = {
	world = nil,
	match = {
		status = MATCH_STATUS_PLAYING,
	},
	player = {
		score = 0,
		direction = nil,
		hitDeflection = nil
	},
	opponent = {
		score = 0,
	},
	field = {},
	ball = {},
}

function love.load()	
	math.randomseed(os.time())
	love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
	love.window.setTitle('Pong')
	
	state.world = love.physics.newWorld()
	state.world:setCallbacks(onCollision)

	state.field.body = love.physics.newBody(state.world)
	state.field.shape = love.physics.newChainShape(
		true,
		WINDOW_PADDING, WINDOW_PADDING,
		WINDOW_WIDTH - WINDOW_PADDING, WINDOW_PADDING,
		WINDOW_HEIGHT - WINDOW_PADDING, WINDOW_WIDTH - WINDOW_PADDING,
		WINDOW_PADDING, WINDOW_HEIGHT - WINDOW_PADDING 
	)
	state.field.fixture = love.physics.newFixture(state.field.body, state.field.shape)
	state.field.fixture:setFriction(0)
	
	state.ball.body = love.physics.newBody(state.world, 0, 0, "dynamic")
	state.ball.shape = love.physics.newCircleShape(BALL_SIZE)
	state.ball.fixture = love.physics.newFixture(state.ball.body, state.ball.shape)
	state.ball.fixture:setRestitution(1)
	state.ball.fixture:setFriction(0)	
	
	state.player.body = love.physics.newBody(state.world)
	state.player.shape = love.physics.newRectangleShape(PADDLE_WIDTH, PADDLE_HEIGHT)
	state.player.fixture = love.physics.newFixture(state.player.body, state.player.shape)
	state.player.fixture:setFriction(0)
	
	state.opponent.body = love.physics.newBody(state.world)
	state.opponent.shape = love.physics.newRectangleShape(PADDLE_WIDTH, PADDLE_HEIGHT)
	state.opponent.fixture = love.physics.newFixture(state.opponent.body, state.opponent.shape)
	state.opponent.fixture:setFriction(0)

	startMatch()
end

function love.update(dt)
	if love.keyboard.isDown('r') then
		startMatch()
	end

	if state.match.status == MATCH_STATUS_WON or state.match.status == MATCH_STATUS_LOST then
		return
	end

	if state.match.status == MATCH_STATUS_POINT then
		state.match.status = MATCH_STATUS_PLAYING
		resetBallPosition()
		resetPlayerPosition()
		resetOpponentPosition()
	end

	state.world:update(dt)
	updateBallDirection(dt)
	updatePlayerPosition(dt)
	updateOpponentPosition(dt)
end

function love.draw()
	drawField()
	drawScore()
	drawBall()
	drawPlayer()
	drawOpponent()
end

function love.keypressed(key)
	if key == 'escape' then
		love.event.quit()
	end
	if key == 'up' or 'down' then
		state.player.direction = key
	end
end

function love.keyreleased()
	if key == 'up' or 'down' then
		state.player.direction = nil 
	end
end

function startMatch()
	state.match.status = MATCH_STATUS_PLAYING
	state.player.score = 0
	state.opponent.score = 0
	resetBallPosition()
	resetPlayerPosition()
	resetOpponentPosition()
end

function resetBallPosition()
	state.ball.body:setPosition(BALL_INITIAL_X, BALL_INITIAL_Y)
	ballDirection = state.player.score > state.opponent.score and -1 or 1
	state.ball.body:setLinearVelocity(normalizeVelocicy(
		BALL_SPEED * ballDirection,
		math.random(-BALL_SPEED / 3, BALL_SPEED / 3)
	))
end

function resetPlayerPosition()
	state.player.body:setPosition(PLAYER_INITIAL_X, PLAYER_INITIAL_Y)
end

function resetOpponentPosition()
	state.opponent.body:setPosition(OPPONENT_INITIAL_X, OPPONENT_INITIAL_Y)
end

function updateBallDirection(dt)
	if state.player.hitDeflection ~= nill then
		state.ball.body:setLinearVelocity(normalizeVelocicy(
			BALL_SPEED,
			state.player.hitDeflection * PLAYER_DEFLECTION_RATE * dt
		))
		state.player.hitDeflection = nil
	end
end

function updatePlayerPosition(dt)
	if state.player.direction == 'up' then
		state.player.body:setY(math.max(
			WINDOW_PADDING + PADDLE_HEIGHT / 2,
			state.player.body:getY() - PLAYER_SPEED * dt
		))
	elseif state.player.direction == 'down' then
		state.player.body:setY(math.min(
			WINDOW_HEIGHT - WINDOW_PADDING  - PADDLE_HEIGHT / 2,
			state.player.body:getY() + PLAYER_SPEED * dt
		))
	end
end

function updateOpponentPosition(dt)
	if state.ball.body:getY() - state.opponent.body:getY() > OPPONENT_DELAY then
		state.opponent.body:setY(math.min(
			WINDOW_HEIGHT - WINDOW_PADDING  - PADDLE_HEIGHT / 2,
			state.opponent.body:getY() + OPPONENT_SPEED * dt
		))
	elseif state.ball.body:getY() - state.opponent.body:getY() < -OPPONENT_DELAY then
		state.opponent.body:setY(math.max(
			WINDOW_PADDING + PADDLE_HEIGHT / 2,
			state.opponent.body:getY() - OPPONENT_SPEED * dt
		))
	end
end

function drawField()
	love.graphics.line(WINDOW_WIDTH / 2, WINDOW_PADDING, WINDOW_HEIGHT / 2, WINDOW_HEIGHT - WINDOW_PADDING)
	love.graphics.line(state.field.body:getWorldPoints(state.field.shape:getPoints()))
end

function drawScore()
	love.graphics.print(
		'Score: ' .. state.player.score .. ' - ' .. state.opponent.score,
		WINDOW_PADDING + 10,
		WINDOW_PADDING + 10
	)
	if state.match.status == MATCH_STATUS_WON then
		love.graphics.print("You won! Press r to restart", WINDOW_PADDING + 10, WINDOW_PADDING + 30)
	elseif state.match.status == MATCH_STATUS_LOST then
		love.graphics.print("You lost. Press r to restart", WINDOW_PADDING + 10, WINDOW_PADDING + 30)
	end
end

function drawBall()
	love.graphics.circle('fill', state.ball.body:getX(), state.ball.body:getY(), state.ball.shape:getRadius())
end

function drawPlayer()
	love.graphics.polygon("fill", state.player.body:getWorldPoints(state.player.shape:getPoints()))
end

function drawOpponent()
	love.graphics.polygon("fill", state.opponent.body:getWorldPoints(state.opponent.shape:getPoints()))
end

function normalizeVelocicy(x, y)
	absX = math.abs(x)
	absY = math.abs(y)
	x = absX / (absX + absY) * BALL_SPEED * (absX/x)
	y = absY / (absX + absY) * BALL_SPEED * (absY/y)
	return x, y
end

function onCollision(fixtureA, fixtureB, contact)
	if state.field.fixture == fixtureA or state.field.fixture == fixtureB then
		onFieldCollision()
	end

	if state.player.fixture == fixtureA or state.player.fixture == fixtureB then
		onPlayerCollision(contact)
	end

	if state.opponent.fixture == fixtureA or state.opponent.fixture == fixtureB then
		onOpponentCollision()
	end
end

function onFieldCollision()
	opponentScored = state.ball.body:getX() <= WINDOW_PADDING + state.ball.shape:getRadius() + 1
	playerScored = state.ball.body:getX() >= WINDOW_WIDTH - WINDOW_PADDING - state.ball.shape:getRadius() - 1
	
	if opponentScored then
		state.opponent.score = state.opponent.score + 1
		if state.opponent.score == MATCH_TOP_SCORE then 
			state.match.status = MATCH_STATUS_LOST
			sound.lost:play()
		else
			state.match.status = MATCH_STATUS_POINT
			sound.failure:play()
		end
	elseif playerScored then
		state.player.score = state.player.score + 1
		if state.player.score == MATCH_TOP_SCORE then
			state.match.status = MATCH_STATUS_WON
			sound.won:play()
		else
			state.match.status = MATCH_STATUS_POINT
			sound.point:play()
		end
	else
		sound:playBounceSound()
	end
end

function onPlayerCollision(contact)
	contactX, contactY = contact:getPositions()
	delta = contactY - state.player.body:getY()
	percent = delta / PADDLE_HEIGHT
	state.player.hitDeflection = percent * BALL_SPEED
	sound:playBounceSound()
end

function onOpponentCollision()
	sound:playBounceSound()
end