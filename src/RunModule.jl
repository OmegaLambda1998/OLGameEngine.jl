module RunModule

# Internal Packages
include("ConstantsModule.jl")
using .ConstantsModule
include("SystemModule.jl")
using .SystemModule
include("GameModule.jl")
using .GameModule
include("InputModule.jl")
using .InputModule
include("PhysicsModule.jl")
using .PhysicsModule
include("AIModule.jl")
using .AIModule
include("AudioModule.jl")
using .AudioModule
include("RenderModule.jl")
using .RenderModule
include("WorldModule.jl")
using .WorldModule
include("GUIModule.jl")
using .GUIModule
include("EntityModule.jl")
using .EntityModule

# External Packages
using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2
using Colors

"""
Setup everything needed, including the Window, the Renderer, and the Game object
"""
function setup(toml::Dict{String,Any})
    @info "Setting SDL attributes"
    attributes = get(toml, "ATTRIBUTES", Dict{String,Any}())
    for (attribute, value) in attributes
        @debug "Setting $attribute to $value"
        SDL_GL_SetAttribute(attribute, value)
    end

    @info "Initialising"
    @assert SDL_Init(SDL_INIT_EVERYTHING) == 0 "error initializing SDL: $(unsafe_string(SDL_GetError()))"

    @info "Creating Window"
    window_opts = get(toml, "WINDOW", Dict{String,Any}())
    str_to_win = Dict{String,Any}(
        "centered" => SDL_WINDOWPOS_CENTERED,
        "undefined" => SDL_WINDOWPOS_UNDEFINED,
    )
    name = get(window_opts, "NAME", "OLGameEngine")
    @debug "Window name: $name"
    x = get(window_opts, "X", "centered")
    if x isa String
        x = str_to_win[x]
    end
    @debug "Window x: $x"
    y = get(window_opts, "Y", "centered")
    if y isa String
        y = str_to_win[y]
    end
    @debug "Window y: $y"
    w = get(window_opts, "WIDTH", 1000)
    @debug "Window w: $w"
    h = get(window_opts, "HEIGHT", 1000)
    @debug "Window h: $h"
    win = SDL_CreateWindow(name, x, y, w, h, SDL_WINDOW_SHOWN)
    resizable = get(window_opts, "RESIZABLE", true)
    if resizable
        @debug "Resizable window"
        SDL_SetWindowResizable(win, SDL_TRUE)
    end

    @info "Creating Renderer"
    render_opts = get(toml, "RENDERER", Dict{String,Any}())
    flags = get(render_opts, "FLAGS", Vector{String}())
    render_flags = reduce(|, map(k -> str_to_flag[k], flags))
    renderer = SDL_CreateRenderer(win, -1, render_flags)

    @info "Setting Hints"
    hints = get(toml, "HINTS", Dict{String,Any}())
    for (hint, value) in hints
        SDL_SetHint(hint, value)
    end


    @info "Creating Game"
    game_opts = get(toml, "GAME", Dict{String,Any}())
    game = Game(win, renderer)

    message_log = joinpath(toml["GLOBAL"]["OUTPUT_PATH"], "messages.log")
    add_log!(game, "message_log", message_log)

    @info "Preparing Components"
    components = get(game_opts, "COMPONENTS", Dict{String,Any}())
    for (component_name, component_file) in components

        if !isabspath(component_file)
            component_file = joinpath(toml["GLOBAL"]["INPUT_PATH"], component_file)
        end
        component_file = abspath(component_file)
        @debug "Adding Component: $component_name from file $component_file"
        if isfile(component_file)
            include(component_file)
            @invokelatest add_component(game)
        else
            error("Component file $component_file does not exist")
        end
    end

    @info "Finished Setup"

    return game
end

"""
Clear the render buffer and prepare for the next frame
"""
function prep_stage(game::Game)
    SDL_RenderClear(game.renderer)
end

"""
Read inputs and send `EventMessage`
"""
function input_stage(game::Game)
    quit = false
    event_ref = Ref{SDL_Event}()
    while Bool(SDL_PollEvent(event_ref))
        evt = event_ref[]
        evt_ty = evt.type
        # Handle quitting
        if (evt_ty == SDL_QUIT)
            quit = true
            break
        else
            msg = EventMessage(evt)
            send_message!(game, msg)
        end
    end
    return quit
end

"""
Handle physics
"""
function physics_stage(game::Game)
end

"""
Handle world changes
"""
function world_stage(game::Game)
end

"""
Handle AI
"""
function ai_stage(game::Game)
end

"""
Render everything to the render buffer
"""
function render_stage(game::Game)
    send_important_message!(game, RenderMessage(game))
end

"""
Handle Audio
"""
function audio_stage(game::Game)
end

"""
Draw the render buffer
"""
function draw_stage(game::Game)
    for zorder in sort(collect(keys(game.render_bus)))
        render_bus = game.render_bus[zorder]
        while length(render_bus) > 0
            task = pop!(render_bus)
            task()
        end
    end
    SDL_RenderPresent(game.renderer)
end

"""
Continuously schedule the latest task in the message bus
"""
function handle_all_messages!(game::Game)
    while true
        (system, message), task = take!(game.message_bus)
        errormonitor(schedule(task))
    end
end

"""
Main game loop
"""
function main_loop(game::Game)
    try
        errormonitor(@async handle_all_messages!(game))
        while !game.quit
            prep_stage(game)
            game.quit = input_stage(game)
            physics_stage(game)
            world_stage(game)
            ai_stage(game)
            audio_stage(game)
            render_stage(game)
            draw_stage(game)
        end
    finally
        @info "Quitting"
        send_important_message!(game, QuitMessage())
        SDL_DestroyRenderer(game.renderer)
        SDL_DestroyWindow(game.window)
        SDL_Quit()
    end
end

function run_OLGameEngine(toml::Dict)
    game = setup(toml)
    @sync main_loop(game)
end
export run_OLGameEngine

end
