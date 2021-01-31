package shipSim.shootyThings;

import hxd.fmt.hmd.Data.Position;
import jamSim.Entity;
import h2d.col.Point;
import jamSim.Entity.EntityId;
import h3d.Vector;


class ProjectileData {
    public var entityId:EntityId;
    public var position:Point;
    public var direction:Vector;
    public var speed:Float;
    public var ownerId:EntityId;

    public function new(eId:EntityId = -1)
    {
        entityId = eId;
        position = new Point();
        direction = new Vector();
        speed = 0;
    }
}

class Shootable {
    public var entityId:EntityId;

    public function new(eId:EntityId) {
        entityId = eId;
    }
    public function TakeHit(projectile:ProjectileData): Void {
    }
}