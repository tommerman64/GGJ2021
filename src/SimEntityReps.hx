import shipSim.shootyThings.ShipWeaponData;
import format.as1.Constants.ActionCode;
import shipSim.shootyThings.ShootyData.ProjectileData;
import jamSim.Entity;
import shipSim.ShipInventory.PickupData;
import haxe.Log;
import h2d.Drawable;
import h2d.Anim;
import shipSim.ShipInventory.ShipWeaponSlot;
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
    var _booster : Drawable;
    var _scaleUpFrames : Int;

    public function InitFromGameData(mov:Array<ShipMovement>, col:Map<EntityId,ColliderData>) : Bool {
        for (shipMovement in mov) {
            if (shipMovement.entityId == _entityId) {
                _movement = shipMovement;
            }
        }
        _collider = col[_entityId];
        _scaleUpFrames = 60;

        return _movement != null && _collider != null;
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
        _obj.rotate(Math.PI / 600);
    }
}

class PickupEntityRepresentation extends EnityRepresentation {
    var _collider : ColliderData;
    var _parent : EnityRepresentation;
    var _pickupData:PickupData;
    var _allPlayerReps:Map<EntityId, PlayerShipEntityRepresentation>;
    var _equippedDrawable:Drawable;
    var _floatingDrawable:Drawable;

    public function InitFromGameData(col:Map<EntityId,ColliderData>, pickupData:Map<EntityId,PickupData>, eqDraw:Drawable, flDraw:Drawable) : Bool {
        _collider = col[_entityId];
        _pickupData = pickupData[_entityId];
        _parent = null;
        _equippedDrawable = eqDraw;
        _floatingDrawable = flDraw;

        _obj.addChild(_equippedDrawable);
        _obj.addChild(_floatingDrawable);
        _floatingDrawable.visible = false;
        return _collider != null;
    }

    public function InjectPlayerReps(reps:Map<EntityId, PlayerShipEntityRepresentation>) {
        _allPlayerReps = reps;
    }

    public override function UpdateRepresentation(s2d:Object): Void {
        if(_pickupData.GetParentId() != 0) {
            // we are supposed to have a parent. lets make sure we do
            var desiredParent = FindParentRepresentation(_pickupData.GetParentId());
            _equippedDrawable.visible = true;
            _floatingDrawable.visible = false;

            if(_parent != desiredParent) {
                if(_obj.parent != null) {
                    _obj.parent.removeChild(_obj);
                }
                _parent = desiredParent;
                _parent.GetObject().addChild(_obj);
            }

            _obj.x = _pickupData.GetSlot().relativePosition.x;
            _obj.y = _pickupData.GetSlot().relativePosition.y;
            _obj.rotation = 0;
        }
        else {
            // we are not supposed to have a parent, make sure we don't
            _equippedDrawable.visible = false;
            _floatingDrawable.visible = true;
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
    }

    public override function UpdateRepresentation(s2d:Object) {
        _obj.setPosition(_projectileData.position.x, _projectileData.position.y);
        _obj.rotation = _projectileData.rotation;
    }
}