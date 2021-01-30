import hxd.Rand;
import h2d.col.Circle;
import jamSim.Entity;
import shipSim.CollisionSystem;
import shipSim.Input.InputSystem;
import shipSim.PhysData;
import shipSim.GameEntities;
import h2d.Bitmap;
import h2d.Tile;
import hxd.Key;
import h3d.Vector;
import jamSim.Sim;
import SimEntityReps;

class Main extends hxd.App {

    static var SIM_FRAME_TIME =  1.0/60.0;
    var _music:hxd.snd.Channel;

    // sim and systems
    var _sim:jamSim.Sim;
    var _framerateText : h2d.Text;

    var _timeToNextFrame:Float;

    var GameData = {
        shipMovement : new Array<shipSim.ShipMovement>(),
        colliderData: new Array<ColliderData>(),
    }

    var _playerBitmaps : Array<h2d.Bitmap>;

    var _visualRepresentations : Array<EnityRepresentation>;

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

        _visualRepresentations = new Array<EnityRepresentation>();

        var inputSystem = new InputSystem();
        inputSystem.MapKeys(["A".code, "S".code, "D".code, "F".code, "G".code]);

        var locomotionSystem = new shipSim.ShipLocomotionSystem();
        locomotionSystem.InjectShipMovementData(GameData.shipMovement);
        locomotionSystem.SetInputSystem(inputSystem);

        var collisionSystem = new CollisionSystem();
        collisionSystem.InjectShipMovementData(GameData.shipMovement);
        collisionSystem.InjectColliderData(GameData.colliderData);

        _sim = new Sim();
        _sim.AddSystem(inputSystem);
        _sim.AddSystem(locomotionSystem);
        _sim.AddSystem(collisionSystem);

        MakePlayerEntity(100, 100);

        PlaceCrates(3);

        _timeToNextFrame = SIM_FRAME_TIME;
    }

    function MakePlayerEntity(x:Float, y: Float)
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
        collider.collider = new Circle(x, y, 15);

        // collider data is indexed on ID-1
        if (GameData.colliderData.length > player.GetId() - 1) {
            GameData.colliderData[player.GetId() - 1] = collider; // I think this is bad????
        }
        else {
            while (GameData.colliderData.length < player.GetId() - 1) {
                GameData.colliderData.push(new ColliderData());
            }
            GameData.colliderData.push(collider);
        }

        // create object in hxd scene
        var obj = new h2d.Object(s2d);
        var tile = hxd.Res.lilship.toTile();
        tile = tile.center();
        var bmp = new h2d.Bitmap(tile, obj);

        var visRep = new PlayerShipEntityRepresentation(player.GetId(), obj);
        visRep.InitFromGameData(GameData.shipMovement, GameData.colliderData);
        _visualRepresentations.push(visRep);
    }

    function PlaceCrates(count: Int) {
        var index = 0;
        while(index < count) {
            index++;
        }
    }

    override function update(dt:Float) {
        _framerateText.text = ""+1/dt+"\n" + s2d.width + "\n" + s2d.height;
        _timeToNextFrame -= dt;
        if (_timeToNextFrame <= 0) {
            _timeToNextFrame += SIM_FRAME_TIME;
            // Update
            _sim.Tick();
            for (visRep in _visualRepresentations) {
                visRep.UpdateRepresentation();
            }
        }
    }

    static function main() {
        hxd.Res.initEmbed();
        // this is the same as hxd.Res.loader = new hxd.res.Loader(hxd.fs.EmbedFileSystem.create());
        new Main();
    }
}