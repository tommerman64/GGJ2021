package shipSim.physics;

import haxe.Log;
import hxsl.Types.Vec;
import h3d.Vector;
import shipSim.physics.PhysData;
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
            // Log.trace("pvp collision " + activeCollision.entOne);

            RecalculateVelocity(positionDiff.getNormalized(), p1Movement);
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
            // Log.trace("pve collision " + activeCollision.entOne);

            RecalculateVelocity(positionDiff.getNormalized(), p1Movement);

        }
    }

    function RecalculateVelocity(positionDiff:Vector, mov:ShipMovement) {
        // if we are standing still we probably should still get a velocity jolt from it
        if (mov.velocity.lengthSq() < 3)
        {
            mov.SetVelocity(positionDiff.getNormalized());
            mov.velocity.scale3(-60);
        }
        var collisionDot = mov.velocity.getNormalized().dot3(positionDiff);

        collisionDot = Math.abs(collisionDot);
        var velocityImpact = hxd.Math.lerp(1, 0.3, collisionDot);
        var newV = mov.velocity.reflect(positionDiff);
        newV.scale3(velocityImpact);

        mov.SetVelocity(newV);
    }
}