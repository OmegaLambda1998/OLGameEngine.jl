module RunModule

# External Packages
using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2
using Colors

# Internal Packages
include("GameModule.jl")
using .GameModule

# Exports
export run_OLGameEngine

include("Constants.jl")

function Base.convert(::Type{SDL_GLattr}, attr_name::AbstractString)
    try
        return str_to_attr[attr_name] # Defined in Constants.jl
    catch e
        if isa(e, KeyError)
            throw(ErrorException("Unknown SDL attribute $attr_name."))
        else
            throw(e)
        end
    end
end

function setup(toml::Dict)
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
        "underfined" => SDL_WINDOWPOS_UNDEFINED,
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
    w = get(window_opts, "W", 1000)
    @debug "Window w: $w"
    h = get(window_opts, "H", 1000)
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
    background = parse(Colorant, (get(game_opts, "BACKGROUND", "#000000")))
    @debug "Background: $background"
    game = Game(win, renderer, background)
    return game
end

function prep_scene(game::Game)
    SDL_SetRenderDrawColor(game.renderer, colorant_to_rgb(game.background)..., 255)
    SDL_RenderClear(game.renderer)
end

function eval_input(game::Game)
    close = false
    event_ref = Ref{SDL_Event}()
    while Bool(SDL_PollEvent(event_ref))
        evt = event_ref[]
        evt_ty = evt.type
        # Handle quitting
        if (evt_ty == SDL_QUIT)
            close = true
            break
        end
    end
    return close
end

function present_scene(game::Game)
    SDL_RenderPresent(game.renderer)
end

function main_loop(game::Game)
    try
        close = false
        while !close
            prep_scene(game)
            close = eval_input(game)
            if close
                break
            end
            present_scene(game)
            SDL_Delay(16)
        end
    finally
        SDL_DestroyRenderer(game.renderer)
        SDL_DestroyWindow(game.window)
        SDL_Quit()
    end
end

function run_OLGameEngine(toml::Dict)
    game = setup(toml)
    main_loop(game)
end
end
