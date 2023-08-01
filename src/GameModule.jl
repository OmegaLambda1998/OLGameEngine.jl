# Game Module
module GameModule

# Internal Packages 
using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2
using Colors


# External Packages 

# Exports
export Game

mutable struct Game
    window::Ptr{SDL_Window}
    renderer::Ptr{SDL_Renderer}
    background::Colorant
end

end
