_G.love = require("love")


function love.load()
    _G.number = 0
end


function love.update(dt)
    number = number + 1
end


function love.draw()
    love.graphics.print(number)
end