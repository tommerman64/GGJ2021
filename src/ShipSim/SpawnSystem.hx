package shipSim;

import SimEntityReps.ProjectileEntityRepresentation;
import shipSim.physics.PhysData.ShipMovement;
import shipSim.ShipInventory;
import haxe.Log;
import SimEntityReps.CrateEntityRepresentation;
import SimEntityReps.PlayerShipEntityRepresentation;
import h2d.col.Circle;
import shipSim.physics.PhysData.ColliderData;
import SimEntityReps.PickupEntityRepresentation;
import hxd.Rand;
import h2d.Scene;
import shipSim.shootyThings.ShipWeaponData.WeaponLibrary;
import jamSim.Entity;
import jamSim.SimSystem;

class SpawnSystem extends SimSystem {
    var _scene:Scene;
    var _weaponLibrary:WeaponLibrary;
    var _inventorySlots:Array<ShipWeaponSlot>;
    var _inventories:Map<EntityId,ShipInventory>;
    var _random:Rand;
    var _colliderData:Map<EntityId, ColliderData>;

    var _shipMovement : Array<ShipMovement>;
    var _pickupData:Map<EntityId, PickupData>;

    var _shipRepresentations: Map<EntityId, PlayerShipEntityRepresentation>;
    var _crateRepresentations: Map<EntityId, CrateEntityRepresentation>;
    var _pickupRepresentations: Map<EntityId, PickupEntityRepresentation>;
    var _projectileRepresentations: Map<EntityId, ProjectileEntityRepresentation>;

    public function new() {
        super();
        _random = Rand.create();
    }

    public function SetScene(scene:Scene) {
        _scene = scene;
    }

    public function SetWeaponLibrary(library:WeaponLibrary) {
        _weaponLibrary = library;
    }

    public function SetupInventories(slots:Array<ShipWeaponSlot>, inventories:Map<EntityId,ShipInventory>){
        _inventorySlots = slots;
        _inventories = inventories;
    }

    public function SetColliderData(colliderData:Map<EntityId, ColliderData>) {
        _colliderData = colliderData;
    }

    public function SetShipMovement(shipMovement:Array<ShipMovement>) {
        _shipMovement = shipMovement;
    }

    public function SetRepresentations(
        ships:Map<EntityId, PlayerShipEntityRepresentation>,
        crates: Map<EntityId, CrateEntityRepresentation>,
        pickups: Map<EntityId, PickupEntityRepresentation>,
        projectiles: Map<EntityId, ProjectileEntityRepresentation>){
            _shipRepresentations = ships;
            _crateRepresentations = crates;
            _pickupRepresentations = pickups;
            _projectileRepresentations = projectiles;
    }


    public function SetPickupData(data:Map<EntityId, PickupData>) {
        _pickupData = data;
    }

    public override function Init(entities:Array<Entity>) {
        super.Init(entities);

        for (ent in entities) {
            OnNewEntity(ent);
        }
    }

    public override function OnEntityDestroyed(entity:EntityId) {
        _colliderData.remove(entity);
        for(movement in _shipMovement.filter(function(sm) {return sm.entityId == entity;})) {
            _shipMovement.remove(movement);
        }

        if(_inventories.exists(entity)){
            _inventories.remove(entity);
        }

        if(_shipRepresentations.exists(entity)){
            _scene.removeChild(_shipRepresentations[entity].GetObject());
            _shipRepresentations.remove(entity);
        }
        if(_crateRepresentations.exists(entity)){
            _scene.removeChild(_crateRepresentations[entity].GetObject());
            _crateRepresentations.remove(entity);
        }
        if(_pickupRepresentations.exists(entity)){
            _pickupRepresentations[entity].GetObject().parent.removeChild(_pickupRepresentations[entity].GetObject());
            _pickupRepresentations.remove(entity);
        }
        if(_projectileRepresentations.exists(entity)){
            _scene.removeChild(_projectileRepresentations[entity].GetObject());
            _projectileRepresentations.remove(entity);
        }
    }

