package shipSim;

import jamSim.Entity;
import shipSim.PhysData;

// moves player objects and records all collisions
// responding to collision events actually happens elsewhere
class CollisionSystem extends MovementSystem
{
    var _crateEntityIds: Array<EntityId>;
    var _collisionObjects: Array<ColliderData>;

    public function new() {
        super();
        _crateEntityIds = new Array<EntityId>();
    }

    public function InjectColliderData(col:Array<ColliderData>) {
        _collisionObjects = col;
    }

    public override function Init(entities:Array<Entity>) {
        super.Init(entities);
        for (ent in entities) {
            OnNewEntity(ent);
        }
    }

    public override function OnNewEntity(ent:Entity) {
        super.OnNewEntity(ent);
        if (ent.GetSystemTags().contains("Crate")) {
            _crateEntityIds.push(ent.GetId());
        }
    }

    public override function Tick() {
        for (pId in _playerEntityIds) {
            var movementData = FindMovementData(pId);
            _collisionObjects[pId-1].collider.x += movementData.velocity.x * MovementSystem.SIM_FRAME_LENGTH;
            _collisionObjects[pId-1].collider.y += movementData.velocity.y * MovementSystem.SIM_FRAME_LENGTH;
        }
        /*
        var i = 0;
        while (i < _collisionObjects.length) {
            var j = i + 1;
            while (j < _collisionObjects.length) {
                if (_collisionObjects[i].collider.collideCircle(_collisionObjects[j].collider)) {
                }
            }
        }
        */
    }
}