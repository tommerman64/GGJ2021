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
            var playerCollider =_collisionObjects[pId-1];
            playerCollider.collider.x += movementData.velocity.x * MovementSystem.SIM_FRAME_LENGTH;
            playerCollider.collider.y += movementData.velocity.y * MovementSystem.SIM_FRAME_LENGTH;

            for(crateId in _crateEntityIds) {
                var crateCollider = _collisionObjects[crateId - 1];
                if (crateCollider.collider.collideCircle(playerCollider.collider)) {
                    RecordPlayerCrateCollision(pId, crateId);
                }
            }

            for (pId2 in _playerEntityIds) {
                if (pId2 == pId) {
                    continue;
                }
                var p2Collider =_collisionObjects[pId2-1];

                if (p2Collider.collider.collideCircle(playerCollider.collider)) {
                    RecordPlayerPlayerCollision(pId, pId2);
                }
            }
        }
    }

    function RecordPlayerCrateCollision(playerId:EntityId, crateId:EntityId) {
    }

    function RecordPlayerPlayerCollision(p1Id:EntityId, p2Id:EntityId) {
    }
}