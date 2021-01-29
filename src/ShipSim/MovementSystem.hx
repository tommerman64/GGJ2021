package shipSim;

import jamSim.SimSystem;
import jamSim.Entity;
import shipSim.PhysData;

class MovementSystem extends SimSystem {
    var _playerEntityIds: Array<EntityId>;
    var _shipMovementData : Array<ShipMovement>;

    public function new() {
        super();
        _playerEntityIds = new Array<EntityId>();
    }

    public override function OnNewEntity(ent:Entity) {
        if (ent.GetSystemTags().contains("Player")) {
            _playerEntityIds.push(ent.GetId());
        }
    }

    public function InjectShipMovementData(moveData:Array<ShipMovement>) {
        _shipMovementData = moveData;
    }

    function FindMovementData(eId: EntityId) : ShipMovement {
        for (moveData in _shipMovementData)
        {
            if (moveData.entityId == eId)
            {
                return moveData;
            }
        }
        return null;
    }
}