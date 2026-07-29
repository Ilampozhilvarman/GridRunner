local game
local player
local grid
local previewGrid

local function loadHighScore()
    if love.filesystem.getInfo("highscore.txt") then
        local contents = love.filesystem.read("highscore.txt")
        game.highScore = tonumber(contents) or 0
    end
end

local function saveHighScore()
    love.filesystem.write("highscore.txt", tostring(game.highScore))
end

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
        font = love.graphics.newFont(48),
        highScore = 0,
        paused = false,
        rebinding = nil,
        menuIndex = 1,
        actionOrder = {"jump", "left", "right", "retry", "new", "pause"}
    }
    player = {
        x = game.middle.x,
        y = game.middle.y,
        speed = 400,
        keyMaps = {
            jump = "space",
            left = "a",
            right = "d",
            retry = "r",
            new = "return",
            pause = "escape"
        },
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
    loadHighScore()
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
    game.gridInterval = 2
end

function love.update(dt)
    if game.paused then return end
    if game.dying then
        game.deathTimer = game.deathTimer + dt
        if game.deathTimer >= game.deathDuration then
            game.dying = false
            game.deathTimer = 0
            game.started = false
            if game.score > game.highScore then
                game.highScore = game.score
                saveHighScore()
            end
        end
        return
    end
    player.yVelocity = math.min(player.yVelocity + player.gravity * dt, 1000)
    if not game.started and love.keyboard.isDown(player.keyMaps.new) then
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
            if game.gridInterval - game.gridDecreaseTimeInterval > game.gridMinTimeInterval then
                game.gridInterval = game.gridInterval - game.gridDecreaseTimeInterval
            else
                game.gridInterval = game.gridMinTimeInterval
            end
        end
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
                    game.previewing = false
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
    if game.dying then return end
    local newX = player.x
    if player.keyMaps.left and love.keyboard.isDown(player.keyMaps.left) then
        newX = newX - player.speed * dt
    end
    if player.keyMaps.right and love.keyboard.isDown(player.keyMaps.right) then
        newX = newX + player.speed * dt
    end
    if game.dying then return end
    local blockedX = false
    for i = 0, grid.cols - 1 do
        for j = 0, grid.rows - 1 do
            local cell = grid.cells[i][j]
            if cell.on and checkCollision(newX, player.y, player.radius, player.radius, cell.x, cell.y, grid.cellSize, grid.cellSize) then
                if cell.danger and not game.dying and game.started then
                    game.dying = true
                    player.dead = true
                    game.previewing = false
                end
                blockedX = true
            end
        end
    end

    if not blockedX then
        player.x = newX
    end

    if player.keyMaps.jump and love.keyboard.isDown(player.keyMaps.jump) and player.onGround then
        player.yVelocity = player.jumpForce
        player.onGround = false
    end
end

function love.keypressed(key)
    -- if we're waiting for a new key to bind, capture it and stop
    if game.rebinding then
        if key == player.keyMaps.pause then
            game.rebinding = nil
            return
        end
        -- prevent binding two actions to the same key
        -- swap keys instead of leaving an action unbound
        local oldKey = player.keyMaps[game.rebinding]
        for action, boundKey in pairs(player.keyMaps) do
            if boundKey == key and action ~= game.rebinding then
                player.keyMaps[action] = oldKey
            end
        end
        player.keyMaps[game.rebinding] = key
        game.rebinding = nil
        return
    end

    if key == player.keyMaps.pause then
        game.paused = not game.paused
        return
    end

    if game.paused then
        if key == "down" then
            game.menuIndex = (game.menuIndex % #game.actionOrder) + 1
        elseif key == "up" then
            game.menuIndex = ((game.menuIndex - 2) % #game.actionOrder) + 1
        elseif key == "return" then
            game.rebinding = game.actionOrder[game.menuIndex]
        end
        return
    end

    if key == player.keyMaps.retry then
        reset()
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
        love.graphics.printf("Game over, press " .. (player.keyMaps.new or "unbound") .. " to try again.", game.middle.x - 450, game.middle.y - 50, 900, "center")
        love.graphics.printf("Score: " .. game.score, game.middle.x - 300, game.middle.y + 50, 600, "center")
        love.graphics.printf("High Score: " .. game.highScore, game.middle.x - 300, game.middle.y + 150, 600, "center")
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
    if game.paused then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, game.max.x, game.max.y)
        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.printf("Paused", game.middle.x - 300, game.middle.y - 220, 600, "center")

        for i, action in ipairs(game.actionOrder) do
            local y = game.middle.y - 140 + (i - 1) * 60
            local label = action .. ":  " .. (player.keyMaps[action] or "unbound")

            if i == game.menuIndex then
                love.graphics.setColor(1, 1, 0, 1)
                if game.rebinding == action then
                    label = action .. ":  press a key..."
                end
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.printf(label, game.middle.x - 300, y, 600, "center")
        end

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Up/Down to select, Enter to rebind, Esc to cancel", game.middle.x - 400, game.middle.y + 220, 800, "center")
    end
end
