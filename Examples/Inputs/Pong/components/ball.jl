mutable struct BallStartHandler <: KeyHandler
    game::Game
    targets::Vector{sfKeyCode}
end

function BallStartHandler(game::Game)
    targets = Vector{sfKeyCode}([sfKeySpace])
    return BallStartHandler(game, targets)
end

function InputModule.handle_event!(system::BallStartHandler, ::sfEvent)
    ball = get_system(system.game, "ball")
    physics = get_physics(ball)
    if physics.dy + physics.dx == 0
        physics.dy = ball.velocity
        physics.dx = 0.8 * ball.velocity
    end
end

mutable struct Ball <: EntitySystem
    game::Game
    velocity::Float64
    subsystems::Dict{String,System}
end

SystemModule.is_subscribed(system::Ball, message::EventMessage) = true
SystemModule.is_subscribed(system::Ball, message::RenderMessage) = true
SystemModule.is_subscribed(system::Ball, message::PhysicsStepMessage) = true

function Ball(game::Game)
    radius = 0.015
    outline = 0.1
    x = 0.5 - radius
    y = (0.5 + (0.5 * 0.078)) - radius
    velocity = 10.0 * radius
    renderer = Circle(x, y, radius; zorder=2, outline_thickness=-outline, outline_colour=colorant"grey")
    movement_physics_handler = Physics2DObject(width=radius, height=radius, x=x, y=y, min_x=0.0, max_x=1.0, min_y=0.048, max_y=1.0, bounciness=1.0)
    input_handler = BallStartHandler(game)
    subsystems = Dict{String,System}("renderer" => renderer, "physics" => movement_physics_handler, "input" => input_handler)
    return Ball(game, velocity, subsystems)
end

function get_renderer(ball::Ball)
    return ball.subsystems["renderer"]
end

function get_physics(ball::Ball)
    return ball.subsystems["physics"]
end

function SystemModule.handle_message!(ball::Ball, message::PhysicsStepMessage)
    handle_message!(get_physics(ball), message)
    update_ball!(ball)
end

function update_ball!(ball::Ball)
    physics_object = get_physics(ball)
    renderer = get_renderer(ball)
    sfShape_setPosition(renderer.shape, sfVector2f(physics_object.x, physics_object.y))
end

function add_component(game::Game)
    ball = Ball(game)
    add_system!(game, "ball", ball)
end
