# Physics Module
module PhysicsModule

# Internal Packages 

# External Packages 

# Exports
export PhysicsTrait, PhysicsObject, NotPhysicsObject

"""
A trait stating whether an object is affected by physics or not
"""
abstract type PhysicsTrait end

"""
This object is affect by physics
"""
struct PhysicsObject <: PhysicsTrait end

"""
This object is not affected by physics
"""
struct NotPhysicsObject <: PhysicsTrait end

"""
Most objects default to NonPhysicsObject
"""
PhysicsTrait(::Type) = NotPhysicsObject()

end
