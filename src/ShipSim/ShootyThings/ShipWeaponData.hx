package shipSim.shootyThings;
import haxe.Log;
import shipSim.physics.PhysData.ShipMovement;
import h3d.Vector;
import shipSim.ShipInventory;


typedef WeaponLibrary = Array<ShipWeaponData>; 

class ShipWeaponData {
    public var weight:Float;
    public var cooldown:Int;

    public function new() {
    }

    public function OnFire(shipPosition: Vector, slotData:ShipWeaponSlot, mov:ShipMovement) {
        Log.trace("Boom");
    }
}

class ProjectileWeaponData extends ShipWeaponData {
    public var recoil:Float;
    public var recoilRotationAccelerator:Float;

    public override function OnFire(shipPosition:Vector, slotData:ShipWeaponSlot, mov:ShipMovement) {
        // spawn projectile
        // do recoil on ship
    }
}