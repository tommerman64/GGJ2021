import hxd.snd.SoundGroup;
import haxe.Resource;
import h2d.col.Circle;
import hxd.snd.Manager;
import hxd.Key;
import hxd.Rand;
import h2d.col.Bounds;
import shipSim.physics.MovementSystem;
import h2d.Bitmap;
import h2d.Graphics;
import shipSim.shootyThings.ProjectileSystem;
import shipSim.shootyThings.ShipWeaponData;
import shipSim.shootyThings.WeaponSystem;
import shipSim.SpawnSystem;
import shipSim.ShipPickupSystem;
import shipSim.physics.ShipCollisionResolver;
import h2d.col.Point;
import hxd.clipper.Rect;
import jamSim.Entity;
import shipSim.physics.CollisionSystem;
import shipSim.physics.ShipLocomotionSystem;
import shipSim.Input.InputSystem;
import shipSim.physics.PhysData;
import shipSim.GameEntities;
import h3d.Vector;
import jamSim.Sim;
import SimEntityReps;
import shipSim.CratePlacement;
import shipSim.ShipInventory;
import shipSim.ReturnZoneSystem;

class Main extends hxd.App {

    static var SIM_FRAME_TIME =  1.0/60.0;
    var _music:hxd.snd.Channel;
    var _musicGroup: hxd.snd.ChannelGroup;
    var _musicSG: SoundGroup;

    var _boost:hxd.snd.Channel;
    var _boostGroup:hxd.snd.ChannelGroup;
    var _boostSG:SoundGroup;

    // sim and systems
    var _sim:jamSim.Sim;
    var _framerateText : h2d.Text;
    var _background:h2d.Bitmap;
    var _title:h2d.Bitmap;

    var _timeToNextFrame:Float;

    var _endRoundTimer:Float;

    var GameData = {
        shipMovement : new Array<ShipMovement>(),
        colliderData: new Map<EntityId, ColliderData>(),
        screenBounds: new Rect(0,0,1280,720),
        inventories: new Map<EntityId, ShipInventory>(),
        weaponLibrary: new WeaponLibrary(),
        pickupData: new Map<EntityId, PickupData>(),
    }

    var _shipRepresentations = new Map<EntityId, PlayerShipEntityRepresentation>();
    var _crateRepresentations = new Map<EntityId, CrateEntityRepresentation>();
    var _pickupRepresentations = new Map<EntityId, PickupEntityRepresentation>();
    var _projectileRepresentations = new Map<EntityId, ProjectileEntityRepresentation>();

    var spawnSystem:SpawnSystem;
    var locomotionSystem:ShipLocomotionSystem;

    var _returnZoneSys:ReturnZoneSystem;

    var dbgGraphics : h2d.Graphics;

    var _parallaxStars : Array<h2d.Bitmap>;

    override function init() {
        super.init();
        LoadStars();
        LoadFramerateText();

        if (hxd.res.Sound.supportedFormat(Mp3) || hxd.res.Sound.supportedFormat(OggVorbis))
        {
            _musicGroup = new hxd.snd.ChannelGroup("music");
            _musicSG = new hxd.snd.SoundGroup("musicSg");
            var res:hxd.res.Sound = hxd.Res.menuMusic;
            _music = res.play(true, 1, _musicGroup, _musicSG);
            _music.priority = 10; 

            _boostGroup = new hxd.snd.ChannelGroup("boost");
            _boostGroup.volume = 0;
            _boostSG = new hxd.snd.SoundGroup("boostSg");
            _boost = hxd.Res.boostLoop.play(true, 2, _boostGroup, _boostSG);
            _boost.priority = 1;
        }

        _shipRepresentations = new Map<EntityId, PlayerShipEntityRepresentation>();
        _crateRepresentations = new Map<EntityId, CrateEntityRepresentation>();
        _pickupRepresentations = new Map<EntityId, PickupEntityRepresentation>();
    }

    function LoadFramerateText() {
        _framerateText = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
        _framerateText.textColor = 0xFFFFFF;

        _framerateText.y = 20;
        _framerateText.x = 700;
        _framerateText.scale(2);
    }

