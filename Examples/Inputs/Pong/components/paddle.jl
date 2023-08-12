#
# Event handler
#
mutable struct PaddleMovementHandler <: KeyHandler
    game::Game
    side::String
    targets::Vector{SDL_Scancode}
end

function PaddleMovementHandler(game::Game, side::String)
    if side == "left"
        targets = Vector{SDL_Scancode}([SDL_SCANCODE_W, SDL_SCANCODE_S])
    else
        targets = Vector{SDL_Scancode}([SDL_SCANCODE_I, SDL_SCANCODE_K])
    end
    return PaddleMovementHandler(game, side, targets)
end

function InputModule.handle_event!(system::PaddleMovementHandler, event::SDL_Event)
    paddle = get_system(system.game, "$(system.side)_paddle")
    # We know that event can only be SDL_SCANCODE_[W, S, I, K]

    # event is SDL_SCANCODE_[W, I] so move paddle up
    if event.key.keysym.scancode == system.targets[1]
        if event.type == SDL_KEYDOWN
            paddle.moving_up = true
            paddle.moving_down = false
        else
            paddle.moving_up = false
        end
    else
        if event.type == SDL_KEYDOWN
            paddle.moving_up = false
            paddle.moving_down = true
        else
            paddle.moving_down = false
        end
    end
end

mutable struct Paddle <: EntitySystem
    game::Game
    side::String
    moving_up::Bool
    moving_down::Bool
    velocity::Float64
    subsystems::Dict{String,System}
end

function Paddle(game::Game, side::String)
    width = 0.015
    height = 0.15
    if side == "left"
        x = 2.0 * width
    else
        x = 1.0 - 3.0 * width
    end
    y = 0.5 - (height / 2.0)
    velocity = 4.0 * height
    renderer = RectangleRender(game, x, y, width, height)
    movement_input_handler = PaddleMovementHandler(game, side)
    movement_physics_handler = Physics2DObject(width=width, height=height, x=x, y=y, min_y=0.048, max_y=1.0)
    subsystems = Dict{String,System}("renderer" => renderer, "movement_input_handler" => movement_input_handler, "movement_physics_handler" => movement_physics_handler)
    return Paddle(game, side, false, false, velocity, subsystems)
end

function get_physics(paddle::Paddle)
    return paddle.subsystems["movement_physics_handler"]
end

function get_input(paddle::Paddle)
    return paddle.subsystems["movement_input_handler"]
end

function get_renderer(paddle::Paddle)
    return paddle.subsystems["renderer"]
end

SystemModule.is_subscribed(system::Paddle, message::EventMessage) = true
SystemModule.is_subscribed(system::Paddle, message::RenderMessage) = true
SystemModule.is_subscribed(system::Paddle, message::PhysicsStepMessage) = true

function SystemModule.handle_message!(paddle::Paddle, message::PhysicsStepMessage)
    physics_object = get_physics(paddle)
    if paddle.moving_up
        physics_object.dy = -paddle.velocity
    elseif paddle.moving_down
        physics_object.dy = paddle.velocity
    else
        physics_object.dy = 0.0
    end
    handle_message!(physics_object, message)
    update_paddle!(paddle)
end

function update_paddle!(paddle::Paddle)
    physics_object = get_physics(paddle)
    renderer = get_renderer(paddle)
    renderer.x = physics_object.x
    renderer.y = physics_object.y
    renderer.width = physics_object.width
    renderer.height = physics_object.height
end

function set_velocity!(paddle::Paddle, velocity::Float64)
    get_physics(paddle).dy = velocity
end

function add_component(game::Game, side::String)
    paddle = Paddle(game, side)

    add_system!(game, "$(side)_paddle", paddle)
end
