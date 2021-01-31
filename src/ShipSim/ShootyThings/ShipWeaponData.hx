package shipSim.shootyThings;
import h2d.Drawable;
import shipSim.shootyThings.ShootyData;
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
    public var warmup:Int;

    //Drawable Info for visRep
    public var tileScale:Float;
    public var eqTile:Tile;
    public var eqAnimName:String;

    public var pickupTile:Tile;
    public var pickupAnimName:String;

    public function new() {
        warmup = 0;
    }

    public function OnFire(shipPosition: Vector, slotData:ShipWeaponSlot, mov:ShipMovement, projectileSystem:ProjectileSystem) {
        Log.trace("Boom");
    }

    public function GetDrawable(equipped:Bool) : Drawable {
        if (equipped) {
            if (eqTile != null) {
                return GetEquippedBmp();
            }
    
            return GetAnim(eqAnimName);
        }
        else {
            if (eqTile != null) {
                return GetPickupBmp();
            }
            return GetAnim(pickupAnimName);
        }
        
    }

    public function GetEquippedBmp() : Drawable {
        var bmp = new h2d.Bitmap(eqTile);
        bmp.scale(tileScale);
        return bmp;
    }

    public function GetPickupBmp() : Drawable {
        var bmp = new h2d.Bitmap(pickupTile);
        bmp.scale(tileScale);
        return bmp;
    }

    public function GetAnim(animName:String) : Drawable {
        var texture = hxd.Res.loader.load("" +animName + ".png").toTexture();
        var jsonData = hxd.Res.loader.load("" +animName + "Map.json");
        var anim = ResourceLoading.LoadAnimFromSpriteSheet(texture, jsonData);
        anim.scale(tileScale);
        return anim;
    }
}

class ProjectileWeaponData extends ShipWeaponData {
    public var recoil:Float;
    public var recoilRotationAccelerator:Float;
    public var projectileTex:Tile;
    public var projectileSpeed:Float;

    public function new() {
        super();
        recoil = 1;
        recoilRotationAccelerator = 0;
        projectileSpeed = 0;
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
        projectile.rotation = mov.rotation;
        projectile.tile = projectileTex;

        projectileSystem.FireProjectile(projectile);

        var recoilVector = mov.GetForward();
        recoilVector.scale3(recoil);
        mov.velocity = mov.velocity.sub(recoilVector);
        mov.rotationalVelocity += recoilRotationAccelerator * slotData.spinFactor;
    }
}