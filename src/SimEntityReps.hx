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

    public function UpdateRepresentation(): Void {
    }

    public function GetObject(): Object {
        return _obj;
    }
}


class PlayerShipEntityRepresentation extends EnityRepresentation {
    var _collider : ColliderData;
    var _movement : ShipMovement;
    var _booster : Drawable;

    public function InitFromGameData(mov:Array<ShipMovement>, col:Map<EntityId,ColliderData>) : Bool {
        for (shipMovement in mov) {
            if (shipMovement.entityId == _entityId) {
                _movement = shipMovement;
            }
        }
        _collider = col[_entityId];

        return _movement != null && _collider != null;
    }

    public override function UpdateRepresentation(): Void {
        _obj.x = _collider.collider.x;
        _obj.y = _collider.collider.y;
        _obj.rotation = _movement.rotation;
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

    public override function UpdateRepresentation(): Void {
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

    public function InitFromGameData(col:Map<EntityId,ColliderData>, pickupData:Map<EntityId,PickupData>) : Bool {
        _collider = col[_entityId];
        _pickupData = pickupData[_entityId];
        _parent = null;
        return _collider != null;
    }

    public function InjectPlayerReps(reps:Map<EntityId, PlayerShipEntityRepresentation>) {
        _allPlayerReps = reps;
    }

    public override function UpdateRepresentation(): Void {
        if(_pickupData.GetParentId() != 0) {
            // we are supposed to have a parent. lets make sure we do
            var desiredParent = FindParentRepresentation(_pickupData.GetParentId());

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
            if (_parent != null) {
                if (_obj.parent == _parent.GetObject()) {
                    _obj.parent.removeChild(_obj);
                }
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