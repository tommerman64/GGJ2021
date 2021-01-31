package shipSim.physics;

import hxd.Pixels.Channel;
import hxd.snd.ChannelGroup;
import h3d.Vector;
import shipSim.Input.InputState;
import shipSim.Input.InputSystem;
import shipSim.physics.PhysData;
import shipSim.physics.MovementSystem;
import jamSim.Entity;

class ShipLocomotionSystem extends MovementSystem {

    // MOVEMENT CONSTS
    static var BASE_ROTATIONAL_ACCEL = 10 * Math.PI;
    static var MAX_SPEED = 200;
    static var BOOSTER_ACCEL = 60;
    static var NATURAL_DECEL = 5;
    static var MAX_ROTATION = Math.PI;

    var _inputSystem:InputSystem;
    var _anyPlayerBoosting:Bool;
    var _boostAudio:ChannelGroup;

    public function new() {
        super();
    }

    public function SetInputSystem(inpSys:InputSystem) {
        _inputSystem = inpSys;
    }

    public override function Init(entities:Array<Entity>) {
        super.Init(entities);

        for (ent in entities) {
            OnNewEntity(ent);
        }

        _anyPlayerBoosting = false;
        _boostAudio = new hxd.snd.ChannelGroup("booster");
        _boostAudio.volume = 0;
        hxd.Res.boostLoop.play(true, 1, _boostAudio).priority = 1;
    }

    private function UpdateMovementData(inp:InputState, movement:ShipMovement) {
        // velocity and rotational velocity should naturally decelerate
        var targetVelocity = movement.GetForward();
        movement.velocity = GameMath.VecMoveTowards(movement.velocity, new Vector(), NATURAL_DECEL * MovementSystem.SIM_FRAME_LENGTH);
        movement.rotationalVelocity = GameMath.MoveTowards(movement.rotationalVelocity, 0, BASE_ROTATIONAL_ACCEL / 100);

        if (inp.Throttle) {
            _anyPlayerBoosting = true;
            targetVelocity.scale3(MAX_SPEED);
            // move current velocity towards that by acceleration value
            movement.velocity = GameMath.VecMoveTowards(movement.velocity, targetVelocity, BOOSTER_ACCEL * MovementSystem.SIM_FRAME_LENGTH);
        }

        if(movement.velocity.length() > 2.0*MAX_SPEED){
            movement.velocity.normalize();
            movement.velocity.scale3(2.0*MAX_SPEED);
        }

        movement.boosting = inp.Throttle;

        // Don't allow rotational acceleration beyond the max
        var rotationInput : Float = 0;
        if (inp.Left && movement.rotationalVelocity > -MAX_ROTATION) {
            rotationInput -= BASE_ROTATIONAL_ACCEL * MovementSystem.SIM_FRAME_LENGTH;
        }

        if (inp.Right && movement.rotationalVelocity < MAX_ROTATION) {
            rotationInput += BASE_ROTATIONAL_ACCEL * MovementSystem.SIM_FRAME_LENGTH;
        }

        // Set rotation then clamp the true max
        movement.rotationalVelocity += rotationInput;
        movement.rotationalVelocity = Math.min(movement.rotationalVelocity, 2*MAX_ROTATION);
        movement.rotationalVelocity = Math.max(movement.rotationalVelocity, -2*MAX_ROTATION);

        movement.rotation += movement.rotationalVelocity * MovementSystem.SIM_FRAME_LENGTH;
    }

    public override function Tick() {
        super.Tick();
        var inputIndex:Int = 0;
        for (playerId in _playerEntityIds) {
            var moveData = FindMovementData(playerId);
            UpdateMovementData(_inputSystem.GetInputState(inputIndex), moveData);
            inputIndex++;
            if (inputIndex >= _inputSystem.GetPlayerCount())
            {
                break;
            }
        }

        if(_anyPlayerBoosting){
            _boostAudio.volume = 1;
        }
        else {
            _boostAudio.volume = 0;
        }
        _anyPlayerBoosting = false;
    }
}