package shipSim.physics;

import hxsl.Types.Vec;
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


class ActiveCollision {
    public var entOne:EntityId;
    public var entTwo:EntityId;

    public function new(e1:EntityId, e2:EntityId) {
        entOne = e1;
        entTwo = e2;
    }
}

class ShipMovement
{
    public var entityId:Int;
    public var velocity: Vector;
    public var rotation: Float;
    public var rotationalVelocity: Float;
    public var bounce:Vector;
    public var boosting:Bool;

    public function new() {
        rotation = 0;
        rotationalVelocity = 0;
        velocity = new Vector();
        bounce = new Vector();
        boosting = false;
    }
}