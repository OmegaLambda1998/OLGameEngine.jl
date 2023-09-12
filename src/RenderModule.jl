# Render Module
module RenderModule

# Internal Packages 
using ..ConstantsModule
using ..SystemModule
using ..GameModule

# External Packages 
using CSFML
using CSFML.LibCSFML
using Colors
using Base.Threads

"""
A message which tells Renderable objects to render themselves
"""
Base.@kwdef mutable struct RenderMessage <: Message
    metadata::Dict{String,Any} = Dict{String,Any}()
end
export RenderMessage

"""
A system which renders to the screen
"""
abstract type RenderableSystem <: System end
export RenderableSystem

function SystemModule.is_subscribed(::RenderableSystem, ::RenderMessage)
    return true
end

"""
If a system is renderable, render it
"""
function SystemModule.handle_message!(system::RenderableSystem, message::RenderMessage)
    render(system, message.metadata["GAME"])
end

"""
By default nothing needs to happen when quitting a RenderableSystem
"""
function quit(::RenderableSystem) end
export quit

"""
If an object is renderable it should have it's own render function defined. If it doesn't this error will be called.
"""
function render(system::RenderableSystem, ::Game)
    error("System: $system is Renderable but does not have a render function defined.")
end

#
# COMPOSITE RENDER
#

Base.@kwdef mutable struct CompositeRender <: CompositeSystem
    subsystems::Vector{RenderableSystem}
end
export CompositeRender

function SystemModule.is_subscribed(::CompositeRender, ::RenderMessage)
    return true
end

function render(composite_system::CompositeRender, game::Game)
    for system in composite_system.subsystems
        render(system, game)
    end
end


#
# Shapes & Sprites
#

abstract type RenderableShape end
struct RectangleShape <: RenderableShape end

Base.@kwdef mutable struct Shape{S} <: RenderableSystem
    shape::Ptr{S}
    copy_shape::Function
    get_size::Function
    rel_to_abs_size::Function
    rel_to_abs_outline::Function
    modify_shape::Function
    draw_shape::Function
    zorder::Int64
end

function Shape(create_shape::Function, copy_shape::Function, get_size::Function, rel_to_abs_size::Function, rel_to_abs_outline, modify_shape::Function, draw_shape::Function, x::Float64, y::Float64, args...; zorder::Int64=1, colour::Colorant=colorant"white", outline_thickness::Float64=0.0, outline_colour::Colorant=colorant"white")
    shape = create_shape()
    sfShape_setPosition(shape, sfVector2f(x, y))
    modify_shape(shape, args...)
    r, g, b = colorant_to_rgb(colour)
    sfShape_setFillColor(shape, sfColor_fromRGB(r, g, b))
    if outline_thickness != 0.0
        sfShape_setOutlineThickness(shape, outline_thickness)
        r, g, b = colorant_to_rgb(outline_colour)
        sfShape_setOutlineColor(shape, sfColor_fromRGB(r, g, b))
    end
    return Shape(shape, copy_shape, get_size, rel_to_abs_size, rel_to_abs_outline, modify_shape, draw_shape, zorder)
end
export Shape

function Rectangle(x::Float64, y::Float64, width::Float64, height::Float64; kwargs...)
    create_shape = sfRectangleShape_create
    copy_shape = sfRectangleShape_copy
    get_size = sfRectangleShape_getSize
    function rel_to_abs_size(size::sfVector2f, window_width::UInt32, window_height::UInt32)
        return sfVector2f(size.x * window_width, size.y * window_height)
    end
    function rel_to_abs_outline(thickness::Float32, abs_size::sfVector2f)
        abs_width = abs_size.x
        abs_height = abs_size.y
        min_abs = min(abs_width, abs_height)
        return thickness * min_abs
    end
    modify_shape = sfRectangleShape_setSize
    draw_shape = sfRenderWindow_drawRectangleShape
    return Shape(create_shape, copy_shape, get_size, rel_to_abs_size, rel_to_abs_outline, modify_shape, draw_shape, x, y, sfVector2f(width, height); kwargs...)
end
export Rectangle

function Square(x::Float64, y::Float64, width::Float64; kwargs...)
    return Rectangle(x, y, width, width; kwargs...)
end
export Square

function Ellipse(x::Float64, y::Float64, width::Float64, height::Float64; kwargs...)
    create_shape = sfCircleShape_create
    copy_shape = sfCircleShape_copy
    function get_size(shape::Ptr{sfCircleShape})
        radius = sfCircleShape_getRadius(shape)
        scale = sfCircleShape_getScale(shape)
        height_scale = scale.y
        return sfVector2f(radius, height_scale)
    end
    function rel_to_abs_size(scale::sfVector2f, window_width::UInt32, ::UInt32)
        radius = scale.x * window_width
        height_scale = scale.y
        return sfVector2f(radius, height_scale)
    end
    function rel_to_abs_outline(thickness::Float32, scale::sfVector2f)
        radius = scale.x
        return thickness * radius
    end
    function modify_shape(shape::Ptr{sfCircleShape}, scale::sfVector2f)
        radius = scale.x
        height_scale = scale.y
        sfCircleShape_setRadius(shape, radius)
        sfCircleShape_setScale(shape, sfVector2f(1.0, height_scale))
    end
    draw_shape = sfRenderWindow_drawCircleShape
    radius = width / 2.0
    height_scale = height / width
    return Shape(create_shape, copy_shape, get_size, rel_to_abs_size, rel_to_abs_outline, modify_shape, draw_shape, x, y, sfVector2f(radius, height_scale); kwargs...)
end
export Ellipse

function Circle(x::Float64, y::Float64, radius::Float64; kwargs...)
    return Ellipse(x, y, 2*radius, 2*radius; kwargs...)
end
export Circle

function rel_to_abs(game::Game, shape::Shape)
    window_width, window_height = game.width, game.height
    rel_shape = shape.shape
    abs_shape = shape.copy_shape(rel_shape)
    pos = sfShape_getPosition(rel_shape)
    abs_x = pos.x * window_width
    abs_y = pos.y * window_height
    rel_size = shape.get_size(rel_shape)
    abs_size = shape.rel_to_abs_size(rel_size, window_width, window_height)
    sfShape_setPosition(abs_shape, sfVector2f(abs_x, abs_y))
    shape.modify_shape(abs_shape, abs_size)
    rel_outline_thickness = sfShape_getOutlineThickness(rel_shape)
    if rel_outline_thickness != 0.0
        outline_thickness = shape.rel_to_abs_outline(rel_outline_thickness, abs_size)
        sfShape_setOutlineThickness(abs_shape, outline_thickness)
    end
    return abs_shape
end


function render(shape::Shape, game::Game)
    task = () -> begin
        abs_shape = rel_to_abs(game, shape)
        shape.draw_shape(game.window, abs_shape, C_NULL)
    end
    add_render_task!(game, task, shape.zorder)
end

end
