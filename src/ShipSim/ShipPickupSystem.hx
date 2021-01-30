package shipSim;

import shipSim.GameEntities.PlayerShipEntity;
import SimEntityReps.PlayerShipEntityRepresentation;
import SimEntityReps.PickupEntityRepresentation;
import haxe.Log;
import shipSim.physics.CollisionSystem;
import jamSim.SimSystem;
import jamSim.Entity;

class ShipPickupSystem extends SimSystem {
    var _collisionSystem : CollisionSystem;
    var _shipInventories : Map<EntityId, ShipInventory>;
    var _pickupRepresentations : Map<EntityId, PickupEntityRepresentation>;
    var _shipRepresentations : Map<EntityId, PlayerShipEntityRepresentation>;

    public function new() {
        super();
    }

    public override function Init(entities:Array<Entity>) {
        super.Init(entities);

        for (ent in entities) {
            OnNewEntity(ent);
        }
    }

    public function SetCollisionSystem(colSys:CollisionSystem) {
        _collisionSystem = colSys;
    }

    public function SetRepresentations(pickupRepresentations:Map<EntityId, PickupEntityRepresentation>, shipRepresentations:Map<EntityId, PlayerShipEntityRepresentation>) {
        _pickupRepresentations = pickupRepresentations;
        _shipRepresentations = shipRepresentations;
    }

    public function SetInventories(inventories:Map<EntityId, ShipInventory>) {
        _shipInventories = inventories;
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
                    _pickupRepresentations[pickupId].Attach(_shipRepresentations[shipId].GetObject(), attachedSlot);
                }
            }
        }
    }
}