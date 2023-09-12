function add_component(game::Game)
    function wall(n)
        parts = Vector{Shape{sfRectangleShape}}()
        width = 0.015
        height = 0.15
        x = 0.5 - (0.5 * width)
        rel_y = 0.078
        for i in 1:n
            y = (rel_y + ((i - 1) * (height + 0.04)))
            wall_part = Rectangle(x, y, width, height; zorder=1)
            push!(parts, wall_part)
        end
        return CompositeRender(parts)
    end
    add_system!(game, "wall", wall(5))
end
