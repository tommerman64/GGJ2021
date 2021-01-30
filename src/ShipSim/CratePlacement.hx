package shipSim;

import h2d.col.Circle;
import jamSim.Entity.EntityId;
import shipSim.physics.PhysData.ColliderData;
import shipSim.GameEntities.SpaceCrate;
import hxd.Rand;
import h2d.col.Point;
import hxd.clipper.Rect;


class CratePlacement
{
    static var _random = Rand.create();

    static function GenerateLinearPlacement(center:Point, end:Point, numberOfCrates:Int): Array<Point> {
        var cratePlacements = new Array<Point>();
        
        if(numberOfCrates % 2 != 0) {
            cratePlacements.push(center);
            numberOfCrates -= 1;
        }

        for(i in 0...(cast numberOfCrates/2)) {
            var dir = end.sub(center);
            dir.scale(i/numberOfCrates/2);
            cratePlacements.push(center.add(dir));
            cratePlacements.push(center.sub(dir));
        }

        return cratePlacements;
    }

    public static function GenerateCratePlacements(center:Point, width:Int, height:Int, numberOfCrates:Int): Array<Point> {
        return GenerateLinearPlacement(center, new Point(center.x + width/2, center.y + height/2), numberOfCrates);
    }
}