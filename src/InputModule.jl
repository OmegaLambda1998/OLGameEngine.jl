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
struct EventMessage <: InputMessage
    event::SDL_Event
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


end
