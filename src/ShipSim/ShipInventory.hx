package shipSim;

import haxe.Log;
import jamSim.Entity;
import h3d.Vector;

class ShipWeaponSlot {
    public function new(position:Vector, spin:Float) {
        relativePosition = position;
        spinFactor = spin;
    }

    // Where to place the weapon relative to the ship
    public var relativePosition:Vector;
    // Modifiers for the translation and rotation recoil of the weapon respectively
    public var recoilAngle:Float;
    public var spinFactor:Float;
}

class PickupData {
    var _weaponLibraryIndex:Int;
    var _parentEntityId:EntityId;
    var _slot:ShipWeaponSlot;


    public function new(i:Int) {
        _weaponLibraryIndex = i;
        _parentEntityId = 0;
    }

    public function AttachToShip(shipEntityId:EntityId, slot:ShipWeaponSlot) {
        _parentEntityId = shipEntityId;
        _slot = slot;
    }

    public function DetachFromShip() {
        _parentEntityId = 0;
        _slot = null;
    }

    public function GetWeaponLibIndex() {
        return _weaponLibraryIndex;
    }

    public function GetParentId():EntityId {
        return _parentEntityId;
    }

    public function GetSlot() : ShipWeaponSlot {
        return _slot;
    }
}

class ShipInventory {
    public var weaponSlots:Array<ShipWeaponSlot>;
    public var weaponEntityIds:Array<EntityId>; // Entity IDs of attached weapons

    public function new() {
    }

    // weapon entity id > pickup > weapon library index

    public function InitializeWeaponSlots(slots:Array<ShipWeaponSlot>) {
        weaponSlots = slots;
        weaponEntityIds = new Array<EntityId>();
        for(i in 0...weaponSlots.length) {
            weaponEntityIds.push(0);
        }
    }

    public function AttachWeaponToFirstOpenIndex(weapon:EntityId): ShipWeaponSlot {
        if (Entity.IdIsValid(weapon)) {
            var index = weaponEntityIds.indexOf(0);
            if (index != -1) {
                AttachWeaponAtIndex(weapon, index);
                return weaponSlots[index];
            }
        }

        return null;
    }

    public function AttachWeaponAtIndex(weapon:EntityId, index:Int) {
        if (index < weaponEntityIds.length && index >= 0 && Entity.IdIsValid(weapon)) {
            // Make sure we're not double-attaching the same weapon
            var existingIndex = weaponEntityIds.indexOf(weapon);
            if (existingIndex == -1) {
                if (weaponEntityIds[index] == 0)
                    // Add weapon to attachment-related systems
                    weaponEntityIds[index] = weapon;
            }
        }
    }

    public function HasOpenSlots(): Bool {
        // Log.trace(weaponEntityIds[0]);
        return weaponEntityIds.indexOf(0) != -1;
    }

    public function IsEmpty() : Bool {
        for (i in 0...weaponEntityIds.length) {
            if (weaponEntityIds[i] > 0) {
                return false;
            }
        }

        return true;
    }

    public function ContainsWeapon(weapon:EntityId): Bool {
        return weaponEntityIds.indexOf(weapon) != -1;
    }

    public function DetachWeapon(weapon:EntityId) {
        if (weapon > 0) {
            var weaponIndex = weaponEntityIds.indexOf(weapon);
            if (weaponIndex != -1) {
                // Remove weapon from attachment-related systems
                weaponEntityIds[weaponIndex] = 0;
            }
        }
    }

    // returns the entity id of the newly detached weapon
    public function DetachNextWeapon() : EntityId {
        for (i in 0...weaponEntityIds.length) {
            if (weaponEntityIds[i] > 0) {
                var weaponId = weaponEntityIds[i];
                DetachWeapon(weaponId);
                return weaponId;
            }
        }
        return -1;
    }

}