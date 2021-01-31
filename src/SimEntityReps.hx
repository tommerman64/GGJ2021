import h2d.Tile;
import shipSim.ShipInventory;
import shipSim.shootyThings.ShootyData.ProjectileData;
import shipSim.ShipInventory.PickupData;
import haxe.Log;
import h2d.Drawable;
import h2d.Anim;
import shipSim.physics.PhysData.ShipMovement;
import shipSim.physics.PhysData.ColliderData;
import h2d.Object;
import jamSim.Entity.EntityId;

// visual representation of a sim entity
// keeps a reference to the entity ID, all relevant data gets passed into the Update function

class EnityRepresentation {
    var _entityId:EntityId;
    var _obj: Object;
    public function new (id:EntityId, obj:Object) {
        _entityId = id;
        _obj = obj;
    }

    public function UpdateRepresentation(s2d:Object): Void {
    }

    public function GetObject(): Object {
        return _obj;
    }
}


class PlayerShipEntityRepresentation extends EnityRepresentation {
    var _collider : ColliderData;
    var _movement : ShipMovement;
    var _inventory : ShipInventory;
    var _booster : Drawable;
    var _scaleUpFrames : Int;
    var _armorPieces : Array<Drawable>;

    public function InitFromGameData(mov:Array<ShipMovement>, col:Map<EntityId,ColliderData>, inv:Map<EntityId,ShipInventory>) : Bool {
        for (shipMovement in mov) {
            if (shipMovement.entityId == _entityId) {
                _movement = shipMovement;
            }
        }
        _collider = col[_entityId];
        _inventory = inv[_entityId];
        _scaleUpFrames = 60;

        return _movement != null && _collider != null && _inventory != null;
    }

    public function AttachArmorPieces(tiles:Array<Tile>) {
        var positions = [
            { x:0, y:0 },
            { x:0, y: -17 },
            { x:0, y: 16 },
            { x:35, y:0 },
            { x:-35, y:0 },
        ];
        _armorPieces = new Array<Drawable>();
        for (i in 0...tiles.length) {
            var t = tiles[i];
            var bmp = new h2d.Bitmap(t, _obj);
            bmp.x = positions[i].x;
            bmp.y = positions[i].y;
            _armorPieces.push(bmp);
        }
    }

    public override function UpdateRepresentation(s2d:Object): Void {
        _obj.x = _collider.collider.x;
        _obj.y = _collider.collider.y;
        _obj.rotation = _movement.rotation;
        if(_scaleUpFrames >= 0) {
            _obj.setScale(0.25 + 0.75 * (60-_scaleUpFrames)/60);
            _scaleUpFrames -= 1;
            _obj.x -= _movement.GetForward().x * 50 * (_scaleUpFrames)/60;
            _obj.y -= _movement.GetForward().y * 50 * (_scaleUpFrames)/60;
        }
        _booster.visible = _movement.boosting;

        for (a in 0...5) {
            _armorPieces[a].visible = a < _inventory.armor;
        }
    }

    public function SetBoosterAnim(b:Anim) {
        _booster = b;
    }
}

class CrateEntityRepresentation extends EnityRepresentation {
    var _collider : ColliderData;

    public function InitFromGameData(col:Map<EntityId,ColliderData>) : Bool {
        _collider = col[_entityId];
        return _collider != null;
    }

    public override function UpdateRepresentation(s2d:Object): Void {
        _obj.x = _collider.collider.x;
        _obj.y = _collider.collider.y;
        _obj.rotate(Math.PI / 600 * Math.sin(_entityId));
    }
}

class PickupEntityRepresentation extends EnityRepresentation {
    var _collider : ColliderData;
    var _parent : EnityRepresentation;
    var _pickupData:PickupData;
    var _allPlayerReps:Map<EntityId, PlayerShipEntityRepresentation>;

    var _equippedDrawable:Drawable;
    var _floatingDrawable:Drawable;
    var _equippedAnim:Anim;

    public function InitFromGameData(col:Map<EntityId,ColliderData>, pickupData:Map<EntityId,PickupData>, eqDraw:Drawable, flDraw:Drawable, eqAnim:Anim) : Bool {
        _collider = col[_entityId];
        _pickupData = pickupData[_entityId];
        _parent = null;

        _floatingDrawable = flDraw;
        _obj.addChild(_floatingDrawable);

        if (eqAnim != null) {
            _equippedAnim = eqAnim;
            _obj.addChild(eqAnim);
            eqAnim.pause = true;
        }

        if (eqDraw != null) {
            _equippedDrawable = eqDraw;
            _obj.addChild(_equippedDrawable);
        }

        return _collider != null;
    }

    public function InjectPlayerReps(reps:Map<EntityId, PlayerShipEntityRepresentation>) {
        _allPlayerReps = reps;
    }

    public override function UpdateRepresentation(s2d:Object): Void {
        if(_pickupData.GetParentId() != 0) {
            // we are supposed to have a parent. lets make sure we do
            var desiredParent = FindParentRepresentation(_pickupData.GetParentId());
            SetEquipped(true);

            if(_parent != desiredParent) {
                if(_obj.parent != null) {
                    _obj.parent.removeChild(_obj);
                }
                _parent = desiredParent;
                _parent.GetObject().addChild(_obj);
            }

            if (_equippedAnim != null) {
                _equippedAnim.pause = !_pickupData.GetShooting();
            }

            _obj.x = _pickupData.GetSlot().relativePosition.x;
            _obj.y = _pickupData.GetSlot().relativePosition.y;
            _obj.rotation = 0;
        }
        else {
            // we are not supposed to have a parent, make sure we don't
            SetEquipped(false);
            if (_parent != null) {
                if (_obj.parent == _parent.GetObject()) {
                    _obj.parent.removeChild(_obj);
                }
                s2d.addChild(_obj);
            }
            _parent = null;
            _obj.x = _collider.collider.x;
            _obj.y = _collider.collider.y;
            // Log.trace(_collider.collider);
            _obj.rotate(Math.PI / 300);
        }
    }

    function SetEquipped(eq:Bool) {
        if (_equippedDrawable != null) {
            _equippedDrawable.visible = eq;
        }

        if (_equippedAnim != null) {
            _equippedAnim.visible = eq;
        }
        
        _floatingDrawable.visible = !eq;
    }

    function FindParentRepresentation(entityId:EntityId)  : EnityRepresentation{
        if (entityId <= 0) {
            return null;
        }

        for (rep in _allPlayerReps) {
            if (rep._entityId == entityId) {
                return rep;
            }
        }
        return null;
    }
}

class ProjectileEntityRepresentation extends EnityRepresentation {
    var _projectileData:ProjectileData;

    public function SetProjectileData(data:ProjectileData){
        _projectileData = data;
        if (_projectileData.tile == null) {
            _projectileData.tile = hxd.Res.laserBeam.toTile();
        }

        _projectileData.tile = _projectileData.tile.center();
        var bmp = new h2d.Bitmap(_projectileData.tile, _obj);
        bmp.scale(1.0/3.0);
    }

    public override function UpdateRepresentation(s2d:Object) {
        _obj.setPosition(_projectileData.position.x, _projectileData.position.y);
        _obj.rotation = _projectileData.rotation;
    }
}