# Clock Module
module ClockModule

# Internal Packages 

# External Packages 
using ..SystemModule

abstract type ClockMessage <: Message end
export ClockMessage

Base.@kwdef mutable struct TickMessage <: ClockMessage
    dt::Float64 # The amount of time since the last tick in seconds
    metadata::Dict{String,Any} = Dict{String,Any}()
end
export TickMessage

end
