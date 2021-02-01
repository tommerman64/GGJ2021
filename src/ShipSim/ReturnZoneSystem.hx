package shipSim;

import js.lib.WebAssembly.WebAssemblyInstantiatedSource;
import h3d.Vector;
import h2d.col.Circle;
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
    var _colliderObjects: Map<EntityId,ColliderData>;
    var _pickupSystem:ShipPickupSystem;

    var _returnZones : Array<Circle>;
    var _magnets : Array<Circle>;

    var _gameEnd : Bool = false;

    var _winnerPos : Point;

    public override function new() {
        super();
        _pickupEntityIds = new Array<EntityId>();
        _returnZones = new Array<Circle>();
        _magnets = new Array<Circle>();
    }

    public function InjectColliderData(col:Map<EntityId,ColliderData>) {
        _colliderObjects = col;
    }

    public function InjectPickupData(pu:Map<EntityId,PickupData>) {
        _pickupData = pu;
    }

    public function SetPickupSystem(sys:ShipPickupSystem) {
        _pickupSystem = sys;
    }

    public function AddReturnZone(zone:Circle) {
        _returnZones.push(zone);
    }

    public function AddMagnet(magnet:Circle) {
        _magnets.push(magnet);
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

        for(zone in _returnZones) {
            for (eId in _pickupEntityIds) {
                var col = _colliderObjects[eId];
                var position : Point = new Point(col.collider.x, col.collider.y);
                if (zone.contains(position)) {
                    if (_pickupData[eId].GetWeaponLibIndex() == 0) { // it was the crystal, game is over
                        var winSound = hxd.Res.win.play();
                        winSound.priority = 9;
                        winSound.onEnd = function() {hxd.Res.ding.play().priority = 9;}
                        _gameEnd = true;
                        _winnerPos = new Point(zone.x, zone.y);
                    }
                    else {
                        hxd.Res.score.play().priority = 2;
                    }
                    _sim.DestroyEntity(eId);
                    _pickupEntityIds.remove(eId);
                }
            }
        }

        for(magnet in _magnets) {
            for (eId in _pickupEntityIds) {
                var col = _colliderObjects[eId];
                var position : Point = new Point(col.collider.x, col.collider.y);
                if (magnet.contains(position)) {
                    var targetVec = new Vector(magnet.x - col.collider.x, magnet.y - col.collider.y);
                    targetVec.normalizeFast();
                    targetVec.scale3(100);
                    _pickupSystem.AdjustDrift(eId, targetVec);
                }
            }
        }
    }

    public override function OnEntityDestroyed(eId:EntityId) {
        if (_pickupEntityIds.contains(eId)) {
            _pickupEntityIds.remove(eId);
        }
    }

    public function HasGameEnded() {
        return _gameEnd;
    }

    public function GetReturnZones() : Array<Circle> {
        return _returnZones;
    }

    public function GetMagnets() : Array<Circle> {
        return _magnets;
    }

    public function GetWinnerPosition() : Point {
        if (_winnerPos == null) {
            return new Point();
        }
        return _winnerPos;
    }
}