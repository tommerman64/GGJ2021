package shipSim;

import jamSim.Entity;
import h3d.Vector;

class ShipWeaponSlot {
    // Where to place the weapon relative to the ship
    public var relativeRotation:Float;
    public var relativePosition:Vector;
    // Modifiers for the translation and rotation recoil of the weapon respectively
    public var recoilAngle:Float;
    public var spinFactor:Float;
}

class ShipInventory {
    public var weaponSlots:Array<ShipWeaponSlot>;
    public var weaponEntityIds:Array<EntityId>; // Entity IDs of attached weapons

    public function InitializeWeaponSlots(slots:Array<ShipWeaponSlot>) {
        weaponSlots = slots;
        weaponEntityIds = new Array<EntityId>();
        weaponEntityIds.resize(weaponSlots.length);
    }

    public function AttachWeaponToFirstOpenIndex(weapon:Entity) {
        if (weapon.IsValid()) {
            var index = weaponEntityIds.indexOf(0);
            if (index != -1) {
                AttachWeaponAtIndex(weapon, index);
            }
        }
    }

    public function AttachWeaponAtIndex(weapon:Entity, index:Int) {
        if (index < weaponEntityIds.length && index >= 0 && weapon.IsValid()) {
            // Make sure we're not double-attaching the same weapon
            var existingIndex = weaponEntityIds.indexOf(weapon.GetId());
            if (existingIndex == -1) {
                if (weaponEntityIds[index] == 0)
                    // Add weapon to attachment-related systems
                    weaponEntityIds[index] = weapon.GetId();
            }
        }
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

    public function Jettison() {
        for (weapon in weaponEntityIds) {
            DetachWeapon(weapon);
        }
    }
}