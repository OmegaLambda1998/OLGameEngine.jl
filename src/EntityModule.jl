# Entity Module
module EntityModule

# Internal Packages 
using ..SystemModule

# External Packages 

abstract type EntitySystem <: CompositeSystem end
export EntitySystem

end
