package shipSim.physics;

import haxe.Log;
import hxsl.Types.Vec;
import h3d.Vector;
import jamSim.Entity;

class ShipCollisionResolver extends MovementSystem {
    static var PVP_BOUNCE = 8;
    static var PVE_BOUNCE = 5;

    var _collisionSystem : CollisionSystem;

    public function new() {
        super();
    }

    public override function Init(entities:Array<Entity>) {
        super.Init(entities);

        for (ent in entities) {
            OnNewEntity(ent);
        }
    }

    public function SetCollisionSystem(colSys:CollisionSystem) {
        _collisionSystem = colSys;
    }

    public override function LateTick() {
        super.LateTick();

        for (activeCollision in _collisionSystem.GetPlayerCollisions()) {
            var p1Movement = FindMovementData(activeCollision.entOne);

            var colliderOne = _collisionSystem.GetColliderObject(activeCollision.entOne).collider;
            var colliderTwo = _collisionSystem.GetColliderObject(activeCollision.entTwo).collider;

            var positionDiff:Vector = new Vector();
            positionDiff.x = colliderOne.x - colliderTwo.x;
            positionDiff.y = colliderOne.y - colliderTwo.y;
            positionDiff.normalize();
            positionDiff.scale3(PVP_BOUNCE);
            GameMath.AddInPlace(p1Movement.bounce, positionDiff);
            Log.trace("pvp collision " + activeCollision.entOne);
        }

        for (activeCollision in _collisionSystem.GetCrateCollisions()) {
            var p1Movement = FindMovementData(activeCollision.entOne);

            var colliderOne = _collisionSystem.GetColliderObject(activeCollision.entOne).collider;
            var colliderTwo = _collisionSystem.GetColliderObject(activeCollision.entTwo).collider;

            var positionDiff:Vector = new Vector();
            positionDiff.x = colliderOne.x - colliderTwo.x;
            positionDiff.y = colliderOne.y - colliderTwo.y;
            positionDiff.normalize();
            positionDiff.scale3(PVE_BOUNCE);
            GameMath.AddInPlace(p1Movement.bounce, positionDiff);
            Log.trace("pve collision " + activeCollision.entOne);
        }
    }
}