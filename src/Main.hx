import shipSim.ShipInventory;
import shipSim.ShipPickupSystem;
import shipSim.physics.ShipCollisionResolver;
import h2d.col.Point;
import hxd.clipper.Rect;
import h2d.col.Bounds;
import hxd.Rand;
import h2d.col.Circle;
import jamSim.Entity;
import shipSim.physics.CollisionSystem;
import shipSim.physics.ShipLocomotionSystem;
import shipSim.Input.InputSystem;
import shipSim.physics.PhysData;
import shipSim.GameEntities;
import h2d.Bitmap;
import h2d.Tile;
import hxd.Key;
import h3d.Vector;
import jamSim.Sim;
import SimEntityReps;
import shipSim.CratePlacement;

class Main extends hxd.App {

    static var SIM_FRAME_TIME =  1.0/60.0;
    var _music:hxd.snd.Channel;

    // sim and systems
    var _sim:jamSim.Sim;
    var _framerateText : h2d.Text;

    var _timeToNextFrame:Float;

    var GameData = {
        shipMovement : new Array<ShipMovement>(),
        colliderData: new Map<EntityId, ColliderData>(),
        screenBounds: new Rect(0,0,1280,720),
        inventories: new Map<EntityId, ShipInventory>(),
    }

    var _playerBitmaps : Array<h2d.Bitmap>;

    var _shipRepresentations = new Map<EntityId, PlayerShipEntityRepresentation>();
    var _crateRepresentations = new Map<EntityId, CrateEntityRepresentation>();
    var _pickupRepresentations = new Map<EntityId, PickupEntityRepresentation>();

    var dbgGraphics : h2d.Graphics;

    override function init() {
        super.init();

        _framerateText = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
        _framerateText.textColor = 0xFFFFFF;

        _framerateText.y = 20;
        _framerateText.x = 20;
        _framerateText.scale(2);

        if (hxd.res.Sound.supportedFormat(Mp3) || hxd.res.Sound.supportedFormat(OggVorbis))
        {
            var res:hxd.res.Sound = hxd.Res.babycobraz;
            _music = res.play(true);
        }

        _shipRepresentations = new Map<EntityId, PlayerShipEntityRepresentation>();
        _crateRepresentations = new Map<EntityId, CrateEntityRepresentation>();
        _pickupRepresentations = new Map<EntityId, PickupEntityRepresentation>();

        var inputSystem = new InputSystem();
        inputSystem.MapKeys(["A".code, "S".code, "D".code, "F".code, "G".code]);
        inputSystem.MapKeys(["J".code, "K".code, "L".code, "I".code, "O".code]);

        var locomotionSystem = new ShipLocomotionSystem();
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

        _sim = new Sim();
        _sim.AddSystem(inputSystem);
        _sim.AddSystem(locomotionSystem);
        _sim.AddSystem(collisionSystem);
        _sim.AddSystem(collisionResolver);
        _sim.AddSystem(pickupSystem);

        var player1Id = MakePlayerEntity(100, 100);
        var player2Id = MakePlayerEntity(300, 300);

        var slots = new Array<ShipWeaponSlot>();
        slots.push(new ShipWeaponSlot(new Vector(50, 0)));

        GameData.inventories[player1Id] = new ShipInventory();
        GameData.inventories[player1Id].InitializeWeaponSlots(slots);
        GameData.inventories[player2Id] = new ShipInventory();
        GameData.inventories[player2Id].InitializeWeaponSlots(slots);

        pickupSystem.SetInventories(GameData.inventories);
        pickupSystem.SetRepresentations(_pickupRepresentations, _shipRepresentations);

        var width = GameData.screenBounds.right - GameData.screenBounds.left;
        var height = GameData.screenBounds.bottom - GameData.screenBounds.top;
        var center = new Point(width/2, height/2);
        var placements = CratePlacement.GenerateCratePlacements(center, cast (width*0.6), cast (height*0.7), 12);
        for(crate in placements) {
            MakeCrateEntity(crate.x, crate.y);
        }

        _timeToNextFrame = SIM_FRAME_TIME;

        dbgGraphics = new h2d.Graphics(s2d);
    }

