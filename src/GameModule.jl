# Game Module
module GameModule

# Internal Packages 
using ..ConstantsModule
using ..SystemModule

# External Packages 
using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2
using Colors

"""
Game objects contain the SDL window, the SDL renderer, a set of Systems, a message bus and whether the game has been quit or not 
"""
mutable struct Game
    window::Ptr{SDL_Window}
    renderer::Ptr{SDL_Renderer}
    systems::Dict{String,System}
    message_bus::Channel{Pair{Pair{DataType,DataType},Task}}
    render_bus::Dict{Int64,Vector{Function}}
    logs::Dict{String,AbstractString}
    quit::Bool
end
export Game

function Game(window::Ptr{SDL_Window}, renderer::Ptr{SDL_Renderer})
    return Game(window, renderer, Dict{String,System}(), Channel{Pair{Pair{DataType,DataType},Task}}(32), Dict{Int64,Channel{Task}}(), Dict{String,AbstractString}(), false)
end

function add_log!(game::Game, log_name::String, log_file::AbstractString)
    if isfile(log_file)
        rm(log_file)
    end
    touch(log_file)
    game.logs[log_name] = log_file
end
export add_log!

function log_message(game::Game, log_name::String, message::String; mode::String="a")
    if !(log_name in keys(game.logs))
        error("Log $log_name does not exist")
    end
    log_file = game.logs[log_name]
    open(log_file, mode) do io
        println(io, message)
    end
end
export log_message

function get_dimensions(game::Game)
    w_ref, h_ref = Ref{Cint}(0), Ref{Cint}(0)
    SDL_GetWindowSize(game.window, w_ref, h_ref)
    return w_ref[], h_ref[]
end
export get_dimensions

function get_centre(game::Game)
    width, height = get_dimensions(game)
    return width ÷ 2, height ÷ 2
end
export get_centre

"""
Add a System to game
"""
function add_system!(game::Game, name::String, system::System)
    game.systems[name] = system
end
export add_system!

"""
Get a System from game
"""
function get_system(game::Game, name::String)
    if !(name in keys(game.systems))
        error("System $name does not exist")
    end
    return game.systems[name]
end
export get_system

"""
Send a message to all game Systems
"""
function send_message!(game::Game, message::Message)
    for system in values(game.systems)
        send_message!(game, message, system)
    end
end
export send_message!

"""
Send a message to a specific game system 
"""
function send_message!(game::Game, message::Message, system::System)
    task = @task handle_message!(system, message)
    put!(game.message_bus, (typeof(system) => typeof(message)) => task)
end

function send_important_message!(game::Game, message::Message)
    for system in values(game.systems)
        send_important_message!(message, system)
    end
end
export send_important_message!

function send_important_message!(message::Message, system::System)
    handle_message!(system, message)
end

function add_render_task!(game::Game, task::Function, zorder::Int64)
    if !(zorder in keys(game.render_bus))
        game.render_bus[zorder] = Vector{Function}()
    end
    push!(game.render_bus[zorder], task)
end
export add_render_task!

end
