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
        jumpKey = "lshift"
    }
    grid = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
        CellSize = {
            radius = 30
        },
        cells = {}
    }
    print(grid.width)
    print(grid.height)
end

function love.update(dt)

end

function love.draw()
    for i = 1, grid.width / grid.CellSize.radius do
        for j = 1, grid.height / grid.CellSize.radius do
            love.graphics.rectangle("line", i * grid.CellSize.radius, j * grid.CellSize.radius, grid.CellSize.radius, grid.CellSize.radius)
        end
    end
end