    function LoadStars() {
        var backgroundTex = hxd.Res.spaaace.toTile();
        _background = new h2d.Bitmap(backgroundTex, s2d);
        _background.scale(2/3);
        _background.alpha = 0.24;

        _title = new Bitmap(hxd.Res.title.toTile().center(), s2d);

        _title.x = s2d.width/4;
        _title.y = s2d.height/2;
        _title.scale(0.66);

        _parallaxStars = new Array<h2d.Bitmap>();
        var parallaxSeed = Rand.create();
        for (i in 0...4) {
            var tile = i % 2 == 0 ? hxd.Res.Stars1.toTile() : hxd.Res.Stars2.toTile();
            _parallaxStars.push(new Bitmap(tile, s2d));
            _parallaxStars[_parallaxStars.length - 1].alpha = parallaxSeed.rand();
            _parallaxStars[_parallaxStars.length - 1].x = parallaxSeed.random(2*s2d.width) - s2d.width;
            _parallaxStars[_parallaxStars.length - 1].rotation = parallaxSeed.rand() * Math.PI;
        }
    }

    function GetBattleMusic(): hxd.res.Sound {
        if (hxd.res.Sound.supportedFormat(Mp3) || hxd.res.Sound.supportedFormat(OggVorbis))
        {
                return hxd.Res.battleMusic;
        }
        return null;
    }

