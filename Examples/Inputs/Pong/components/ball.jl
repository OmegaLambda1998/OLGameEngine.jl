function add_component(game::Game)
    ball = Ball(game)
    add_system!(game, "ball", ball)
end
