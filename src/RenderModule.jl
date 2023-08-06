# Render Module
module RenderModule

# Internal Packages 
using ..ConstantsModule
using ..SystemModule
using ..GameModule

# External Packages 
using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2
using Colors

"""
A message which tells Renderable objects to render themselves
"""
struct RenderMessage <: Message
    game::Game
end
export RenderMessage

function Base.show(io::IO, message::RenderMessage)
    print(io, "RenderMessage")
end

"""
A system which renders to the screen
"""
abstract type RenderableSystem <: System end
export RenderableSystem

function SystemModule.is_subscribed(system::RenderableSystem, message::RenderMessage)
    return true
end

"""
If a system is renderable, render it
"""
function SystemModule.handle_message!(system::RenderableSystem, message::RenderMessage)
    log_message(message.game, "message_log", "$message -> $system")
    render(system, message.game)
end

"""
By default nothing needs to happen when quitting a RenderableSystem
"""
function quit(system::RenderableSystem) end
export quit

"""
If an object is renderable it should have it's own render function defined. If it doesn't this error will be called.
"""
function render(system::RenderableSystem, game::Game)
    error("System: $system is Renderable but does not have a render function defined.")
end
export render

"""
x, y, width, height are relative to the window size:
x: 0 -> left, 1 -> right
y: 0 -> top, 1 -> bottom
width: 0 -> 0, 1 -> window width
height 0 -> 0, 1 -> window height
This function converts from these relative units to physical units
"""
function relative_to_physical(game::Game, x, y, width, height)
    window_width, window_height = get_dimensions(game)
    x = floor(Int32, x * window_width)
    y = floor(Int32, y * window_height)
    width = floor(Int32, width * window_width)
    height = floor(Int32, height * window_height)
    return x, y, width, height
end
export relative_to_physical

function physical_to_relative(game::Game, x, y, width, height)
    window_width, window_height = get_dimensions(game)
    x = x / window_width
    y = y / window_height
    width = width / window_width
    height = height / window_height
    return x, y, width, height
end
export physical_to_relative

"""
Get a rectangle given relative x, y, width, and height.
"""
function get_rect(game::Game, x::Float64, y::Float64, width::Float64, height::Float64)
    x, y, width, height = relative_to_physical(game, x, y, width, height)
    dest_ref = Ref(SDL_Rect(x, y, width, height))
    return dest_ref
end

mutable struct CompositeRender <: CompositeSystem
    subsystems::Vector{RenderableSystem}
end
export CompositeRender

function SystemModule.is_subscribed(system::CompositeRender, message::RenderMessage)
    return true
end

function render(composite_system::CompositeRender, game::Game)
    for system in composite_system.subsystems
        render(system, game)
    end
end

mutable struct Image <: RenderableSystem
    texture::Ptr{SDL_Texture}
    x::Float64
    y::Float64
    width::Float64
    height::Float64
    zorder::Int64
    dest_ref::Base.RefValue{SDL_Rect}
end
export Image

function Base.show(io::IO, system::Image)
    print(io, "Image")
end

function quit(image::Image)
    SDL_DestroyTexture(image.texture)
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
    return Image(texture, x, y, width, height, zorder, get_rect(game, x, y, width, height))
end

function Image(game::Game, filepath::AbstractString, x::Float64, y::Float64, width::Float64, height::Float64; zorder::Int64=1)
    return Image(get_texture(game, filepath), x, y, width, height, zorder, get_rect(game, x, y, width, height))
end

function BackgroundImage(game::Game, filepath::AbstractString; zorder::Int64=0)
    return Image(get_texture(game, filepath), 0, 0, 1, 1, zorder, get_rect(game, 0, 0, 1, 1))
end
export BackgroundImage

function render(image::Image, game::Game)
    image.dest_ref = get_rect(game, image.x, image.y, image.width, image.height)
    task = () -> SDL_RenderCopy(game.renderer, image.texture, C_NULL, image.dest_ref)
    add_render_task!(game, task, image.zorder)
end

mutable struct Rectangle <: RenderableSystem
    x::Float64
    y::Float64
    width::Float64
    height::Float64
    colour::Colorant
    zorder::Int64
    rect::Base.RefValue{SDL_Rect}
end
export Rectangle

function Rectangle(game::Game, x::Float64, y::Float64, width::Float64, height::Float64; colour::Colorant=colorant"white", zorder::Int64=1)
    rect = get_rect(game, x, y, width, height)
    return Rectangle(x, y, width, height, colour, zorder, rect)
end

function Base.show(io::IO, system::Rectangle)
    print(io, "Rectangle")
end

function render(rectangle::Rectangle, game::Game)
    rectangle.rect = get_rect(game, rectangle.x, rectangle.y, rectangle.width, rectangle.height)
    task = () -> begin
        r, g, b = colorant_to_rgb(rectangle.colour)
        SDL_SetRenderDrawColor(game.renderer, r, g, b, 255)
        SDL_RenderFillRect(game.renderer, rectangle.rect)
    end
    add_render_task!(game, task, rectangle.zorder)
end


end
