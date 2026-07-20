local game
local player
local grid
function love.load()
    game = {
        middle = {
            x = love.graphics.getWidth() / 2,
            y = love.graphics.getHeight() / 2,
        },
        score = 0
    }
    player = {
        x = game.middle.x,
        y = game.middle.y,
        speed = 20,
        jumpKey = "space",
        leftKey = "a",
        rightKey = "d",
    }
    grid = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
        cellSize = 30,
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

local function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
        x1 + w1 > x2 and
        y1 < y2 + h2 and
        y1 + h1 > y2
end

function love.update(dt)

end

function love.draw()
    for i = 0, grid.cols - 1 do
        for j = 0, grid.rows - 1 do
            if grid.cells[i][j].on then
                love.graphics.rectangle("line", grid.cells[i][j].x, grid.cells[i][j].y, grid.cellSize, grid.cellSize)
            end
        end
    end
end
