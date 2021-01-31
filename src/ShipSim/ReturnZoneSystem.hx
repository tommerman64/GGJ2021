package shipSim;

import h2d.col.Point;
import h2d.col.Bounds;
import hxd.clipper.Rect;
import shipSim.physics.PhysData;
import jamSim.SimSystem;
import jamSim.Entity;
import shipSim.ShipInventory;
import shipSim.shootyThings.ShipWeaponData;

class ReturnZoneSystem extends SimSystem {
    var _pickupEntityIds : Array<EntityId>;
    var _pickupData:Map<EntityId,PickupData>;
    var _weaponLib:WeaponLibrary;
    var _colliderObjects: Map<EntityId,ColliderData>;

    var _returnZones : Array<Bounds>;

    public override function new() {
        super();
        _pickupEntityIds = new Array<EntityId>();
        _returnZones = new Array<Bounds>();
    }

    public function InjectColliderData(col:Map<EntityId,ColliderData>) {
        _colliderObjects = col;
    }

    public function SetWeaponLibrary(lib:WeaponLibrary) {
        _weaponLib = lib;
    }

    public function InjectPickupData(pu:Map<EntityId,PickupData>) {
        _pickupData = pu;
    }

    public function AddReturnZone(bounds:Bounds) {
        _returnZones.push(bounds);
    }

    public override function Init(entities:Array<Entity>) {
        super.Init(entities);

        for (ent in entities) {
            OnNewEntity(ent);
        }
    }

    public override function OnNewEntity(ent:Entity) {
        super.OnNewEntity(ent);
        if (ent.GetSystemTags().contains("Pickup")) {
            _pickupEntityIds.push(ent.GetId());
        }
    }

    public override function LateTick() {
        super.LateTick();

        for(bounds in _returnZones) {
            for (eId in _pickupEntityIds) {
                var col = _colliderObjects[eId];
                var position : Point = new Point(col.collider.x, col.collider.y);

                if (bounds.contains(position)) {
                    // give someone points
                    _sim.DestroyEntity(eId);
                    _pickupEntityIds.remove(eId);
                }
            }
        }
    }

    public function GetReturnZones() : Array<Bounds> {
        return _returnZones;
    }
}