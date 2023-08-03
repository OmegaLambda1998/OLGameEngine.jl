# System Module
module SystemModule

# Internal Packages 

# External Packages 
using Dates

# Exports
export System
export Message
export handle_message!
export QuitMessage


abstract type System end

abstract type Message end

# Generic handle message
# If there is no dispatch match for system and message, this will run
function handle_message!(system::System, message::Message)
end

struct QuitMessage <: Message end

end
