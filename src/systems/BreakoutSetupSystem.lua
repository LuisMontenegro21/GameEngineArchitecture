local Screen = require("src.Screen")

local BreakoutSetupSystem = { name = "breakoutSetup" }

local PADDLE_WIDTH = 96
local PADDLE_HEIGHT = 16
local PADDLE_BOTTOM_MARGIN = 40

local BALL_SIZE = 12
local BALL_SPEED_X = 220
local BALL_SPEED_Y = -220

local BRICK_ROWS = 5
local BRICK_COLUMNS = 10
local BRICK_WIDTH = 72
local BRICK_HEIGHT = 22
local BRICK_GAP_X = 8
local BRICK_GAP_Y = 8
local BRICK_TOP_MARGIN = 56

local BRICK_COLORS = {
    { 0.95, 0.35, 0.35 },
    { 0.95, 0.60, 0.25 },
    { 0.95, 0.85, 0.25 },
    { 0.35, 0.75, 0.45 },
    { 0.35, 0.55, 0.95 },
}

function BreakoutSetupSystem.setup(scene)
    local registry = scene.registry
    local paddleY = Screen.h - PADDLE_BOTTOM_MARGIN - PADDLE_HEIGHT
    local paddleX = (Screen.w - PADDLE_WIDTH) / 2

    registry:spawn({
        position = { x = paddleX, y = paddleY },
        size = { w = PADDLE_WIDTH, h = PADDLE_HEIGHT },
        velocity = { vx = 0, vy = 0 },
        paddle = {
            speed = 420,
            leftKey = "left",
            rightKey = "right",
            altLeftKey = "a",
            altRightKey = "d",
        },
        clampHorizontal = {},
        moves = {},
        renderShape = {},
    })

    registry:spawn({
        position = {
            x = (Screen.w - BALL_SIZE) / 2,
            y = paddleY - BALL_SIZE - 12,
        },
        size = { w = BALL_SIZE, h = BALL_SIZE },
        velocity = { vx = BALL_SPEED_X, vy = BALL_SPEED_Y },
        ball = {},
        moves = {},
        renderShape = {},
    })

    local gridWidth = BRICK_COLUMNS * BRICK_WIDTH
        + (BRICK_COLUMNS - 1) * BRICK_GAP_X
    local gridX = (Screen.w - gridWidth) / 2

    for row = 1, BRICK_ROWS do
        for column = 1, BRICK_COLUMNS do
            registry:spawn({
                position = {
                    x = gridX + (column - 1) * (BRICK_WIDTH + BRICK_GAP_X),
                    y = BRICK_TOP_MARGIN + (row - 1) * (BRICK_HEIGHT + BRICK_GAP_Y),
                },
                size = { w = BRICK_WIDTH, h = BRICK_HEIGHT },
                brick = {
                    row = row,
                    color = BRICK_COLORS[row],
                },
            })
        end
    end

    registry:setResource("breakout", {
        remainingBricks = BRICK_ROWS * BRICK_COLUMNS,
        status = "playing",
    })
end

return BreakoutSetupSystem
