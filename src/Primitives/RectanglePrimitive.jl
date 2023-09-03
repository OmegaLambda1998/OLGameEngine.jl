
abstract type RenderableShape end
struct RectangleShape <: RenderableShape end

Base.@kwdef mutable struct Shape{S} <: RenderableSystem
    shape::Ptr{S}
    draw_shape::Function
    zorder::Int64
end

function Shape(create_shape::Function, modify_shape::Function, draw_shape::Function, x::Float64, y::Float64, args...; zorder::Int64=1, colour::Colorant=colorant"white", outline_thickness::Float64=0.0, outline_colour::Colorant=colorant"white")
    shape = create_shape()
    sfShape_setPosition(shape, sfVector2f(x, y))
    modify_shape(shape, args...)
    r, g, b = colorant_to_rgb(colour)
    sfShape_setFillColor(shape, sfColor_fromRGB(r, g, b))
    if outline_thickness != 0.0
        sfShape_setOutlineThickness(rectangle, outline_thickness)
        r, g, b = colorant_to_rgb(outline_colour)
        sfShape_setOutlineColor(rectangle, sfColor_fromRGB(r, g, b))
    end
    return Shape(shape, draw_shape, zorder)
end
export Shape

function Rectangle(x::Float64, y::Float64, width::Float64, height::Float64; zorder::Int64=1, colour::Colorant=colorant"white", outline_colour::Colorant=colorant"white", outline_thickness::Float64=0.0)
    create_shape = sfRectangleShape_create
    modify_shape = sfRectangleShape_setSize
    draw_shape = sfRenderWindow_drawRectangleShape
    return Shape(create_shape, modify_shape, draw_shape, x, y, sfVector2f(width, height); zorder=zorder, colour=colour, outline_thickness=outline_thickness, outline_colour=outline_colour)
end
export Rectangle

function Square(x::Float64, y::Float64, width::Float64; zorder::Int64=1)
    return Rectangle(x, y, width, width; zorder=zorder)
end
export Square

function render(shape::Shape, game::Game)
    task = () -> begin
        shape.draw_shape(game.window, shape.shape, C_NULL)
    end
    add_render_task!(game, task, shape.zorder)
end
