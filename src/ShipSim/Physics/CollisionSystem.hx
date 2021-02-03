package shipSim.physics;

import haxe.Constraints.Constructible;
import jamSim.SimSystem.SystemWithEntityData;
import hxsl.Types.Vec;
import h3d.Vector;
import jamSim.Entity;
import shipSim.physics.PhysData;

// moves player objects and records all collisions
// responding to collision events actually happens elsewhere
class CollisionSystem extends MovementSystem
    implements SystemWithEntityData<ColliderData>
{
    var _crateEntityIds: Array<EntityId>;
    var _pickupEntityIds: Array<EntityId>;
    var _colliderObjects: Map<EntityId,ColliderData>;
    var _playerPlayerCollisions:Array<ActiveCollision>;
    var _playerCrateCollisions:Array<ActiveCollision>;
    var _playerPickupCollisions:Array<ActiveCollision>;

    var _positionMax:Vector;

    public function new() {
        super();
        _crateEntityIds = new Array<EntityId>();
        _pickupEntityIds = new Array<EntityId>();
        _playerCrateCollisions = new Array<ActiveCollision>();
        _playerPlayerCollisions = new Array<ActiveCollision>();
        _playerPickupCollisions = new Array<ActiveCollision>();
        _positionMax = new Vector();

        _colliderObjects = new Map<EntityId, ColliderData>();
    }

    private function GetSystemDataForEntity(entityId:EntityId): ColliderData {
        if(_colliderObjects.exists(entityId)) {
            return _colliderObjects[entityId];
        }
        return null;
    }

    public function GetSystemEntityDataProvider(): EntityId->ColliderData {
        return GetSystemDataForEntity;
    }

    private function WriteSystemEntityData(entityId:EntityId, entityData:ColliderData) {
        _colliderObjects[entityId] = entityData;
    }

    public function GetSystemEntityDataWriter(): (EntityId,ColliderData)->Void {
        return WriteSystemEntityData;
    }

    public function SetPlayfieldSize(x:Float, y:Float) {
        _positionMax.x = x;
        _positionMax.y = y;
    }

    public function GetColliderObject(eId:EntityId) : ColliderData {
        return _colliderObjects[eId];
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
        if (ent.GetSystemTags().contains("Pickup")) {
            _pickupEntityIds.push(ent.GetId());
        }
    }

    public override function OnEntityDestroyed(entity:EntityId) {
        super.OnEntityDestroyed(entity);
        _crateEntityIds.remove(entity);
        _pickupEntityIds.remove(entity);
        _colliderObjects.remove(entity);
    }

    public override function EarlyTick() {
        super.EarlyTick();
        _playerCrateCollisions.resize(0);
        _playerPlayerCollisions.resize(0);
        _playerPickupCollisions.resize(0);
        for (pId in _playerEntityIds) {
            var movementData = FindMovementData(pId);
            if (movementData.bounce.lengthSq() > 0) {
                var playerCollider =_colliderObjects[pId];
                playerCollider.collider.x += movementData.bounce.x;
                playerCollider.collider.y += movementData.bounce.y;
                movementData.bounce.scale3(0);
            }
        }
    }

    public override function Tick() {
        for(pickupId in _pickupEntityIds) {
            KeepColliderInBounds(_colliderObjects[pickupId]);
        }
        for (pId in _playerEntityIds) {
            var movementData = FindMovementData(pId);
            var playerCollider =_colliderObjects[pId];
            playerCollider.collider.x += movementData.velocity.x * MovementSystem.SIM_FRAME_LENGTH;
            playerCollider.collider.y += movementData.velocity.y * MovementSystem.SIM_FRAME_LENGTH;

            KeepColliderInBounds(playerCollider);

            for(crateId in _crateEntityIds) {
                var crateCollider = _colliderObjects[crateId];
                if (crateCollider.collider.collideCircle(playerCollider.collider)) {
                    RecordPlayerCrateCollision(pId, crateId);
                }
            }

            for(pickupId in _pickupEntityIds) {
                var pickupCollider = _colliderObjects[pickupId];
                if (pickupCollider.collider.collideCircle(playerCollider.collider)) {
                    RecordPlayerPickupCollision(pId, pickupId);
                }
            }

            for (pId2 in _playerEntityIds) {
                if (pId2 == pId) {
                    continue;
                }
                var p2Collider =_colliderObjects[pId2];

                if (p2Collider.collider.collideCircle(playerCollider.collider)) {
                    RecordPlayerPlayerCollision(pId, pId2);
                }
            }
        }
    }

    function KeepColliderInBounds(colliderData:ColliderData) {
        if (colliderData.collider.x < 0) {
            colliderData.collider.x += _positionMax.x;
        }

        if (colliderData.collider.x > _positionMax.x) {
            colliderData.collider.x -= _positionMax.x;
        }

        if (colliderData.collider.y < 0) {
            colliderData.collider.y += _positionMax.y;
        }

        if (colliderData.collider.y > _positionMax.y) {
            colliderData.collider.y -= _positionMax.y;
        }
    }

    function RecordPlayerCrateCollision(playerId:EntityId, crateId:EntityId) {
        _playerCrateCollisions.push(new ActiveCollision(playerId, crateId));
    }

    function RecordPlayerPickupCollision(playerId:EntityId, pickupId:EntityId) {
        _playerPickupCollisions.push(new ActiveCollision(playerId, pickupId));
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

    public function GetPickupCollisions() : Array<ActiveCollision>{
        return _playerPickupCollisions;
    }
}