    function StartGame() {
        _endRoundTimer = 2;
        _title.visible = false;
        _music.stop();
        _music = GetBattleMusic().play(true, 0.5, _musicGroup, _musicSG);

        _boost.stop();
        _boostGroup.volume = 0;
        _boost = hxd.Res.boostLoop.play(true, 1, _boostGroup, _boostSG);

        var inputSystem = new InputSystem();
        inputSystem.MapKeys(["Q".code, "W".code, "A".code, "S".code, "D".code]);
        inputSystem.MapKeys(["U".code, "I".code, "J".code, "K".code, "L".code]);

        locomotionSystem = new ShipLocomotionSystem();
        locomotionSystem.InjectShipMovementData(GameData.shipMovement);
        locomotionSystem.SetInputSystem(inputSystem);

        var collisionSystem = new CollisionSystem();
        collisionSystem.InjectShipMovementData(GameData.shipMovement);
        collisionSystem.InjectColliderData(GameData.colliderData);
        collisionSystem.SetPlayfieldSize(GameData.screenBounds.right, GameData.screenBounds.bottom);

        var collisionResolver = new ShipCollisionResolver();
        collisionResolver.InjectShipMovementData(GameData.shipMovement);
        collisionResolver.SetCollisionSystem(collisionSystem);

        var pickupSystem = new ShipPickupSystem();
        pickupSystem.SetCollisionSystem(collisionSystem);
        pickupSystem.SetPickupData(GameData.pickupData);
        pickupSystem.InjectColliderData(GameData.colliderData);
        pickupSystem.SetInputSystem(inputSystem);
        pickupSystem.SetShipMovement(GameData.shipMovement);

        spawnSystem = new SpawnSystem();
        spawnSystem.SetColliderData(GameData.colliderData);
        spawnSystem.SetRepresentations(_shipRepresentations, _crateRepresentations, _pickupRepresentations, _projectileRepresentations);
        spawnSystem.SetWeaponLibrary(GameData.weaponLibrary);
        spawnSystem.SetShipMovement(GameData.shipMovement);
        spawnSystem.SetPickupData(GameData.pickupData);
        spawnSystem.SetScene(s2d);

        var projectileSystem = new ProjectileSystem();
        projectileSystem.SetProjectileRepresentations(_projectileRepresentations);
        projectileSystem.SetColliderData(GameData.colliderData);
        projectileSystem.SetSpawner(spawnSystem);
        projectileSystem.SetPlayfieldSize(GameData.screenBounds.right, GameData.screenBounds.bottom);
        projectileSystem.SetPickupSystem(pickupSystem);

        var weaponSystem = new WeaponSystem();
        weaponSystem.SetInputSystem(inputSystem);
        weaponSystem.SetProjectileSystem(projectileSystem);
        weaponSystem.InjectShipMovementData(GameData.shipMovement);
        weaponSystem.InjectColliderData(GameData.colliderData);
        weaponSystem.InjectPickupData(GameData.pickupData);
        weaponSystem.SetWeaponLibrary(GameData.weaponLibrary);

        _returnZoneSys = new ReturnZoneSystem();
        _returnZoneSys.InjectColliderData(GameData.colliderData);
        _returnZoneSys.InjectPickupData(GameData.pickupData);
        _returnZoneSys.SetPickupSystem(pickupSystem);

        var bounds = GameData.screenBounds;
        var screenWidth = bounds.right - bounds.left;
        var screenHeight = bounds.bottom - bounds.top;
        _returnZoneSys.AddReturnZone(new Circle(bounds.left + (0.1 * screenWidth), bounds.bottom - (0.175 * screenHeight), 60));
        _returnZoneSys.AddMagnet(new Circle(bounds.left + (0.1 * screenWidth), bounds.bottom - (0.175 * screenHeight), 160));
        _returnZoneSys.AddReturnZone(new Circle(bounds.right - (0.1 * screenWidth), bounds.top + (0.175 * screenHeight), 60));
        _returnZoneSys.AddMagnet(new Circle(bounds.right - (0.1 * screenWidth), bounds.top + (0.175 * screenHeight), 160));

        _sim = new Sim();
        _sim.AddSystem(inputSystem);
        _sim.AddSystem(locomotionSystem);
        _sim.AddSystem(collisionSystem);
        _sim.AddSystem(collisionResolver);
        _sim.AddSystem(weaponSystem);
        _sim.AddSystem(pickupSystem);
        _sim.AddSystem(spawnSystem);
        _sim.AddSystem(projectileSystem);
        _sim.AddSystem(_returnZoneSys);

        var sndManager = Manager.get();
        sndManager.masterSoundGroup.maxAudible = 4;
        sndManager.masterChannelGroup.priority = 1;

        // Hook up weapons and inventories
        var slots = new Array<ShipWeaponSlot>();
        slots.push(new ShipWeaponSlot(new Vector(15, 0), 0.5));
        slots.push(new ShipWeaponSlot(new Vector(-15, 0), -0.5));
        slots.push(new ShipWeaponSlot(new Vector(30, 0), 1));
        slots.push(new ShipWeaponSlot(new Vector(-30, 0), -1));
        spawnSystem.SetupInventories(slots, GameData.inventories);
        pickupSystem.SetInventories(GameData.inventories);
        weaponSystem.SetInventory(GameData.inventories);
        InitializeWeaponLibrary();

        // Create player ships
        var player1 = MakePlayerEntity(bounds.left + (screenWidth * 0.12) , bounds.bottom - (screenHeight * 0.2));
        var player2 = MakePlayerEntity(bounds.right - (screenWidth * 0.12) , bounds.top + (screenHeight * 0.2));
        // Rotate for initial facing
        for(movement in GameData.shipMovement){
            if(movement.entityId == player1){
                movement.rotation = Math.PI/4;
            }
            if(movement.entityId == player2){
                movement.rotation = 5*Math.PI/4;
            }
        }

        var width = GameData.screenBounds.right - GameData.screenBounds.left;
        var height = GameData.screenBounds.bottom - GameData.screenBounds.top;
        var center = new Point(width/2, height/2);
        var placements = CratePlacement.GenerateCratePlacements(center, cast (width*0.6), cast (height*0.7), 12);
        for(crate in placements) {
            MakeCrateEntity(crate.x, crate.y);
        }

        _timeToNextFrame = SIM_FRAME_TIME;

        var mothershipTile = hxd.Res.mothership.toTile().center();

        var ship = new h2d.Bitmap(mothershipTile, s2d);
        var offset = new Point(-15,15);
        ship.scale(0.6);
        ship.rotate(Math.PI);
        var pos = new Point(_returnZoneSys.GetReturnZones()[0].x, _returnZoneSys.GetReturnZones()[0].y);
        pos = pos.add(offset);
        ship.setPosition(pos.x, pos.y);

        ship = new h2d.Bitmap(mothershipTile, s2d);
        ship.scale(0.6);
        pos = new Point(_returnZoneSys.GetReturnZones()[1].x, _returnZoneSys.GetReturnZones()[1].y);
        pos = pos.sub(offset);
        ship.setPosition(pos.x, pos.y);
        dbgGraphics = new h2d.Graphics(s2d);
    }

    function MakePlayerEntity(x:Float, y: Float): EntityId
    {
        var player = new PlayerShipEntity();
        spawnSystem.SpawnEntity(player, x, y);
        return player.GetId();
    }

