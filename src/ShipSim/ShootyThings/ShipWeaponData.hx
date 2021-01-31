package shipSim.shootyThings;
import shipSim.shootyThings.ShootyData.ProjectileData;
import h2d.Bitmap;
import h2d.Object;
import h2d.Tile;
import haxe.Log;
import shipSim.physics.PhysData.ShipMovement;
import h3d.Vector;
import shipSim.ShipInventory;


typedef WeaponLibrary = Array<ShipWeaponData>; 

class ShipWeaponData {
    public var weight:Float;
    public var cooldown:Int;
    public var tile:Tile;
    public var tileScale:Float;

    public function new() {
    }

    public function OnFire(shipPosition: Vector, slotData:ShipWeaponSlot, mov:ShipMovement, projectileSystem:ProjectileSystem) {
        Log.trace("Boom");
    }

    public function AttachBmpToObject(obj:Object):Bitmap {
        var bmp = new h2d.Bitmap(tile, obj);
        bmp.scale(tileScale);
        return bmp;
    }
}

class ProjectileWeaponData extends ShipWeaponData {
    public var recoil:Float;
    public var recoilRotationAccelerator:Float;

    public override function OnFire(shipPosition:Vector, slotData:ShipWeaponSlot, mov:ShipMovement, projectileSystem:ProjectileSystem) {
        // spawn projectile
        // do recoil on ship
        var projectile = new ProjectileData();
        projectile.direction = mov.GetForward();
        projectile.position.x = shipPosition.x + slotData.relativePosition.x;
        projectile.position.y = shipPosition.y + slotData.relativePosition.y;
        projectile.speed = 40;
        projectile.ownerId = mov.entityId;

        projectileSystem.FireProjectile(projectile);
    }
}