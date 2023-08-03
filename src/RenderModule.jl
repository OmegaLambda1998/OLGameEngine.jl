# Render Module
module RenderModule

# Internal Packages 
using ..SystemModule
using ..GameModule

# External Packages 
using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2
using Colors

# Exports
export RenderMessage
export render
export Image
export BackgroundImage

abstract type RenderableSystem <: System end

"""
A message which tells Renderable objects to render themselves
"""
struct RenderMessage <: Message
    game::Game
end

function Base.show(io::IO, message::RenderMessage)
    print(io, "RenderMessage")
end

"""
If a system is renderable, render it
"""
function SystemModule.handle_message!(system::RenderableSystem, message::RenderMessage)
    log_message(message.game, "message_log", "$message -> $system")
    render(system, message.game)
end

function SystemModule.handle_message!(system::RenderableSystem, message::QuitMessage)
    quit(system)
end

"""
If an object is renderable it should have it's own render function defined. If it doesn't this error will be called.
"""
function render(system::RenderableSystem, game::Game)
    error("System: $system is Renderable but does not have a render function defined.")
end

mutable struct Image <: RenderableSystem
    texture::Ptr{SDL_Texture}
    zorder::Int64
    x::Float64
    y::Float64
    width::Float64
    height::Float64
    dest_ref::Base.RefValue{SDL_Rect}
end

function Base.show(io::IO, system::Image)
    print(io, "Image")
end

function quit(image::Image)
    SDL_DestroyTexture(image.texture)
end

function get_dest_ref(game::Game, x, y, width, height)
    window_width, window_height = get_dimensions(game)
    x = floor(Int32, x * window_width)
    y = floor(Int32, y * window_height)
    width = floor(Int32, width * window_width)
    height = floor(Int32, height * window_height)
    dest_ref = Ref(SDL_Rect(x, y, width, height))
    return dest_ref
end

function get_texture(game::Game, filepath::AbstractString)
    if !isfile(filepath)
        error("Image filepath: $filepath does not exist")
    end
    surface = IMG_Load(filepath)
    texture = SDL_CreateTextureFromSurface(game.renderer, surface)
    SDL_FreeSurface(surface)
    return texture
end

function Image(game::Game, filepath::AbstractString, x::Float64, y::Float64; zorder::Int64=1)
    texture = get_texture(game, filepath)
    window_width, window_height = get_dimensions(game)
    texture_width, texture_height = Ref{Cint}(0), Ref{Cint}(0)
    SDL_QueryTexture(texture, C_NULL, C_NULL, texture_width, texture_height)
    width = window_width ÷ texture_width[]
    height = window_height ÷ texture_height[]
    return Image(texture, zorder, x, y, width, height, get_dest_ref(game, x, y, width, height))
end

function Image(game::Game, filepath::AbstractString, x::Float64, y::Float64, width::Float64, height::Float64; zorder::Int64=1)
    return Image(get_texture(game, filepath), zorder, x, y, width, height, get_dest_ref(game, x, y, width, height))
end

function BackgroundImage(game::Game, filepath::AbstractString; zorder::Int64=0)
    return Image(get_texture(game, filepath), zorder, 0, 0, 1, 1, get_dest_ref(game, 0, 0, 1, 1))
end

function render(image::Image, game::Game)
    image.dest_ref = get_dest_ref(game, image.x, image.y, image.width, image.height)
    task = () -> SDL_RenderCopy(game.renderer, image.texture, C_NULL, image.dest_ref)
    add_render_task!(game, task, image.zorder)
end

end
