package shipSim.shootyThings;

import shipSim.ShipInventory.ShipWeaponSlot;
import h3d.Vector;
import hxd.fmt.hmd.Data.Index;
import shipSim.physics.PhysData;
import shipSim.physics.MovementSystem;
import jamSim.Entity;
import shipSim.Input;

class WeaponSystem extends MovementSystem {

    static var s_baseWeaponData:ShipWeaponData;

    var _baseWeaponCooldown:Int;
    var _inputSystem:InputSystem;
    var _cooldowns:Map<EntityId, Array<Int>>;

    var _inventories:Map<EntityId, ShipInventory>;
    var _colliderObjects: Map<EntityId,ColliderData>;

    public function new() {
        super();
        if (s_baseWeaponData == null) {
            s_baseWeaponData = new ShipWeaponData();
            s_baseWeaponData.cooldown = 6;
        }
        _cooldowns = new Map<EntityId, Array<Int>>();
    }

    public function InjectColliderData(col:Map<EntityId,ColliderData>) {
        _colliderObjects = col;
    }

    public function SetInputSystem(inpSys:InputSystem) {
        _inputSystem = inpSys;
    }

    public function SetInventory(invs:Map<EntityId, ShipInventory>) {
        _inventories = invs;
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
            _cooldowns[ent.GetId()] = new Array();
            _baseWeaponCooldown = 0;
        }
    }

    public override function Tick() {
        super.Tick();

        var inputIndex:Int = 0;
        for (playerId in _playerEntityIds) {
            var moveData = FindMovementData(playerId);
            var wantsToShoot = _inputSystem.GetInputState(inputIndex).Shoot;
            if (wantsToShoot) {
                TryShoot(playerId);
            }
            RunCooldowns(playerId);
            inputIndex++;
        }
    }

    function RunCooldowns(playerId:EntityId) {
        var cdIndex = 0;
        if (_baseWeaponCooldown > 0) {
            _baseWeaponCooldown--;
        }

        while (cdIndex < _cooldowns[playerId].length) {
            _cooldowns[playerId][cdIndex]--;
            cdIndex++;
        }
    }

    function GetWeapon(index:Int) : ShipWeaponData {
        // Should be getting this from the player inventories
        return s_baseWeaponData;
    }

    function GetCooldown(playerId:EntityId, weaponIndex:Int) :Int
    {
        return _cooldowns[playerId][0]; // (use index here once inventory is implemented)
    }

    function GetPlayerPosition(entityId:EntityId) : Vector {
        return new Vector(_colliderObjects[entityId].collider.x, _colliderObjects[entityId].collider.x);
    }

    public function TryShoot(playerId:EntityId) {
        var mov = FindMovementData(playerId);
        var pos = GetPlayerPosition(playerId);

        if (_baseWeaponCooldown <= 0) {
            s_baseWeaponData.OnFire(pos, new ShipWeaponSlot(new Vector()), mov);
            _baseWeaponCooldown = s_baseWeaponData.cooldown;
        }

        var inventory = _inventories[playerId];
        var slotIndex = 0;
        for (weapon in inventory.weaponEntityIds) {
            if (weapon == 0) {
                continue;
            }
            var weaponSlot = inventory.weaponSlots[slotIndex];
            if (GetCooldown(playerId, slotIndex) <= 0) {
                GetWeapon(slotIndex).OnFire(pos, weaponSlot, mov);
                _cooldowns[playerId][slotIndex] = GetWeapon(slotIndex).cooldown;
            }
            slotIndex++;
        }
    }
}