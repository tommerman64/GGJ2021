package shipSim.shootyThings;

import h2d.Tile;
import jamSim.Sim;
import shipSim.physics.PhysData.ColliderData;
import h2d.col.Collider;
import shipSim.GameEntities.Pickup;
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
    public var damage:Int;
    public var rotation:Float;
    public var tile:Tile;

    public function new(eId:EntityId = -1)
    {
        entityId = eId;
        position = new Point();
        direction = new Vector();
        speed = 0;
        damage = 1;
        rotation = 0;
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

class ShootableCrate extends Shootable {
    public var spawnSystem:SpawnSystem;
    public var colliderData:ColliderData;
    public var sim:Sim;
    public var health:Int;

    public function new(eId:EntityId){
        super(eId);
        health = 5;
    }

    public override function TakeHit(projectile:ProjectileData): Void {
        if(health > 0){
            health -= projectile.damage;
            if(health <= 0){
                var x = projectile.position.x;
                var y = projectile.position.y;
                if(colliderData != null){
                    x = colliderData.collider.x;
                    y = colliderData.collider.y;
                }
                spawnSystem.SpawnEntity(new Pickup(), x, y);
                hxd.Res.crateBreak.play().priority = 1;
                sim.DestroyEntity(entityId);
            }
            else{
                hxd.Res.cratehit.play().priority = 1;
            }
        }
    }
}

class ShootableShip extends Shootable {
    public var colliderData:ColliderData;
    public var pickupSystem:ShipPickupSystem;

    public function new(eId:EntityId){
        super(eId);
    }

    public override function TakeHit(projectile:ProjectileData): Void {
        hxd.Res.cratehit.play().priority = 1;
        for(i in 0...projectile.damage){
            pickupSystem.JettisonRandomWeaponOrArmor(entityId);
        }
    }

}