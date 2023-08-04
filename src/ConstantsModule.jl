module ConstantsModule

# Internal Packages 

# External Packages 
using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2
using Colors

"""
Dictionary of String, SDL Attribute pairs
"""
const str_to_attr::Dict{String,SimpleDirectMediaLayer.LibSDL2.SDL_GLattr} = Dict{String,SimpleDirectMediaLayer.LibSDL2.SDL_GLattr}(
    "SDL_GL_RED_SIZE" => SDL_GL_RED_SIZE,
    "SDL_GL_GREEN_SIZE" => SDL_GL_GREEN_SIZE,
    "SDL_GL_BLUE_SIZE" => SDL_GL_BLUE_SIZE,
    "SDL_GL_ALPHA_SIZE" => SDL_GL_ALPHA_SIZE,
    "SDL_GL_BUFFER_SIZE" => SDL_GL_BUFFER_SIZE,
    "SDL_GL_DOUBLEBUFFER" => SDL_GL_DOUBLEBUFFER,
    "SDL_GL_DEPTH_SIZE" => SDL_GL_DEPTH_SIZE,
    "SDL_GL_STENCIL_SIZE" => SDL_GL_STENCIL_SIZE,
    "SDL_GL_ACCUM_RED_SIZE" => SDL_GL_ACCUM_RED_SIZE,
    "SDL_GL_ACCUM_GREEN_SIZE" => SDL_GL_ACCUM_GREEN_SIZE,
    "SDL_GL_ACCUM_BLUE_SIZE" => SDL_GL_ACCUM_BLUE_SIZE,
    "SDL_GL_ACCUM_ALPHA_SIZE" => SDL_GL_ACCUM_ALPHA_SIZE,
    "SDL_GL_STEREO" => SDL_GL_STEREO,
    "SDL_GL_MULTISAMPLEBUFFERS" => SDL_GL_MULTISAMPLEBUFFERS,
    "SDL_GL_MULTISAMPLESAMPLES" => SDL_GL_MULTISAMPLESAMPLES,
    "SDL_GL_ACCELERATED_VISUAL" => SDL_GL_ACCELERATED_VISUAL,
    "SDL_GL_RETAINED_BACKING" => SDL_GL_RETAINED_BACKING,
    "SDL_GL_CONTEXT_MAJOR_VERSION" => SDL_GL_CONTEXT_MAJOR_VERSION,
    "SDL_GL_CONTEXT_MINOR_VERSION" => SDL_GL_CONTEXT_MINOR_VERSION,
    "SDL_GL_CONTEXT_EGL" => SDL_GL_CONTEXT_EGL,
    "SDL_GL_CONTEXT_FLAGS" => SDL_GL_CONTEXT_FLAGS,
    "SDL_GL_CONTEXT_PROFILE_MASK" => SDL_GL_CONTEXT_PROFILE_MASK,
    "SDL_GL_SHARE_WITH_CURRENT_CONTEXT" => SDL_GL_SHARE_WITH_CURRENT_CONTEXT,
    "SDL_GL_FRAMEBUFFER_SRGB_CAPABLE" => SDL_GL_FRAMEBUFFER_SRGB_CAPABLE,
    "SDL_GL_CONTEXT_RELEASE_BEHAVIOR" => SDL_GL_CONTEXT_RELEASE_BEHAVIOR,
    "SDL_GL_CONTEXT_RESET_NOTIFICATION" => SDL_GL_CONTEXT_RESET_NOTIFICATION,
    "SDL_GL_CONTEXT_NO_ERROR" => SDL_GL_CONTEXT_NO_ERROR,
)
export str_to_attr

function Base.convert(::Type{SDL_GLattr}, attr_name::AbstractString)
    try
        return str_to_attr[attr_name] # Defined in Constants.jl
    catch e
        if isa(e, KeyError)
            throw(ErrorException("Unknown SDL attribute $attr_name."))
        else
            throw(e)
        end
    end
end

"""
Dictionary of String, SDL Render Flag pairs
"""
const str_to_flag::Dict{String,SimpleDirectMediaLayer.LibSDL2.SDL_RendererFlags} = Dict{String,SimpleDirectMediaLayer.LibSDL2.SDL_RendererFlags}(
    "SDL_RENDERER_SOFTWARE" => SDL_RENDERER_SOFTWARE,
    "SDL_RENDERER_ACCELERATED" => SDL_RENDERER_ACCELERATED,
    "SDL_RENDERER_PRESENTVSYNC" => SDL_RENDERER_PRESENTVSYNC,
    "SDL_RENDERER_TARGETTEXTURE" => SDL_RENDERER_TARGETTEXTURE
)
export str_to_flag

"""
Convert a Colorant to seperate [0, 255] r g b parameters
"""
function colorant_to_rgb(c::Colorant)
    c = parse(RGB, c)
    r = Float64(c.r) * 255
    g = Float64(c.g) * 255
    b = Float64(c.b) * 255
    return (r, g, b)
end
export colorant_to_rgb

end
