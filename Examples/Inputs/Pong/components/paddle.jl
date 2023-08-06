#
# Event handler
#
mutable struct PaddleMovementHandler <: KeyHandler
    game::Game
    side::String
    moving_up::Bool
    moving_down::Bool
    targets::Vector{SDL_Scancode}
end

SystemModule.is_subscribed(system::PaddleMovementHandler, message::TickMessage) = true

function PaddleMovementHandler(game::Game, side::String)
    if side == "left"
        targets = Vector{SDL_Scancode}([SDL_SCANCODE_W, SDL_SCANCODE_S])
    else
        targets = Vector{SDL_Scancode}([SDL_SCANCODE_I, SDL_SCANCODE_K])
    end
    return PaddleMovementHandler(game, side, false, false, targets)
end

function InputModule.handle_event!(system::PaddleMovementHandler, event::SDL_Event)
    # We know that event can only be SDL_SCANCODE_[W, S, I, K]

    # event is SDL_SCANCODE_[W, I] so move paddle up
    if event.key.keysym.scancode == system.targets[1]
        if event.type == SDL_KEYDOWN
            system.moving_up = true
            system.moving_down = false
        else
            system.moving_up = false
        end
    else
        if event.type == SDL_KEYDOWN
            system.moving_up = false
            system.moving_down = true
        else
            system.moving_down = false
        end
    end
end

struct MoveUpMessage <: Message
    dt::Float64
    side::String
end

struct MoveDownMessage <: Message
    dt::Float64
    side::String
end

function SystemModule.handle_message!(system::PaddleMovementHandler, message::TickMessage)
    if system.moving_up
        send_important_message!(system.game, MoveUpMessage(message.dt, system.side))
    elseif system.moving_down
        send_important_message!(system.game, MoveDownMessage(message.dt, system.side))
    end
end

mutable struct Paddle <: EntitySystem
    game::Game
    side::String
    x::Float64
    y::Float64
    velocity::Float64
    width::Float64
    height::Float64
    subsystems::Dict{String,System}
end

function Paddle(game::Game, side::String)
    width = 0.015
    height = 0.15
    if side == "left"
        x = 2 * width
    else
        x = 1 - 3 * width
    end
    y = 0.5 - (height / 2)
    velocity = 3 * height
    renderer = Rectangle(game, x, y, width, height)
    movement_handler = PaddleMovementHandler(game, side)
    subsystems = Dict{String,System}("renderer" => renderer, "movement_handler" => movement_handler)
    return Paddle(game, side, x, y, velocity, width, height, subsystems)
end

SystemModule.is_subscribed(system::Paddle, message::EventMessage) = true
SystemModule.is_subscribed(system::Paddle, message::RenderMessage) = true
SystemModule.is_subscribed(system::Paddle, message::TickMessage) = true
SystemModule.is_subscribed(system::Paddle, message::MoveUpMessage) = true
SystemModule.is_subscribed(system::Paddle, message::MoveDownMessage) = true

function update_paddle!(paddle::Paddle)
    for field in fieldnames(Paddle)
        for system in values(paddle.subsystems)
            if field in fieldnames(typeof(system))
                setfield!(system, field, getfield(paddle, field))
            end
        end
    end
end

function SystemModule.handle_message!(paddle::Paddle, message::MoveUpMessage)
    if message.side == paddle.side
        move_up!(paddle, message.dt)
    end
end

function SystemModule.handle_message!(paddle::Paddle, message::MoveDownMessage)
    if message.side == paddle.side
        move_down!(paddle, message.dt)
    end
end

function move_up!(paddle::Paddle, dt::Float64)
    top_y = 0.048
    if (paddle.y - (paddle.velocity * dt)) <= (top_y + (paddle.velocity * dt))
        paddle.y = top_y
    else
        paddle.y = paddle.y - (paddle.velocity * dt)
    end
    update_paddle!(paddle::Paddle)
end

function move_down!(paddle::Paddle, dt::Float64)
    bottom_y = 1 - paddle.height
    if (paddle.y + (paddle.velocity * dt)) >= (bottom_y - (paddle.velocity * dt))
        paddle.y = bottom_y
    else
        paddle.y = paddle.y + (paddle.velocity * dt)
    end
    update_paddle!(paddle::Paddle)

end

function add_component(game::Game, side::String)
    paddle = Paddle(game, side)

    add_system!(game, "$(side)_paddle", paddle)
end
