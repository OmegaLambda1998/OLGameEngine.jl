function add_component(game::Game)
    function wall(n)
        parts = Vector{RectangleRender}()
        width = 0.015
        height = 0.15
        x = 0.5 - (width / 2)
        init_y = 0.048 + 0.03
        for i in 1:n
            wall_part = RectangleRender(game, x, init_y + ((i - 1) * (height + 0.04)), width, height)
            push!(parts, wall_part)
        end
        return CompositeRender(parts)
    end
    add_system!(game, "wall", wall(5))
end
