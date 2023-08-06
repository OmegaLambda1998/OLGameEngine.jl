# Clock Module
module ClockModule

# Internal Packages 

# External Packages 
using ..SystemModule

abstract type ClockMessage <: Message end
export ClockMessage

mutable struct TickMessage <: ClockMessage
    dt::Float64 # The amount of time since the last tick in seconds
end
export TickMessage

end
