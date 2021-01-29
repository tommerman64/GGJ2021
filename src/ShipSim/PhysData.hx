package shipSim;

import h3d.Vector;
import h2d.col.Circle;
import jamSim.Entity;

class ColliderData
{
    // circle is both position and radius
    public var collider:Circle;
    public var obstacleCollisions:Array<EntityId>;
    public var playerCollisions:Array<EntityId>;

    public function new() {}
}

class ShipMovement
{
    public var entityId:Int;
    public var velocity: Vector;
    public var rotation: Float;
    public var rotationalVelocity: Float;

    public function new() {
        rotation = 0;
        rotationalVelocity = 0;
        velocity = new Vector();
    }
}