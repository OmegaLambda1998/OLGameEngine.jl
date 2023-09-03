function add_component(game::Game)
    function wall(n)
        parts = Vector{Shape{sfRectangleShape}}()
        window_width, window_height = get_dimensions(game)
        rel_width = 0.015
        width = rel_width * window_width
        rel_height = 0.15
        height = rel_height * window_height
        rel_x = 0.5 - (rel_width / 2)
        x = rel_x * window_width
        rel_y = 0.078
        for i in 1:n
            y = (rel_y + ((i - 1) * (rel_height + 0.04))) * window_height
            wall_part = Rectangle(x, y, width, height)
            push!(parts, wall_part)
        end
        return CompositeRender(parts)
    end
    add_system!(game, "wall", wall(5))
end
