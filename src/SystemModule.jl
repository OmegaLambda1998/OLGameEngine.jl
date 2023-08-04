# System Module
module SystemModule

# Internal Packages 

# External Packages 
using Dates

abstract type System end
export System

abstract type Message end
export Message

# Generic handle message
# If there is no dispatch match for system and message, this will run
function handle_message!(system::System, message::Message)
end
export handle_message!

struct QuitMessage <: Message end
export QuitMessage

end
