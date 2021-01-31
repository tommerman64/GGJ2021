package shipSim;

import SimEntityReps.CrateEntityRepresentation;
import hxd.Rand;
import h3d.Vector;
import shipSim.physics.MovementSystem;
import shipSim.physics.PhysData.ShipMovement;
import h2d.col.Point;
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
    var _pickupDrifts: Map<EntityId, Point>;
    var _shipMovement:Array<ShipMovement>;
    var _random:Rand;

    public function new() {
        super();
        _playerIds = new Array<EntityId>();
        _ignoredWeapons = new Map<EntityId, Map<EntityId, Int>>();
        _pickupDrifts = new Map<EntityId, Point>();
        _random = Rand.create();
    }

    public override function Init(entities:Array<Entity>) {
        super.Init(entities);

        for (ent in entities) {
            OnNewEntity(ent);
        }
    }

    public override function OnNewEntity(ent:Entity) {
        super.OnNewEntity(ent);
        if (ent.GetSystemTags().contains("Player")){
            _playerIds.push(ent.GetId());
            _ignoredWeapons[ent.GetId()] = new Map<EntityId, Int>();
        }
        if(ent.GetSystemTags().contains("Pickup")){
            var r = _random.rand() * 2 * Math.PI;
            var rt = Math.sqrt(_random.rand());
            var x = rt * Math.sin(r) * 10;
            var y = rt * Math.cos(r) * 10;
            _pickupDrifts[ent.GetId()] = new Point(x,y);
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

    public function SetShipMovement(mov:Array<ShipMovement>) {
        _shipMovement = mov;
    }

    public function SetPickupData(data:Map<EntityId,PickupData>) {
        _pickupData = data;
    }

    public function SetInventories(inventories:Map<EntityId, ShipInventory>) {
        _shipInventories = inventories;
    }

    public override function EarlyTick() {
        for(pickupId in _pickupDrifts.keys()){
            if(_colliderData.exists(pickupId)){
                _colliderData[pickupId].collider.x += _pickupDrifts[pickupId].x * _sim.GetSimFrameLength();
                _colliderData[pickupId].collider.y += _pickupDrifts[pickupId].y * _sim.GetSimFrameLength();
            }
        }
    }

    public override function Tick() {
        var inpIndex = 0;
        for(pId in _playerIds) {
            if (_inputSystem.GetInputState(inpIndex).Jettison) {
                var weaponId = _shipInventories[pId].DetachNextWeapon();
                if(weaponId > 0){
                    hxd.Res.jettison.play();
                }
                while (weaponId > 0) {
                    // find weapon in pickup data using id
                    var pickup = _pickupData[weaponId];
                    var slot = pickup.GetSlot();
                    // set the pickup to dropped
                    pickup.DetachFromShip();
                    // find the collision data
                    var weaponCol = _colliderData[weaponId];
                    var shipCol = _colliderData[pId];

                    var slotPosition = new Vector(shipCol.collider.x, shipCol.collider.y);
                    for(move in _shipMovement){
                        if(move.entityId == pId){
                            slotPosition = GameMath.GetSlotAbsolutePosition(new Vector(shipCol.collider.x, shipCol.collider.y), slot, move);
                        }
                    }

                    weaponCol.collider.x = slotPosition.x;
                    weaponCol.collider.y = slotPosition.y;

                    _ignoredWeapons[pId][weaponId] = 120;

                    // Apply ship drift
                    for(move in _shipMovement){
                        if(move.entityId == pId){
                            _pickupDrifts[weaponId] = new Point(move.velocity.x, move.velocity.y);
                        }
                    }

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
                hxd.Res.pickup.play();
                if(attachedSlot != null) {
                    _pickupData[pickupId].AttachToShip(shipId, attachedSlot);
                    _pickupDrifts.remove(pickupId);
                }
            }
        }
    }
}