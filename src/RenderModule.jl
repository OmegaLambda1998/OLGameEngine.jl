# Render Module
module RenderModule

# Internal Packages 
using ..ConstantsModule
using ..SystemModule
using ..GameModule

# External Packages 
using CSFML
using CSFML.LibCSFML
using Colors
using Base.Threads

"""
A message which tells Renderable objects to render themselves
"""
Base.@kwdef mutable struct RenderMessage <: Message
    metadata::Dict{String,Any} = Dict{String,Any}()
end
export RenderMessage

"""
A system which renders to the screen
"""
abstract type RenderableSystem <: System end
export RenderableSystem

function SystemModule.is_subscribed(::RenderableSystem, ::RenderMessage)
    return true
end

"""
If a system is renderable, render it
"""
function SystemModule.handle_message!(system::RenderableSystem, message::RenderMessage)
    render(system, message.metadata["GAME"])
end

"""
By default nothing needs to happen when quitting a RenderableSystem
"""
function quit(::RenderableSystem) end
export quit

"""
If an object is renderable it should have it's own render function defined. If it doesn't this error will be called.
"""
function render(system::RenderableSystem, ::Game)
    error("System: $system is Renderable but does not have a render function defined.")
end

#
# COMPOSITE RENDER
#

Base.@kwdef mutable struct CompositeRender <: CompositeSystem
    subsystems::Vector{RenderableSystem}
end
export CompositeRender

function SystemModule.is_subscribed(::CompositeRender, ::RenderMessage)
    return true
end

function render(composite_system::CompositeRender, game::Game)
    for system in composite_system.subsystems
        render(system, game)
    end
end

# Include all primitives
primitives_dir = joinpath(@__DIR__, "Primitives")
for file in readdir(primitives_dir)
    file = joinpath(primitives_dir, file)
    if isfile(file)
        include(file)
    end
end


end