    function MakeCrateEntity(x:Float, y:Float) {
        var crate = new SpaceCrate();
        spawnSystem.SpawnEntity(crate, x, y);
    }

    function MakePickupEntity(x:Float, y:Float) {
        var pickup = new Pickup();
        spawnSystem.SpawnEntity(pickup, x, y);
    }

    function InitializeWeaponLibrary() {
        var zapper = new ProjectileWeaponData();
        zapper.cooldown = 30;
        zapper.weight = 5;
        zapper.eqTile = hxd.Res.laserCannon.toTile();
        zapper.eqTile = zapper.eqTile.center();
        zapper.pickupTile = hxd.Res.pinkOrb.toTile();
        zapper.pickupTile = zapper.pickupTile.center();
        zapper.tileScale = 1;
        zapper.recoil = 10;
        zapper.recoilRotationAccelerator = 2;
        zapper.projectileSpeed = 40;
        zapper.sound = hxd.Res.laser;
        zapper.projectileDamage = 2;

        var fatMan = new ProjectileWeaponData();
        fatMan.cooldown = 60;
        fatMan.weight = 50;
        fatMan.eqTile = hxd.Res.fatman.toTile();
        fatMan.projectileTex = hxd.Res.fatman.toTile();
        fatMan.eqTile = fatMan.eqTile.center();
        fatMan.tileScale = .7;
        fatMan.pickupTile = hxd.Res.blueOrb.toTile();
        fatMan.pickupTile = fatMan.pickupTile.center();
        fatMan.recoil = 40;
        fatMan.recoilRotationAccelerator = 10;
        fatMan.projectileSpeed = 6;
        fatMan.sound = hxd.Res.fatmanLaunch;
        fatMan.projectileDamage = 3;

        var brrr = new ProjectileWeaponData();
        brrr.cooldown = 10;
        brrr.warmup = 90;
        brrr.weight = 5;
        brrr.eqAnimName = "minigun";
        brrr.pickupTile = hxd.Res.pinkOrb.toTile();
        brrr.pickupTile = brrr.pickupTile.center();
        brrr.tileScale = 1;
        brrr.recoil = 5;
        brrr.recoilRotationAccelerator = 3;
        brrr.projectileSpeed = 45;
        brrr.projectileTex = hxd.Res.redlaser.toTile();
        brrr.sound = hxd.Res.brrr;


        var prize = new ShipWeaponData();
        prize.eqAnimName = "crystal";
        prize.pickupAnimName = "crystal";
        prize.tileScale = 1.0/2.0;
        prize.cooldown = 0;
        prize.weight = 200;
        prize.SetIsCrystal();

        var armor = new ShipWeaponData();
        armor.eqTile = hxd.Res.armoricon.toTile();
        armor.pickupTile = hxd.Res.armoricon.toTile();
        armor.pickupTile = armor.pickupTile.center();
        armor.tileScale = 1;

        // PRIZE HAS TO BE FIRST
        GameData.weaponLibrary.push(prize);
        // ARMOR HAS TO BE SECOND
        GameData.weaponLibrary.push(armor);

        GameData.weaponLibrary.push(zapper);
        GameData.weaponLibrary.push(fatMan);
        GameData.weaponLibrary.push(brrr);
    }