    public function SpawnEntity(entity:Entity, x:Float, y:Float) {
        _sim.AddEntity(entity);
        GenerateColliderData(entity, x, y);
        if(entity.GetSystemTags().contains("Player")){
            InitializeShip(entity);
        }
        if(entity.GetSystemTags().contains("Crate")){
            InitializeCrate(entity);
        }
        if(entity.GetSystemTags().contains("Pickup")){
            InitializePickup(entity);
        }
        if(entity.GetSystemTags().contains("Projectile")){
            InitializeProjectile(entity);
        }
    }

    function GenerateColliderData(entity:Entity, x:Float, y:Float) {
        // Projectiles don't use the collision system
        if(entity.GetSystemTags().contains("Projectile")) {
            return;
        }

        // Make Collider Data
        var collider:ColliderData = new ColliderData();
        collider.obstacleCollisions = new Array<EntityId>();
        collider.playerCollisions = new Array<EntityId>();

        if(entity.GetSystemTags().contains("Player")) {
            collider.collider = new Circle(x, y, 20);
        }
        else if(entity.GetSystemTags().contains("Crate")) {
            collider.collider = new Circle(x, y, 25);
        }
        else if(entity.GetSystemTags().contains("Pickup")) {
            collider.collider = new Circle(x, y, 18);
        }

        _colliderData[entity.GetId()] = collider;
    }

    function InitializeShip(entity:Entity) {
        // create object in hxd scene
        var obj = new h2d.Object(_scene);
        var tile = hxd.Res.playership.toTile();
        tile = tile.center();
        var bmp = new h2d.Bitmap(tile, obj);
        bmp.scale(2.0/3.0);

        // load flames
        var boosterAnim = ResourceLoading.LoadAnimFromTexAtlas(hxd.Res.booster.toTexture(), hxd.Res.boosterMap);

        obj.addChild(boosterAnim);
        boosterAnim.loop = true;
        boosterAnim.scale(1.0/15.0);
        boosterAnim.setPosition(0, 27);

        // Make Movement Data
        var playerMovement:ShipMovement = new ShipMovement();
        playerMovement.entityId = entity.GetId();
        _shipMovement.push(playerMovement);

        // Set up inventory
        _inventories[entity.GetId()] = new ShipInventory();
        _inventories[entity.GetId()].InitializeWeaponSlots(_inventorySlots);

        var visRep = new PlayerShipEntityRepresentation(entity.GetId(), obj);
        visRep.InitFromGameData(_shipMovement, _colliderData);
        visRep.SetBoosterAnim(boosterAnim);
        _shipRepresentations[entity.GetId()] = visRep;
    }

    function InitializeCrate(entity:Entity) {
        // create object in hxd scene
        var obj = new h2d.Object(_scene);
        var tile = _random.random(2) > 0 ? hxd.Res.spacecrate.toTile() : hxd.Res.crate2.toTile();
        tile = tile.center();
        var bmp = new h2d.Bitmap(tile, obj);
        bmp.scale(2.0/3.0);

        var visRep = new CrateEntityRepresentation(entity.GetId(), obj);
        visRep.InitFromGameData(_colliderData);
        _crateRepresentations[entity.GetId()] = visRep;
    }

    function InitializePickup(entity:Entity) {
        // create object in hxd scene
        var obj = new h2d.Object(_scene);

        // Roll a random weapon
        var weaponIndex = _random.random(_weaponLibrary.length);

        _pickupData[entity.GetId()] = new PickupData(weaponIndex);

        var visRep = new PickupEntityRepresentation(entity.GetId(), obj);
        visRep.InitFromGameData(_colliderData, _pickupData,
            _weaponLibrary[weaponIndex].GetDrawable(true),
            _weaponLibrary[weaponIndex].GetDrawable(false));
        visRep.InjectPlayerReps(_shipRepresentations);
        _pickupRepresentations[entity.GetId()] = visRep;
    }

    function InitializeProjectile(entity:Entity) {
        // create object in hxd scene
        var obj = new h2d.Object(_scene);
        var tile = hxd.Res.laserBeam.toTile();
        tile = tile.center();
        var bmp = new h2d.Bitmap(tile, obj);
        bmp.scale(1.0/3.0);

        var visRep = new ProjectileEntityRepresentation(entity.GetId(), obj);
        _projectileRepresentations[entity.GetId()] = visRep;
    }
}