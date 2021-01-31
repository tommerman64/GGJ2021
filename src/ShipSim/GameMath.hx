package shipSim;
import h3d.Vector;

import shipSim.ShipInventory;
import shipSim.physics.PhysData;

class GameMath
{

    public static function Sign(f:Float):Float {
        if (f > 0) {
            return 1;
        }
        if (f < 0) {
            return -1;
        }
        return 0;
    }
    public static function VecMoveTowards(start:Vector, target:Vector, delta:Float)
    {
        var speedDiff : Vector = target.sub(start);
        var changeThisTick : Vector = speedDiff.getNormalized();
        changeThisTick.scale3(delta);

        // check length, might just return target
        if (changeThisTick.lengthSq() > speedDiff.lengthSq())
        {
            return target;
        }

        return start.add(changeThisTick);
    }

    public static function MoveTowards(start:Float, target:Float, delta:Float) : Float {
        var diff = target - start;
        if (Math.abs(diff) < Math.abs(delta)) {
            return target;
        }

        return start + delta * Sign(diff);
    }

    public static function GetSlotAbsolutePosition(shipPosition: Vector, slotData:ShipWeaponSlot, mov:ShipMovement) : Vector{
        var relativePos = slotData.relativePosition;
        GameMath.RotateInPlace(relativePos, mov.rotation);
        GameMath.AddInPlace(relativePos, shipPosition);

        return relativePos;
    }

    public static function RotateInPlace(v1:Vector, rot:Float) {
        var x = hxd.Math.cos(rot) * v1.x - Math.sin(rot) * v1.y;
        var y = hxd.Math.sin(rot) * v1.x + Math.cos(rot) * v1.y;
    }

    public static function AddInPlace(v1:Vector, v2:Vector) {
        v1.x += v2.x;
        v1.y += v2.y;
        v1.z += v2.z;
    }
}