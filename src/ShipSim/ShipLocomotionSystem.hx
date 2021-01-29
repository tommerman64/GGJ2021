package shipSim;

import h3d.Vector;
import shipSim.Input.InputState;
import shipSim.Input.InputSystem;
import shipSim.PhysData;
import shipSim.MovementSystem;
import jamSim.Entity;

class ShipLocomotionSystem extends MovementSystem {

    // MOVEMENT CONSTS
    static var BASE_ROTATIONAL_ACCEL = 2 * Math.PI;
    static var SIM_FRAME_LENGTH = 1.0/60.0;
    static var MAX_SPEED = 20;
    static var BOOSTER_ACCEL = 15;
    static var NATURAL_DECEL = 5;

    var _inputSystem:InputSystem;

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
    }

    private function UpdateMovementData(inp:InputState, movement:ShipMovement) {
        // velocity and rotational velocity should naturally decelerate
        var targetVelocity = new Vector();
        movement.velocity = GameMath.VecMoveTowards(movement.velocity, targetVelocity, NATURAL_DECEL * SIM_FRAME_LENGTH);
        movement.rotationalVelocity = GameMath.MoveTowards(movement.rotationalVelocity, 0, BASE_ROTATIONAL_ACCEL / 10);

        if (inp.Throttle) {
            targetVelocity.x = Math.cos(movement.rotation);
            targetVelocity.y = Math.sin(movement.rotation);
            // multiply this by max velocity
            targetVelocity.scale3(MAX_SPEED);
            // move current velocity towards that by acceleration value
            movement.velocity = GameMath.VecMoveTowards(movement.velocity, targetVelocity, BOOSTER_ACCEL * SIM_FRAME_LENGTH);
        }

        var rotationInput : Float = 0;
        if (inp.Left) {
            rotationInput = -BASE_ROTATIONAL_ACCEL * SIM_FRAME_LENGTH;
        }

        if (inp.Right) {
            rotationInput = BASE_ROTATIONAL_ACCEL * SIM_FRAME_LENGTH;
        }

        movement.rotationalVelocity += rotationInput;

        movement.rotation += movement.rotationalVelocity * SIM_FRAME_LENGTH;
    }

    public override function Tick() {
        super.EarlyTick();
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
    }
}