# System Module
module SystemModule

# Internal Packages 

# External Packages 

abstract type System end
export System

abstract type Message end
export Message

# Generic handle message
# If there is no dispatch match for system and message, this will run
function handle_message!(system::System, message::Message)
    error("System $(typeof(system)) can't handle Message $(typeof(message))")
end
export handle_message!

function is_subscribed(system::System, message::Message)
    return false
end
export is_subscribed

function is_whitelisted(system::System, message::Message)
    return false
end
export is_whitelisted

function is_blacklisted(system::System, message::Message)
    return false
end
export is_blacklisted

#
# Useful pre-defined Systems
#
"""
A system which contains other systems.
Assumed to have a `subsystems::Dict{String, <:System}` field.
"""
abstract type CompositeSystem <: System end
export CompositeSystem

function handle_message!(composite_system::CompositeSystem, message::Message)
    for system in values(composite_system.subsystems)
        if @invokelatest is_subscribed(system, message)
            handle_message!(system, message)
        end
    end
end

#
# Useful pre-defined Messages
#
"""
Message which tells a system to quit.
This usually means clearing any memory the system is taking up.
"""
Base.@kwdef mutable struct QuitMessage <: Message
    metadata::Dict{String, Any} = Dict{String, Any}()
end
export QuitMessage

"""
If a system is told to quit, run the quit function.
"""
function handle_message!(system::System, message::QuitMessage)
    quit(system)
end

"""
Most systems don't need to do anything when they quit.
"""
function quit(system::System) end

function handle_message!(composite_system::CompositeSystem, message::QuitMessage)
    quit.(values(composite_system.subsystems))
end

end
