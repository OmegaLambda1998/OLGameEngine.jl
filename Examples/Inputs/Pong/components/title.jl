function add_component(game::Game)
    title = ImageRender(game, abspath(joinpath(@__DIR__, "../assets/Title.png")), 0.476 / 2, 0.0, 0.476, 0.048; zorder=0)
    add_system!(game, "Title", title)
end
