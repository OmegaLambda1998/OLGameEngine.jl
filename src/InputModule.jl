# Input Module
module InputModule

# Internal Packages 
using ..SystemModule

# External Packages 
using CSFML 
using CSFML.LibCSFML 

abstract type InputMessage <: Message end
export InputMessage


"""
A message containing an SFML Event
"""
Base.@kwdef mutable struct EventMessage <: InputMessage
    event::sfEvent
    metadata::Dict{String, Any} = Dict{String, Any}()
end
export EventMessage

"""
A system which handles SFML events
Expected to have a field `targets::Vector{<:sfEventType}`
"""
abstract type EventHandlerSystem <: System end
export EventHandlerSystem

function SystemModule.is_subscribed(system::EventHandlerSystem, message::EventMessage)
    return true
end

"""
Handle generic sfEvent's
"""
abstract type GenericEventHandler <: EventHandlerSystem end
export GenericEventHandler

function SystemModule.handle_message!(system::GenericEventHandler, message::EventMessage)
    if message.event.type in system.targets
        @invokelatest handle_event!(system, message.event)
    end
end

function handle_event!(system::GenericEventHandler, event::sfEvent)
    error("System $(typeof(system)) does not have a handle_event! function for event $(event.type)")
end
export handle_event!

abstract type KeyHandler <: EventHandlerSystem end
export KeyHandler

function SystemModule.handle_message!(system::KeyHandler, message::EventMessage)
    if (message.event.type == sfEvtKeyPressed) || (message.event.type == sfEvtKeyReleased)
        if message.event.key.code in system.targets
            @invokelatest handle_event!(system, message.event)
        end
    end
end

function handle_event!(system::KeyHandler, event::sfEvent)
    error("System $(typeof(system)) does not have a handle_event! function for event $(event.type)")
end

end