    function MakePlayerEntity(x:Float, y: Float): EntityId
    {
        var player = new PlayerShipEntity();
        _sim.AddEntity(player);

        // Make Movement Data
        var playerMovement:ShipMovement = new ShipMovement();
        playerMovement.entityId = player.GetId();
        GameData.shipMovement.push(playerMovement);

        // Make Collider Data
        var collider:ColliderData = new ColliderData();
        collider.obstacleCollisions = new Array<EntityId>();
        collider.playerCollisions = new Array<EntityId>();
        collider.collider = new Circle(x, y, 20);

        PlaceColliderData(player.GetId(), collider);

        // create object in hxd scene
        var obj = new h2d.Object(s2d);
        var tile = hxd.Res.playership.toTile();
        tile = tile.center();
        var bmp = new h2d.Bitmap(tile, obj);
        bmp.scale(2.0/3.0);

        var visRep = new PlayerShipEntityRepresentation(player.GetId(), obj);
        visRep.InitFromGameData(GameData.shipMovement, GameData.colliderData);
        _shipRepresentations[player.GetId()] = visRep;

        return player.GetId();
    }

    function MakeCrateEntity(x:Float, y:Float) {
        var crate = new SpaceCrate();

        _sim.AddEntity(crate);

        // Make Collider Data
        var collider:ColliderData = new ColliderData();
        collider.obstacleCollisions = new Array<EntityId>();
        collider.playerCollisions = new Array<EntityId>();
        collider.collider = new Circle(x, y, 25);

        PlaceColliderData(crate.GetId(), collider);

        // create object in hxd scene
        var obj = new h2d.Object(s2d);
        var tile = hxd.Res.spacecrate.toTile();
        tile = tile.center();
        var bmp = new h2d.Bitmap(tile, obj);
        bmp.scale(2.0/3.0);
        obj.rotate(x + y);

        var visRep = new CrateEntityRepresentation(crate.GetId(), obj);
        visRep.InitFromGameData(GameData.colliderData);
        _crateRepresentations[crate.GetId()] = visRep;
    }

    function MakePickupEntity(x:Float, y:Float) {
        var pickup = new Pickup();

        _sim.AddEntity(pickup);

        // Make Collider Data
        var collider:ColliderData = new ColliderData();
        collider.obstacleCollisions = new Array<EntityId>();
        collider.playerCollisions = new Array<EntityId>();
        collider.collider = new Circle(x, y, 18);

        PlaceColliderData(pickup.GetId(), collider);

        // create object in hxd scene
        var obj = new h2d.Object(s2d);
        var tile = hxd.Res.spacecrate.toTile();
        tile = tile.center();
        var bmp = new h2d.Bitmap(tile, obj);
        bmp.scale(2.0/3.6);
        obj.rotate(x + y);

        var visRep = new PickupEntityRepresentation(pickup.GetId(), obj);
        visRep.InitFromGameData(GameData.colliderData);
        _pickupRepresentations[pickup.GetId()] = visRep;
    }

    function PlaceColliderData(id:EntityId, collider:ColliderData) {
            GameData.colliderData[id] = collider;
    }

    override function update(dt:Float) {
        dbgGraphics.clear();
        _framerateText.text = ""+1/dt+"\n" + s2d.width + "\n" + s2d.height;
        _timeToNextFrame -= dt;
        if (_timeToNextFrame <= 0) {
            _timeToNextFrame += SIM_FRAME_TIME;
            // Update
            _sim.Tick();
            for (visRep in _shipRepresentations) {
                visRep.UpdateRepresentation();
            }
            for (visRep in _crateRepresentations) {
                visRep.UpdateRepresentation();
            }
            for (visRep in _pickupRepresentations) {
                visRep.UpdateRepresentation();
            }

            if (hxd.Key.isDown("5".code)) {
                dbgGraphics.beginFill(0xFF00FF, 0.8);
                for (col in GameData.colliderData) {
                    dbgGraphics.drawCircle(col.collider.x, col.collider.y, col.collider.ray);
                }
            }

            if(hxd.Key.isPressed('6'.code)) {
                MakePickupEntity(300,600);
            }
        }
    }

    static function main() {
        hxd.Res.initEmbed();
        // this is the same as hxd.Res.loader = new hxd.res.Loader(hxd.fs.EmbedFileSystem.create());
        new Main();
    }
}