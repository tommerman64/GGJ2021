package shipSim.shootyThings;
import shipSim.shootyThings.ShipWeaponData.ProjectileWeaponData;
import shipSim.ShipInventory.PickupData;
import shipSim.shootyThings.ShipWeaponData.WeaponLibrary;
import haxe.Log;
import shipSim.ShipInventory.ShipWeaponSlot;
import h3d.Vector;
import shipSim.physics.PhysData;
import shipSim.physics.MovementSystem;
import jamSim.Entity;
import shipSim.Input;

class WeaponSystem extends MovementSystem {

    static var s_baseWeaponData:ShipWeaponData;

    var _baseWeaponCooldown:Int;
    var _inputSystem:InputSystem;
    var _projectileSystem:ProjectileSystem;
    var _cooldowns:Map<EntityId, Array<Int>>;

    var _inventories:Map<EntityId, ShipInventory>;
    var _colliderObjects: Map<EntityId,ColliderData>;
    var _pickupData:Map<EntityId,PickupData>;
    var _weaponLib:WeaponLibrary;

    public function new() {
        super();
        if (s_baseWeaponData == null) {
            s_baseWeaponData = new ProjectileWeaponData();
            s_baseWeaponData.cooldown = 6;
        }
        _cooldowns = new Map<EntityId, Array<Int>>();
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

    public function SetInputSystem(inpSys:InputSystem) {
        _inputSystem = inpSys;
    }

    public function SetProjectileSystem(prjSys:ProjectileSystem) {
        _projectileSystem = prjSys;
    }

    public function SetInventory(invs:Map<EntityId, ShipInventory>) {
        _inventories = invs;
        InitializeCooldowns();
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

    public function InitializeCooldowns() {
        for (playerId in _playerEntityIds) {
            for (slot in _inventories[playerId].weaponSlots) {
                _cooldowns[playerId].push(0);
            }
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

    function GetWeapon(inventory:ShipInventory, index:Int) : ShipWeaponData {
        // Should be getting this from the player inventories
        if (_pickupData == null) {
            return s_baseWeaponData;
        }

        if (_weaponLib == null) {
            return s_baseWeaponData;
        }

        var weaponEntityId = inventory.weaponEntityIds[index];
        var pickupIndex = _pickupData[weaponEntityId].GetWeaponLibIndex();
        return _weaponLib[pickupIndex];
    }

    function GetCooldown(playerId:EntityId, weaponIndex:Int) :Int
    {
        return _cooldowns[playerId][weaponIndex]; // (use index here once inventory is implemented)
    }

    function GetPlayerPosition(entityId:EntityId) : Vector {
        return new Vector(_colliderObjects[entityId].collider.x, _colliderObjects[entityId].collider.y);
    }

    public function TryShoot(playerId:EntityId) {
        var mov = FindMovementData(playerId);
        var pos = GetPlayerPosition(playerId);

        var hasWeapons:Bool = false;

        var inventory = _inventories[playerId];
        var slotIndex = 0;
        for (weapon in inventory.weaponEntityIds) {
            if (weapon == 0) {
                slotIndex++;
                continue;
            }

            hasWeapons = true;
            var weaponSlot = inventory.weaponSlots[slotIndex];
            if (GetCooldown(playerId, slotIndex) <= 0) {
                Log.trace("shooting from weapon slot" + slotIndex);
                GetWeapon(inventory, slotIndex).OnFire(pos, weaponSlot, mov, _projectileSystem);
                _cooldowns[playerId][slotIndex] = GetWeapon(inventory, slotIndex).cooldown;
            }
            slotIndex++;
        }


        if (_baseWeaponCooldown <= 0 && !hasWeapons) {
            s_baseWeaponData.OnFire(pos, new ShipWeaponSlot(new Vector()), mov, _projectileSystem);
            _baseWeaponCooldown = s_baseWeaponData.cooldown;
        }
    }
}