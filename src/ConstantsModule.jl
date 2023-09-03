module ConstantsModule

# Internal Packages 

# External Packages 
using CSFML
using CSFML.LibCSFML
using Colors

"""
Dictionary of String, SFML Window Style pairs
"""
const str_to_attr::Dict{String,sfWindowStyle} = Dict{String,sfWindowStyle}(
    "sfNone" => sfNone,
    "sfTitlebar" => sfTitlebar,
    "sfResize" => sfResize,
    "sfClose" => sfClose,
    "sfFullscreen" => sfFullscreen,
    "sfDefaultStyle" => sfDefaultStyle
)
export str_to_attr

function Base.convert(::Type{sfWindowStyle}, attr_name::AbstractString)
    try
        return str_to_attr[attr_name] # Defined in Constants.jl
    catch e
        if isa(e, KeyError)
            throw(ErrorException("Unknown SFML Window Style $attr_name."))
        else
            throw(e)
        end
    end
end

"""
Convert a Colorant to seperate [0, 255] r g b parameters
"""
function colorant_to_rgb(c::C) where {C<:Colorant}
    c = parse(RGB, c)
    r = Float64(c.r) * 255
    g = Float64(c.g) * 255
    b = Float64(c.b) * 255
    return (r, g, b)
end
export colorant_to_rgb

end
