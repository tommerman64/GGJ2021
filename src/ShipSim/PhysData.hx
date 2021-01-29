package shipSim;

import h3d.Vector;
import h2d.col.Circle;
import jamSim.Entity;

class ColliderData
{
    // circle is both position and radius
    public var collider:Circle;
    public var currentCollisions:Array<EntityId>;
}

class ShipMovement
{
    public var entityId:Int;
    public var velocity: Vector;
    public var rotation: Float;
    public var rotationalVelocity: Float;
}