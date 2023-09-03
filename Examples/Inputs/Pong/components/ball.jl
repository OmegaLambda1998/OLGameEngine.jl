mutable struct Ball <: EntitySystem
    game::Game
    subsystems::Dict{String,System}
end

SystemModule.is_subscribed(system::Ball, message::EventMessage) = true
SystemModule.is_subscribed(system::Ball, message::RenderMessage) = true
SystemModule.is_subscribed(system::Ball, message::PhysicsStepMessage) = true

function Ball(game::Game)
    radius = 0.025
    width = radius * 2.0
    height = radius * 2.0
    x = 0.5 - radius
    y = 0.5 - radius
    renderer = CircleRender(x=x, y=y, radius=radius)
    movement_physics_handler = Physics2DObject(width=width, height=height, x=x, y=y, min_y=0.048, max_y=1.0, dx=0.1, dy=0.2, bounciness = 1.0)
    subsystems = Dict{String,System}("renderer" => renderer, "movement_physics_handler" => movement_physics_handler)
    return Ball(game, subsystems)
end

function get_physics(ball::Ball)
    return ball.subsystems["movement_physics_handler"]
end

function get_input(ball::Ball)
    return ball.subsystems["movement_input_handler"]
end

function get_renderer(ball::Ball)
    return ball.subsystems["renderer"]
end


function SystemModule.handle_message!(ball::Ball, message::PhysicsStepMessage)
    physics_object = get_physics(ball)
    handle_message!(physics_object, message)
    update_ball!(ball)
end

function update_ball!(ball::Ball)
    physics_object = get_physics(ball)
    renderer = get_renderer(ball)
    renderer.x = physics_object.x
    renderer.y = physics_object.y
    renderer.width = physics_object.width
    renderer.height = physics_object.height
end

function add_component(game::Game)
    ball = Ball(game)
    add_system!(game, "ball", ball)
end
