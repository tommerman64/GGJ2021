package shipSim;
import h3d.Vector;

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
}