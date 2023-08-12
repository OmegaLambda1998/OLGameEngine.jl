# Physics Module
module PhysicsModule

# Internal Packages 
using ..SystemModule
using ..GameModule

# External Packages 

abstract type PhysicsSystem <: System end
export PhysicsSystem

abstract type Hitbox <: PhysicsSystem end
export Hitbox

Base.@kwdef mutable struct PhysicsStepMessage <: Message
    dt::Float64
    metadata::Dict{String,Any} = Dict{String,Any}()
end
export PhysicsStepMessage

SystemModule.is_subscribed(system::PhysicsSystem, message::PhysicsStepMessage) = true

function SystemModule.handle_message!(system::PhysicsSystem, message::PhysicsStepMessage)
    step_physics!(system, message.dt)
end

function step_physics!(system::PhysicsSystem, dt::Float64) end
export step_physics!

Base.@kwdef mutable struct Physics2DObject <: PhysicsSystem
    width::Float64
    height::Float64
    x::Float64
    min_x::Float64 = 0.0
    max_x::Float64 = 1.0
    y::Float64
    min_y::Float64 = 0.0
    max_y::Float64 = 1.0
    dx::Float64 = 0.0
    min_dx::Float64 = 0.0
    max_dx::Float64 = 1.0
    dy::Float64 = 0.0
    min_dy::Float64 = 0.0
    max_dy::Float64 = 1.0
    ddx::Float64 = 0.0
    ddy::Float64 = 0.0
    bounciness::Float64 = 0.0
    friction::Float64 = 0.0
    hitboxes::Vector{Hitbox} = Vector{Hitbox}()
end
export Physics2DObject

function step_physics!(system::Physics2DObject, dt::Float64)
    # Update the velocity of the object
    Δdx = (system.ddx * dt) - (system.dx * system.friction)
    Δdy = (system.ddy * dt) - (system.dy * system.friction)
    dx = system.dx + Δdx
    dy = system.dy + Δdy

    if abs(dx) < system.min_dx
        dx = sign(dx) * system.min_dx
    elseif abs(dx) > system.max_dx
        dx = sign(dx) * system.max_dx
    end
    if abs(dy) < system.min_dy
        dy = sign(dy) * system.min_dy
    elseif abs(dy) > system.max_dy
        dy = sign(dy) * system.max_dy
    end

    # Update the position of the object
    Δx = dx * dt
    Δy = dy * dt
    x = system.x + Δx
    y = system.y + Δy

    # Handle edges
    if x < system.min_x
        x = system.min_x
        dx = -system.bounciness * dx
    elseif (x + system.width) > system.max_x
        x = (system.max_x - system.width)
        dx = -system.bounciness * dx
    end
    if y < system.min_y
        y = system.min_y
        dy = -system.bounciness * dy
    elseif (y + system.height) > system.max_y
        y = (system.max_y - system.height)
        dy = -system.bounciness * dy
    end
    system.x = x
    system.y = y
    system.dx = dx
    system.dy = dy
end

end
