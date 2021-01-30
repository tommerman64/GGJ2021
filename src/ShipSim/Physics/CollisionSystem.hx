package shipSim.physics;

import jamSim.Entity;
import shipSim.physics.PhysData;

// moves player objects and records all collisions
// responding to collision events actually happens elsewhere
class CollisionSystem extends MovementSystem
{
    var _crateEntityIds: Array<EntityId>;
    var _colliderObjects: Array<ColliderData>;
    var _playerPlayerCollisions:Array<ActiveCollision>;
    var _playerCrateCollisions:Array<ActiveCollision>;

    public function new() {
        super();
        _crateEntityIds = new Array<EntityId>();
        _playerCrateCollisions = new Array<ActiveCollision>();
        _playerPlayerCollisions = new Array<ActiveCollision>();
    }

    public function InjectColliderData(col:Array<ColliderData>) {
        _colliderObjects = col;
    }

    public function GetColliderObject(eId:EntityId) : ColliderData {
        return _colliderObjects[eId - 1];
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
    
    public override function EarlyTick() {
        super.EarlyTick();
        _playerCrateCollisions.resize(0);
        _playerPlayerCollisions.resize(0);
        for (pId in _playerEntityIds) {
            var movementData = FindMovementData(pId);
            if (movementData.bounce.lengthSq() > 0) {
                var playerCollider =_colliderObjects[pId-1];
                playerCollider.collider.x += movementData.bounce.x;
                playerCollider.collider.y += movementData.bounce.y;
                movementData.bounce.scale3(0);
            }
        }
    }

    public override function Tick() {
        for (pId in _playerEntityIds) {
            var movementData = FindMovementData(pId);
            var playerCollider =_colliderObjects[pId-1];
            playerCollider.collider.x += movementData.velocity.x * MovementSystem.SIM_FRAME_LENGTH;
            playerCollider.collider.y += movementData.velocity.y * MovementSystem.SIM_FRAME_LENGTH;

            for(crateId in _crateEntityIds) {
                var crateCollider = _colliderObjects[crateId - 1];
                if (crateCollider.collider.collideCircle(playerCollider.collider)) {
                    RecordPlayerCrateCollision(pId, crateId);
                }
            }

            for (pId2 in _playerEntityIds) {
                if (pId2 == pId) {
                    continue;
                }
                var p2Collider =_colliderObjects[pId2-1];

                if (p2Collider.collider.collideCircle(playerCollider.collider)) {
                    RecordPlayerPlayerCollision(pId, pId2);
                }
            }
        }
    }

    function RecordPlayerCrateCollision(playerId:EntityId, crateId:EntityId) {
        _playerCrateCollisions.push(new ActiveCollision(playerId, crateId));
    }

    function RecordPlayerPlayerCollision(p1Id:EntityId, p2Id:EntityId) {
        _playerPlayerCollisions.push(new ActiveCollision(p1Id, p2Id));
    }

    public function GetPlayerCollisions() : Array<ActiveCollision>{
        return _playerPlayerCollisions;
    }

    public function GetCrateCollisions() : Array<ActiveCollision>{
        return _playerCrateCollisions;
    }
}