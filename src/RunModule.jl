module RunModule

# Internal Packages
include("ConstantsModule.jl")
using .ConstantsModule
include("SystemModule.jl")
using .SystemModule
include("ClockModule.jl")
using .ClockModule
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
using CSFML
using CSFML.LibCSFML
using Colors

"""
Setup everything needed, including the Window, the Renderer, and the Game object
"""
function setup(toml::Dict{String,Any})
    @debug "Running with $(Threads.nthreads()) Threads."
    @info "Setting Window Styles"

    @info "Creating Window"
    window_opts = get(toml, "WINDOW", Dict{String,Any}())
    title = get(toml, "TITLE", "OLGameEngine")
    @debug "Window title: $title"
    width = get(window_opts, "WIDTH", 1000)
    @debug "Window width: $width"
    height = get(window_opts, "HEIGHT", 1000)
    @debug "Window height: $height"
    bits_per_pixel = get(window_opts, "BITS_PER_PIXEL", 32)
    @debug "Window bits per pixel: $bits_per_pixel"
    style_str = get(window_opts, "STYLE", ["sfDefaultStyle"])
    style = reduce(|, map(s -> str_to_attr[s], style_str))
    mode = sfVideoMode(width, height, bits_per_pixel)
    window = sfRenderWindow_create(mode, title, style, C_NULL)

    @info "Creating Game"
    game_opts = get(toml, "GAME", Dict{String,Any}())
    background_colour = parse(Colorant, get(game_opts, "BACKGROUND_COLOUR", "black"))
    target_fps = get(game_opts, "TARGET_FPS", 0)
    if target_fps > 0
        @debug "Targeting $target_fps FPS"
        sfRenderWindow_setFramerateLimit(window, target_fps)
    end
    game = Game(window=window, background_colour=background_colour, target_fps=target_fps)

    message_log = joinpath(toml["GLOBAL"]["OUTPUT_PATH"], "messages.log")
    add_log!(game, "message_log", message_log)

    @info "Preparing Components"
    components = get(game_opts, "COMPONENTS", Dict{String,Any}())
    for (component_name, component_opts) in components
        component_file = component_opts["FILE"]
        component_args = get(component_opts, "ARGS", Vector{Any}())
        component_kwargs = get(component_opts, "KWARGS", Dict{String,Any}())

        if !isabspath(component_file)
            component_file = joinpath(toml["GLOBAL"]["INPUT_PATH"], component_file)
        end
        component_file = abspath(component_file)
        @debug "Adding Component: $component_name from file $component_file"
        if isfile(component_file)
            include(component_file)
            @invokelatest add_component(game, component_args...; component_kwargs...)
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
    r, g, b = colorant_to_rgb(game.background_colour)
    sfRenderWindow_clear(game.window, sfColor_fromRGB(r, g, b))
end

"""
Read inputs and send `EventMessage`
"""
function input_stage(game::Game)
    quit = false
    event_ref = Ref{sfEvent}()
    while Bool(sfRenderWindow_pollEvent(game.window, event_ref))
        evt = event_ref[]
        evt_ty = evt.type
        # Handle quitting
        if (evt_ty == sfEvtClosed)
            quit = true
            break
        else
            send_important_message!(game, EventMessage(event=evt))
        end
    end
    return quit
end

"""
Handle physics
"""
function physics_stage(game::Game, dt::sfTime)
    send_important_message!(game, PhysicsStepMessage(dt=dt))
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
Handle Audio
"""
function audio_stage(game::Game)
end

"""
Handle GUI updates
"""
function gui_stage(game::Game)
end

"""
Render everything (including gui) to the render buffer
"""
function render_stage(game::Game)
    send_important_message!(game, RenderMessage())
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
    sfRenderWindow_display(game.window)
end

"""
Continuously schedule the latest task in the message bus
"""
function handle_all_messages!(game::Game)
    while true
        (system, message), task = take!(game.message_bus)
        errormonitor(Threads.@spawn task())
    end
end

"""
Main game loop
"""
function main_loop(game::Game)
    try
        errormonitor(Threads.@spawn handle_all_messages!(game))
        clock = sfClock_create()
        while !game.quit
            elapsed = sfClock_restart(clock)
            prep_stage(game)
            game.quit = input_stage(game)
            physics_stage(game, elapsed)
            world_stage(game)
            ai_stage(game)
            audio_stage(game)
            render_stage(game)
            gui_stage(game)
            draw_stage(game)
            fps = (1.0 / sfTime_asSeconds(elapsed))
            print("\e[2K")
            print("\e[1G")
            print("FPS: $(fps)")
            #break
        end
    finally
        @info "Quitting"
        send_important_message!(game, QuitMessage())
        sfRenderWindow_destroy(game.window)
    end
end

function run_OLGameEngine(toml::Dict)
    game = setup(toml)
    @sync main_loop(game)
end
export run_OLGameEngine

end
