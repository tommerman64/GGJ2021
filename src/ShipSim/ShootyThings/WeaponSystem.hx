package shipSim.shootyThings;

import h3d.Vector;
import hxd.fmt.hmd.Data.Index;
import shipSim.physics.MovementSystem;
import jamSim.Entity;
import shipSim.Input;

class WeaponSystem extends MovementSystem {

    static var s_baseWeaponData:ShipWeaponData;
    var _inputSystem:InputSystem;
    var _inventories:Map<EntityId, ShipInventory>;
    var _cooldowns:Map<EntityId, Array<Int>>;

    public function new() {
        super();
        if (s_baseWeaponData == null) {
            s_baseWeaponData = new ShipWeaponData();
            s_baseWeaponData.cooldown = 6;
        }
        _cooldowns = new Map<EntityId, Array<Int>>();
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
        }
    }

    public override function Tick() {
        super.Tick();

        var inputIndex:Int = 0;
        for (playerId in _playerEntityIds) {
            var moveData = FindMovementData(playerId);
            var wantsToShoot = _inputSystem.GetInputState(inputIndex).Shoot;
            if (wantsToShoot) {
                TryShoot(playerId, 0);
            }
            RunCooldowns(playerId);
            inputIndex++;
        }
    }

    function RunCooldowns(playerId:EntityId) {
        var cdIndex = 0;
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

    public function TryShoot(playerId:EntityId, weaponIndex:Int) {
        if (GetCooldown(playerId, weaponIndex) <= 0) {
            GetWeapon(weaponIndex).OnFire(new Vector(), new Vector(), new Vector(), FindMovementData(playerId));
            _cooldowns[playerId][weaponIndex] = GetWeapon(weaponIndex).cooldown;
        }
    }
}