    override function update(dt:Float) {
        // _framerateText.text = ""+1/dt+"\n" + s2d.width + "\n" + s2d.height;
        if (_sim == null) {
            _framerateText.text = "Press T to start!";
            _framerateText.text += "\nPlayer 1: Q/W to steer,\nA for throttle\nS to shoot\nD to drop all attachments";
            _framerateText.text += "\n\nPlayer 2: U/I to steer,\nJ for throttle\nK to shoot\nL to drop all attachments";
            _framerateText.text += "\n\nShoot crates to search for gear and armor.\nDeliver gear to your mothership\n or use them to fight!";
            _framerateText.text += "\nLook for the space crystal,\n whoever brings that to their ship wins!";

            if (Key.isPressed("T".code)) {
                StartGame();
            }
            return;
        }

        _framerateText.text = "";

        if (dbgGraphics != null) {
            dbgGraphics.clear();
        }
        _timeToNextFrame -= dt;
        if (_timeToNextFrame <= 0) {
            _timeToNextFrame += SIM_FRAME_TIME;
            // Update
            _sim.Tick();
            for (visRep in _shipRepresentations) {
                visRep.UpdateRepresentation(s2d);
            }
            for (visRep in _crateRepresentations) {
                visRep.UpdateRepresentation(s2d);
            }
            for (visRep in _pickupRepresentations) {
                visRep.UpdateRepresentation(s2d);
            }
            for (visRep in _projectileRepresentations) {
                visRep.UpdateRepresentation(s2d);
            }

            if(locomotionSystem != null){
                if(locomotionSystem.anyPlayerBoosting){
                    _boostGroup.volume = 1;
                }
                else{
                    _boostGroup.volume = 0;
                }
            }
            else{
                _boostGroup.volume = 0;
            }
        }

        if (_returnZoneSys.HasGameEnded())
        {
            _endRoundTimer-=dt;

            if (_endRoundTimer < 0) {
                EndRound(true);
            }
        }
        else {
            _endRoundTimer = 2;
        }

        /*
        if (hxd.Key.isDown("5".code)) {
            // put it back on top
            s2d.removeChild(dbgGraphics);
            s2d.addChild(dbgGraphics);
            dbgGraphics.beginFill(0xFF00FF, 0.8);
            for (col in GameData.colliderData) {
                dbgGraphics.drawCircle(col.collider.x, col.collider.y, col.collider.ray);
            }

            for (retZone in _returnZoneSys.GetReturnZones()) {
                dbgGraphics.drawCircle(retZone.x, retZone.y, retZone.ray);
            }
            dbgGraphics.beginFill(0x0000FF, 0.8);
            for (mag in _returnZoneSys.GetMagnets()) {
                dbgGraphics.drawCircle(mag.x, mag.y, mag.ray);
            }
        }

        if(hxd.Key.isPressed('6'.code)) {
            MakePickupEntity(300,600);
        }

        if(hxd.Key.isPressed('7'.code)) {
            // Get a crate
            var crates = _sim.GetEntities().filter(function(e) {return e.GetSystemTags().contains("Crate");});
            if(crates.length > 0) {
                var crate = crates[0];
                var crateCollider = GameData.colliderData[crate.GetId()].collider;
                var x = crateCollider.x;
                var y = crateCollider.y;
                _sim.DestroyEntity(crate.GetId()); // Yeet
                spawnSystem.SpawnEntity(new Pickup(), x, y);
            }
        }

        if(hxd.Key.isPressed('1'.code)) {
            for (id in GameData.inventories.keys()) {
                GameData.inventories[id].armor++;
            }
        }
        //*/

        var parallaxSpeed = 1.0;
        for(parallaxLayer in _parallaxStars) {
            parallaxLayer.x += dt * parallaxSpeed * 3;

            if (parallaxLayer.x > s2d.width) {
                parallaxLayer.x = - s2d.width * 2;
            }
            parallaxSpeed += .15;
        }
    }

    function EndRound(restart:Bool) {
        _sim = null;
        // clear GameData
        GameData.shipMovement = new Array<ShipMovement>();
        GameData.colliderData = new Map<EntityId, ColliderData>();
        GameData.screenBounds = new Rect(0,0,1280,720);
        GameData.inventories = new Map<EntityId, ShipInventory>();
        GameData.weaponLibrary = new WeaponLibrary();
        GameData.pickupData = new Map<EntityId, PickupData>();

        // clear representations
        _shipRepresentations = new Map<EntityId, PlayerShipEntityRepresentation>();
        _crateRepresentations = new Map<EntityId, CrateEntityRepresentation>();
        _pickupRepresentations = new Map<EntityId, PickupEntityRepresentation>();
        _projectileRepresentations = new Map<EntityId, ProjectileEntityRepresentation>();

        // clear member systems
        spawnSystem = null;
        locomotionSystem = null;
        _returnZoneSys = null;

        // dbg graphics and parallax stars
        // var dbgGraphics : h2d.Graphics;
        dbgGraphics = null;
        _parallaxStars = null;

        // clear s2d
        // setScene2D(new h2d.Scene());
        s2d = new h2d.Scene();

        LoadStars();
        LoadFramerateText();

        if (restart) {
            StartGame();
        }
    }

    static function main() {
        hxd.Res.initEmbed();
        // this is the same as hxd.Res.loader = new hxd.res.Loader(hxd.fs.EmbedFileSystem.create());
        new Main();
    }
}