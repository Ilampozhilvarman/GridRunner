local game
local player
local grid
function love.load()
    game = {
        middle = {
            x = love.graphics.getWidth() / 2,
            y = love.graphics.getHeight() / 2,
        },
        score = 0,
        started = false
    }
    player = {
        x = game.middle.x,
        y = game.middle.y,
        speed = 500,
        jumpKey = "space",
        leftKey = "a",
        rightKey = "d",
        radius = 25,
        yVelocity = 0,
        gravity = 800,
        jumpForce = -400,
        onGround = true
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
                    on = true
                }
            end
        end
    print(grid.width)
    print(grid.height)
end

local function startGame()
    for i = 0, grid.cols - 1 do
        for j = 0, grid.rows - 1 do
            local isOn = math.random() < 0.3
            grid.cells[i][j].on = isOn
        end
    end
end

local function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
        x1 + w1 > x2 and
        y1 < y2 + h2 and
        y1 + h1 > y2
end

function love.update(dt)
    if not game.started then
        startGame()
        player.onGround = false
        game.started = true
    end
    if love.keyboard.isDown(player.leftKey) then
        player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown(player.rightKey) then
        player.x = player.x + player.speed * dt
    end
    player.yVelocity = player.yVelocity + player.gravity * dt
    player.y = player.y + player.yVelocity * dt

    local ground = 300

    for i = 0, grid.cols - 1 do
        for j = 0, grid.rows - 1 do
            local cell = grid.cells[i][j]
            if cell.on and checkCollision(player.x, player.y, player.radius, player.radius, cell.x, cell.y, grid.cellSize, grid.cellSize) then
                player.y = cell.y - player.radius
                player.yVelocity = 0
                player.onGround = true
            end
        end
    end

    if love.keyboard.isDown(player.jumpKey) and player.onGround then
        player.yVelocity = player.jumpForce
        player.onGround = false
    end
end

function love.draw()
    for i = 0, grid.cols - 1 do
        for j = 0, grid.rows - 1 do
            if grid.cells[i][j].on then
                love.graphics.rectangle("line", grid.cells[i][j].x, grid.cells[i][j].y, grid.cellSize, grid.cellSize)
            end
        end
    end
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("line", player.x, player.y, player.radius, player.radius)
    love.graphics.setColor(1, 1, 1)
end
