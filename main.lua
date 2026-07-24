local game
local player
local grid
function love.load()
    math.randomseed(os.time())
    game = {
        middle = {
            x = love.graphics.getWidth() / 2,
            y = love.graphics.getHeight() / 2,
        },
        score = 0,
        started = false,
        max = {
            x = love.graphics.getWidth(),
            y = love.graphics.getHeight()
        },
        gridTimer = 0,
        gridInterval = 1.5
    }
    player = {
        x = game.middle.x,
        y = game.middle.y,
        speed = 400,
        jumpKey = "space",
        leftKey = "a",
        rightKey = "d",
        radius = 25,
        yVelocity = 0,
        gravity = 800,
        jumpForce = -400,
        onGround = true,
        dead = false
    }
    grid = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
        cellSize = 45,
        cells = {}
    }
    grid.cols = math.floor(grid.width / grid.cellSize)
    grid.rows = math.floor(grid.height / grid.cellSize)
    for i = 0, grid.cols - 1 do
            grid.cells[i] = grid.cells[i] or {}
            for j = 0, grid.rows - 1 do
                grid.cells[i][j] = {
                    x = i * grid.cellSize,
                    y = j * grid.cellSize,
                    width = grid.cellSize,
                    height = grid.cellSize,
                    on = true,
                    danger = false
                }
            end
        end
    print(grid.width)
    print(grid.height)
end

local function randomizeGrid()
    for i = 0, grid.cols - 1 do
        for j = 0, grid.rows - 1 do
            local isOn = math.random() < 0.3
            grid.cells[i][j].on = isOn
            if grid.cells[i][j].on then
                grid.cells[i][j].danger = math.random() < 0.3
            end
        end
    end
end

local function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
        x1 + w1 > x2 and
        y1 < y2 + h2 and
        y1 + h1 > y2
end

local function reset()
    game.score = 0
    game.started = false
    player.x = game.middle.x
    player.y = game.middle.y
    player.yVelocity = 0
    player.onGround = true
    player.dead = false
end

function love.update(dt)
    player.yVelocity = math.min(player.yVelocity + player.gravity * dt, grid.cellSize / dt * 0.9)
    if not game.started and love.keyboard.isDown("lshift") then
        player.onGround = false
        game.started = true
        randomizeGrid()
    end

    if game.started then
        game.gridTimer = game.gridTimer + dt
        if game.gridTimer >= game.gridInterval then
            game.gridTimer = game.gridTimer - game.gridInterval
            randomizeGrid()
        end
    end

    if game.started and love.keyboard.isDown("r") then
        reset()
    end
    player.y = player.y + player.yVelocity * dt

    if player.x > game.max.x or player.x < 0 or player.y > game.max.y or player.y < 0 then
        game.started = false
    end
    --local ground = 300
    for i = 0, grid.cols - 1 do
        for j = 0, grid.rows - 1 do
            local cell = grid.cells[i][j]
            if cell.on and checkCollision(player.x, player.y, player.radius, player.radius, cell.x, cell.y, grid.cellSize, grid.cellSize) then
                if cell.danger then
                    game.started = false
                end
                if player.yVelocity > 0 then
                    player.y = cell.y - player.radius
                    player.yVelocity = 0
                    player.onGround = true
                elseif player.yVelocity < 0 then
                    player.y = cell.y + grid.cellSize
                    player.yVelocity = 0
                end
            end
        end
    end

    local newX = player.x
    if love.keyboard.isDown(player.leftKey) then
        newX = newX - player.speed * dt
    end
    if love.keyboard.isDown(player.rightKey) then
        newX = newX + player.speed * dt
    end

    local blockedX = false
    for i = 0, grid.cols - 1 do
        for j = 0, grid.rows - 1 do
            local cell = grid.cells[i][j]
            if cell.on and checkCollision(newX, player.y, player.radius, player.radius, cell.x, cell.y, grid.cellSize, grid.cellSize) then
                if cell.danger then
                    game.started = false
                    player.dead = true
                end
                blockedX = true
            end
        end
    end

    if not blockedX then
        player.x = newX
    end

    if love.keyboard.isDown(player.jumpKey) and player.onGround then
        player.yVelocity = player.jumpForce
        player.onGround = false
    end
end

function love.draw()
    if game.started then
        for i = 0, grid.cols - 1 do
            for j = 0, grid.rows - 1 do
                if grid.cells[i][j].on then
                    if grid.cells[i][j].danger then
                        love.graphics.setColor(1, 0, 0)
                    else
                        love.graphics.setColor(1, 1, 1)
                    end
                    love.graphics.rectangle("line", grid.cells[i][j].x, grid.cells[i][j].y, grid.cellSize, grid.cellSize)
                end
            end
        end
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("line", player.x, player.y, player.radius, player.radius)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.printf("Game over, press lshift to try again.", game.middle.x, game.middle.y, 900, "center")
    end
    if player.dead then
        love.graphics.clear(1, 0, 0)
    end
end
