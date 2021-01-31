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
    public var animName:String;

    public function new() {
    }

    public function OnFire(shipPosition: Vector, slotData:ShipWeaponSlot, mov:ShipMovement, projectileSystem:ProjectileSystem) {
        Log.trace("Boom");
    }

    public function AttachDrawableToObject(obj:Object) : Void {
        if (tile != null) {
            AttachBmpToObject(obj);
            return;
        }

        LoadAndAttachAnim(obj);
    }

    public function AttachBmpToObject(obj:Object) : Void {
        var bmp = new h2d.Bitmap(tile, obj);
        bmp.scale(tileScale);
    }

    public function LoadAndAttachAnim(obj:Object) : Void {
        var texture = hxd.Res.loader.load("" +animName + ".png").toTexture();
        var jsonData = hxd.Res.loader.load("" +animName + "Map.json");
        var anim = ResourceLoading.LoadAnimFromSpriteSheet(texture, jsonData);
        anim.scale(tileScale);

        obj.addChild(anim);
    }
}

class ProjectileWeaponData extends ShipWeaponData {
    public var recoil:Float;
    public var recoilRotationAccelerator:Float;

    public function new() {
        super();
        recoil = 1;
        recoilRotationAccelerator = 0;
    }

    public override function OnFire(shipPosition:Vector, slotData:ShipWeaponSlot, mov:ShipMovement, projectileSystem:ProjectileSystem) {
        // spawn projectile
        // do recoil on ship
        var projectile = new ProjectileData();
        projectile.direction = mov.GetForward();
        var projectileStart = GameMath.GetSlotAbsolutePosition(shipPosition, slotData, mov);
        projectile.position.x = projectileStart.x;
        projectile.position.y = projectileStart.y;
        projectile.speed = 40;
        projectile.ownerId = mov.entityId;

        projectileSystem.FireProjectile(projectile);

        var recoilVector = mov.GetForward();
        recoilVector.scale3(recoil);
        mov.velocity = mov.velocity.sub(recoilVector);
        mov.rotationalVelocity += recoilRotationAccelerator * slotData.spinFactor;
    }
}