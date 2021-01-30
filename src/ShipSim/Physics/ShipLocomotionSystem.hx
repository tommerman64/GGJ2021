package shipSim.physics;

import h3d.Vector;
import shipSim.Input.InputState;
import shipSim.Input.InputSystem;
import shipSim.physics.PhysData;
import shipSim.physics.MovementSystem;
import jamSim.Entity;

class ShipLocomotionSystem extends MovementSystem {

    // MOVEMENT CONSTS
    static var BASE_ROTATIONAL_ACCEL = 20 * Math.PI;
    static var MAX_SPEED = 120;
    static var BOOSTER_ACCEL = 45;
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
        var targetVelocity = movement.GetForward();
        movement.velocity = GameMath.VecMoveTowards(movement.velocity, targetVelocity, NATURAL_DECEL * MovementSystem.SIM_FRAME_LENGTH);
        movement.rotationalVelocity = GameMath.MoveTowards(movement.rotationalVelocity, 0, BASE_ROTATIONAL_ACCEL / 10);

        if (inp.Throttle) {
            targetVelocity.scale3(MAX_SPEED);
            // move current velocity towards that by acceleration value
            movement.velocity = GameMath.VecMoveTowards(movement.velocity, targetVelocity, BOOSTER_ACCEL * MovementSystem.SIM_FRAME_LENGTH);
        }

        movement.boosting = inp.Throttle;

        var rotationInput : Float = 0;
        if (inp.Left) {
            rotationInput -= BASE_ROTATIONAL_ACCEL * MovementSystem.SIM_FRAME_LENGTH;
        }

        if (inp.Right) {
            rotationInput += BASE_ROTATIONAL_ACCEL * MovementSystem.SIM_FRAME_LENGTH;
        }

        movement.rotationalVelocity += rotationInput;

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
    }
}