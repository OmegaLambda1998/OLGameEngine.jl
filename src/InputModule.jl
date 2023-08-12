# Input Module
module InputModule

# Internal Packages 
using ..SystemModule

# External Packages 
using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2

abstract type InputMessage <: Message end
export InputMessage

"""
A message containing an SDL Event
"""
Base.@kwdef mutable struct EventMessage <: InputMessage
    event::SDL_Event
    metadata::Dict{String, Any} = Dict{String, Any}()
end
export EventMessage

function Base.show(io::IO, msg::EventMessage)
    event = msg.event
    event_type = event.type
    if event_type == SDL_KEYDOWN
        scan_code = event.key.keysym.scancode
        print(io, "$(typeof(msg)): $(string(scan_code))")
    else
        print(io, "$(typeof(msg)): $(string(event_type))")
    end
end

"""
A system which handles SDL events
Expected to have a field `targets::Vector{<:SDL_EventType}`
"""
abstract type EventHandlerSystem <: System end
export EventHandlerSystem

function SystemModule.is_subscribed(system::EventHandlerSystem, message::EventMessage)
    return true
end

"""
Handle generic SDL_Event's
"""
abstract type GenericEventHandler <: EventHandlerSystem end
export GenericEventHandler

function SystemModule.handle_message!(system::GenericEventHandler, message::EventMessage)
    if message.event.type in system.targets
        @invokelatest handle_event!(system, message.event)
    end
end

function handle_event!(system::GenericEventHandler, event::SDL_Event)
    error("System $(typeof(system)) does not have a handle_event! function for event $(event.type)")
end
export handle_event!

abstract type KeyHandler <: EventHandlerSystem end
export KeyHandler

function SystemModule.handle_message!(system::KeyHandler, message::EventMessage)
    if (message.event.type == SDL_KEYDOWN) || (message.event.type == SDL_KEYUP)
        if message.event.key.keysym.scancode in system.targets
            @invokelatest handle_event!(system, message.event)
        end
    end
end

function handle_event!(system::KeyHandler, event::SDL_Event)
    error("System $(typeof(system)) does not have a handle_event! function for event $(event.type)")
end

end
