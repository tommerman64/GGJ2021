package shipSim.physics;

import jamSim.SimSystem;
import jamSim.Entity;
import shipSim.physics.PhysData;

// Sim system that tracks player movement data
class MovementSystem extends SimSystem {
    static var SIM_FRAME_LENGTH = 1.0/60.0;

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

    public override function OnEntityDestroyed(entId:EntityId){
        _playerEntityIds.remove(entId);
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