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

    static var s_baseWeaponData:ProjectileWeaponData;

    var _baseWeaponCooldown:Int;
    var _inputSystem:InputSystem;
    var _projectileSystem:ProjectileSystem;
    var _cooldowns:Map<EntityId, Array<Int>>;
    var _warmups:Map<EntityId, Array<Int>>;

    var _inventories:Map<EntityId, ShipInventory>;
    var _colliderObjects: Map<EntityId,ColliderData>;
    var _pickupData:Map<EntityId,PickupData>;
    var _weaponLib:WeaponLibrary;

    public function new() {
        super();
        if (s_baseWeaponData == null) {
            s_baseWeaponData = new ProjectileWeaponData();
            s_baseWeaponData.cooldown = 60;
            s_baseWeaponData.projectileSpeed = 25;
            s_baseWeaponData.sound = hxd.Res.defaultGun;
        }
        _cooldowns = new Map<EntityId, Array<Int>>();
        _warmups = new Map<EntityId, Array<Int>>();
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
            _warmups[ent.GetId()] = new Array();
            _baseWeaponCooldown = 0;
        }
    }

    public override function OnEntityDestroyed(entId:EntityId) {
        super.OnEntityDestroyed(entId);
        _cooldowns.remove(entId);
        _warmups.remove(entId);
    }

    public function InitializeHeat(playerId:EntityId) {
        for(i in 0..._inventories[playerId].weaponSlots.length){
            _cooldowns[playerId].push(0);
            _warmups[playerId].push(0);
        }
    }

    public override function Tick() {
        super.Tick();

        var inputIndex:Int = 0;
        for (playerId in _playerEntityIds) {
            // Lazy initialize cooldowns/warmups
            if(_cooldowns[playerId].length == 0){
                InitializeHeat(playerId);
            }

            var wantsToShoot = _inputSystem.GetInputState(inputIndex).Shoot;
            if (wantsToShoot) {
                TryShoot(playerId);
            }
            else {
                var inventory = _inventories[playerId];
                for (weapon in inventory.weaponEntityIds) {
                    if (weapon == 0) {
                        continue;
                    }
        
                    _pickupData[weapon].SetShooting(false);
                }
            }
            UpdateHeat(playerId, wantsToShoot);
            inputIndex++;
        }
    }

    function UpdateHeat(playerId:EntityId, wantsToShoot:Bool) {
        if (_baseWeaponCooldown > 0) {
            _baseWeaponCooldown--;
        }

        var cdIndex = 0;
        while (cdIndex < _cooldowns[playerId].length) {
            _cooldowns[playerId][cdIndex] = Std.int(Math.max(0, _cooldowns[playerId][cdIndex]-1));
            cdIndex++;
        }

        var index = 0;
        while (index < _warmups[playerId].length) {
            if(_inventories[playerId].weaponEntityIds[index] > 0){
                if(wantsToShoot){
                    _warmups[playerId][index] = Std.int(Math.min(200, _warmups[playerId][index]+1));
                }
                else {
                    _warmups[playerId][index] = Std.int(Math.max(0, _warmups[playerId][index]-1));
                }
            }
            index++;
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
        return _cooldowns[playerId][weaponIndex];
    }
    function GetWarmup(playerId:EntityId, weaponIndex:Int) :Int
    {
        return _warmups[playerId][weaponIndex];
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

            _pickupData[weapon].SetShooting(true);
            hasWeapons = true;
            var weaponSlot = inventory.weaponSlots[slotIndex];
            if (GetCooldown(playerId, slotIndex) <= 0 && GetWarmup(playerId, slotIndex) > GetWeapon(inventory, slotIndex).warmup) {
                Log.trace("shooting from weapon slot" + slotIndex);
                GetWeapon(inventory, slotIndex).OnFire(pos, weaponSlot, mov, _projectileSystem);
                _cooldowns[playerId][slotIndex] = GetWeapon(inventory, slotIndex).cooldown;
                _warmups[playerId][slotIndex] = GetWeapon(inventory, slotIndex).warmup;
            }
            slotIndex++;
        }


        if (_baseWeaponCooldown <= 0) {
            s_baseWeaponData.OnFire(pos, new ShipWeaponSlot(new Vector(), 0), mov, _projectileSystem);
            _baseWeaponCooldown = s_baseWeaponData.cooldown;
        }
    }
}