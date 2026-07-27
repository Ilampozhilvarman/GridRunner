local game
local player
local grid
local previewGrid
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
        gridInterval = 2,
        gridDecreaseTimeInterval = 0.1,
        gridMinTimeInterval = 0.5,
        dying = false,
        deathTimer = 0,
        deathDuration = 1,
        previewTime = 1,
        previewing = true,
        font = love.graphics.newFont(48)
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
    previewGrid = {
        cols = grid.cols,
        rows = grid.rows,
        cells = {}
    }
    for i = 0, grid.cols - 1 do
        previewGrid.cells[i] = previewGrid.cells[i] or {}
        for j = 0, grid.rows - 1 do
            previewGrid.cells[i][j] = {
                x = grid.cells[i][j].x,
                y = grid.cells[i][j].y,
                on = false,
                danger = false
            }
        end
    end
    print(grid.width)
    print(grid.height)
end

local function randomizeGrid(targetGrid)
    for i = 0, targetGrid.cols - 1 do
        for j = 0, targetGrid.rows - 1 do
            local isOn = math.random() < 0.3
            targetGrid.cells[i][j].on = isOn
            targetGrid.cells[i][j].danger = isOn and math.random() < 0.3
        end
    end
end

local function applyPreview()
    for i = 0, grid.cols - 1 do
        for j = 0, grid.rows - 1 do
            grid.cells[i][j].on = previewGrid.cells[i][j].on
            grid.cells[i][j].danger = previewGrid.cells[i][j].danger
        end
    end
end

local function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
        x1 + w1 > x2 and
        y1 < y2 + h2 and
        y1 + h1 > y2
end

local function resolveEmbeddedPlayer()
    for i = 0, grid.cols - 1 do
        for j = 0, grid.rows - 1 do
            local cell = grid.cells[i][j]
            if cell.on and checkCollision(player.x, player.y, player.radius, player.radius, cell.x, cell.y, grid.cellSize, grid.cellSize) then
                -- overlap depth on each axis
                local overlapLeft = (player.x + player.radius) - cell.x
                local overlapRight = (cell.x + grid.cellSize) - player.x
                local overlapTop = (player.y + player.radius) - cell.y
                local overlapBottom = (cell.y + grid.cellSize) - player.y

                local minX = math.min(overlapLeft, overlapRight)
                local minY = math.min(overlapTop, overlapBottom)

                if minX < minY then
                    if overlapLeft < overlapRight then
                        player.x = cell.x - player.radius
                    else
                        player.x = cell.x + grid.cellSize
                    end
                else
                    if overlapTop < overlapBottom then
                        player.y = cell.y - player.radius
                        player.yVelocity = 0
                        player.onGround = true
                    else
                        player.y = cell.y + grid.cellSize
                        player.yVelocity = 0
                    end
                end
            end
        end
    end
end

local function reset()
    game.score = 0
    game.started = false
    game.dying = false
    game.deathTimer = 0
    game.previewing = false
    game.gridTimer = 0
    player.x = game.middle.x
    player.y = game.middle.y
    player.yVelocity = 0
    player.onGround = true
    player.dead = false
end

function love.update(dt)
    if game.dying then
        game.deathTimer = game.deathTimer + dt
        if game.deathTimer >= game.deathDuration then
            game.dying = false
            game.deathTimer = 0
            game.started = false
        end
        return
    end
    player.yVelocity = math.min(player.yVelocity + player.gravity * dt, 1000)
    if not game.started and love.keyboard.isDown("lshift") then
        reset()
        player.onGround = false
        game.started = true
        randomizeGrid(grid)
    end

    if game.started then
        game.gridTimer = game.gridTimer + dt

        if not game.previewing and game.gridTimer >= (game.gridInterval - game.previewTime) then
            game.previewing = true
            randomizeGrid(previewGrid)
        end

        if game.gridTimer >= game.gridInterval then
            game.gridTimer = game.gridTimer - game.gridInterval
            applyPreview()
            resolveEmbeddedPlayer()
            game.previewing = false
            game.score = game.score + 1
            if game.gridTimer - game.gridDecreaseTimeInterval < game.gridMinTimeInterval then
                game.gridTimer = game.gridTimer - game.gridDecreaseTimeInterval
            end
        end
    end

    if not game.started and love.keyboard.isDown("r") then
        reset()
    end
    player.y = player.y + player.yVelocity * dt

    if player.x > game.max.x or player.x < 0 or player.y > game.max.y or player.y < 0 then
        if game.started and not game.dying then
            game.dying = true
            player.dead = true
            game.previewing = false
        end
    end
    --local ground = 300
    for i = 0, grid.cols - 1 do
        for j = 0, grid.rows - 1 do
            local cell = grid.cells[i][j]
            if cell.on and checkCollision(player.x, player.y, player.radius, player.radius, cell.x, cell.y, grid.cellSize, grid.cellSize) then
                if cell.danger and not game.dying and game.started then
                    game.dying = true
                    player.dead = true
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
                if cell.danger and not game.dying and game.started then
                    game.dying = true
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
    love.graphics.setFont(game.font)
    if game.started or game.dying then
        for i = 0, grid.cols - 1 do
            for j = 0, grid.rows - 1 do
                if grid.cells[i][j].on then
                    if grid.cells[i][j].danger then
                        love.graphics.setColor(1, 0, 0)
                    else
                        love.graphics.setColor(0.8, 0.8, 0.8)
                    end
                    love.graphics.rectangle("fill", grid.cells[i][j].x, grid.cells[i][j].y, grid.cellSize, grid.cellSize)
                end
            end
        end
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", player.x, player.y, player.radius, player.radius)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.printf("Game over, press lshift to try again.", game.middle.x - 450, game.middle.y - 50, 900, "center")
        love.graphics.printf("Score: " .. game.score, game.middle.x - 300, game.middle.y + 50, 600, "center")
    end

    if game.dying then
        local flashOn = math.floor(game.deathTimer / 0.1) % 2 == 0
        if flashOn then
            love.graphics.setColor(1, 0, 0, 0.6)
            love.graphics.rectangle("fill", 0, 0, game.max.x, game.max.y)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

    if game.previewing then
        for i = 0, previewGrid.cols - 1 do
            for j = 0, previewGrid.rows - 1 do
                local pCell = previewGrid.cells[i][j]
                if pCell.on then
                    if pCell.danger then
                        love.graphics.setColor(1, 0, 0, 0.25)
                    else
                        love.graphics.setColor(0.8, 0.8, 0.8, 0.25)
                    end
                    love.graphics.rectangle("fill", pCell.x, pCell.y, grid.cellSize, grid.cellSize)
                end
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
    end
end
