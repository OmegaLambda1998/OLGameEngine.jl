function add_component(game::Game)
    title = Image(game, abspath(joinpath(@__DIR__, "../assets/Title.png")), 0.25, 0.0, 0.5, 0.2)
    add_system!(game, "Title", title)
end
