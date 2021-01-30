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
}


class PlayerShipEntityRepresentation extends EnityRepresentation {
    var _collider : ColliderData;
    var _movement : ShipMovement;

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

    public function InitFromGameData(col:Map<EntityId,ColliderData>) : Bool {
        _collider = col[_entityId];
        return _collider != null;
    }

    public override function UpdateRepresentation(): Void {
        _obj.x = _collider.collider.x;
        _obj.y = _collider.collider.y;
        _obj.rotate(Math.PI / 300);
    }
}