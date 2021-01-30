package shipSim.shootyThings;
import haxe.Log;
import shipSim.physics.PhysData.ShipMovement;
import h3d.Vector;


typedef WeaponLibrary = Array<ShipWeaponData>; 

class ShipWeaponData {
    public var weight:Float;
    public var cooldown:Int;

    public function new() {
    }

    public function OnFire(shipPosition: Vector, offset:Vector, forward:Vector, mov:ShipMovement) {
        Log.trace("Boom");
    }
}

class ProjectileWeaponData extends ShipWeaponData {
    public var recoil:Float;
    public var recoilRotationAccelerator:Float;

    public override function OnFire(shipPosition:Vector, offset:Vector, forward:Vector, mov:ShipMovement) {
        // spawn projectile
        // do recoil on ship
    }
}