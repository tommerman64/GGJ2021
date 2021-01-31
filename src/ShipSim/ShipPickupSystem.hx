package shipSim;

import shipSim.physics.PhysData.ColliderData;
import shipSim.Input.InputSystem;
import shipSim.physics.CollisionSystem;
import jamSim.SimSystem;
import jamSim.Entity;
import shipSim.ShipInventory;

class ShipPickupSystem extends SimSystem {
    var _collisionSystem : CollisionSystem;
    var _shipInventories : Map<EntityId, ShipInventory>;
    var _pickupData : Map<EntityId,PickupData>;
    var _colliderData: Map<EntityId, ColliderData>;
    
    // For dropping items
    var _playerIds : Array<EntityId>;
    var _inputSystem:InputSystem;
    var _ignoredWeapons:Map<EntityId, Map<EntityId, Int>>;


    public function new() {
        super();
        _playerIds = new Array<EntityId>();
        _ignoredWeapons = new Map<EntityId, Map<EntityId, Int>>();
    }

    public override function Init(entities:Array<Entity>) {
        super.Init(entities);

        for (ent in entities) {
            OnNewEntity(ent);
        }
    }

    public override function OnNewEntity(ent:Entity) {
        super.OnNewEntity(ent);
        if (ent.GetSystemTags().contains("Player"))
        {
            _playerIds.push(ent.GetId());
            _ignoredWeapons[ent.GetId()] = new Map<EntityId, Int>();
        }
    }

    public function SetCollisionSystem(colSys:CollisionSystem) {
        _collisionSystem = colSys;
    }

    public function InjectColliderData(col:Map<EntityId, ColliderData>) {
        _colliderData = col;
    }

    public function SetInputSystem(inp:InputSystem) {
        _inputSystem = inp;
    }

    public function SetPickupData(data:Map<EntityId,PickupData>) {
        _pickupData = data;
    }

    public function SetInventories(inventories:Map<EntityId, ShipInventory>) {
        _shipInventories = inventories;
    }

    public override function Tick() {
        var inpIndex = 0;
        for(pId in _playerIds) {
            if (_inputSystem.GetInputState(inpIndex).Jettison) {
                var weaponId = _shipInventories[pId].DetachNextWeapon();
                while (weaponId > 0) {
                    // find weapon in pickup data using id
                    var pickup = _pickupData[weaponId];
                    // set the pickup to dropped
                    pickup.DetachFromShip();
                    // find the collision data
                    var weaponCol = _colliderData[weaponId];
                    var shipCol = _colliderData[pId];
                    weaponCol.collider.x = shipCol.collider.x;
                    weaponCol.collider.y = shipCol.collider.y;

                    _ignoredWeapons[pId][weaponId] = 120;

                    // drop another one
                    weaponId = _shipInventories[pId].DetachNextWeapon();
                }
            }
            else {
                var evictions = new Array<EntityId>();
                for (weaponId in _ignoredWeapons[pId].keys()) {
                    _ignoredWeapons[pId][weaponId]--;
                    if (_ignoredWeapons[pId][weaponId] < 0) {
                        evictions.push(weaponId);
                    }
                }

                for (weaponId in evictions) {
                    _ignoredWeapons[pId].remove(weaponId);
                }
            }
            inpIndex++;
        }
    }

    public override function LateTick() {
        super.LateTick();

        // Handle picking up weapons
        for (activeCollision in _collisionSystem.GetPickupCollisions()) {
            var shipId = activeCollision.entOne;
            var pickupId = activeCollision.entTwo;

            if(!_shipInventories[shipId].HasOpenSlots()){
                return;
            }

            if (_ignoredWeapons[shipId].exists(pickupId)) {
                return;
            }

            var canBePickedUp = true;
            for(inventory in _shipInventories){
                if(inventory.ContainsWeapon(pickupId)){
                    canBePickedUp = false;
                    break;
                }
            }
            if(canBePickedUp) {
                var attachedSlot = _shipInventories[shipId].AttachWeaponToFirstOpenIndex(pickupId);
                if(attachedSlot != null) {
                    _pickupData[pickupId].AttachToShip(shipId, attachedSlot);
                }
            }
        }
    }
}