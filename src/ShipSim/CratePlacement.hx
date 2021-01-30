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

        for(i in 0...numberOfCrates) {
            var dir = end.sub(center).scale(2);
            dir.scale(i/numberOfCrates);
            cratePlacements.push(end.sub(dir));
        }

        return cratePlacements;
    }

    public static function GenerateCratePlacements(center:Point, width:Int, height:Int, numberOfCrates:Int): Array<Point> {
        var crates = GenerateLinearPlacement(center, new Point(center.x - width/2, center.y - height/2), Std.int(numberOfCrates/2));
        var lineCenter = center.sub(new Point(width*0.2, -height*0.2));
        crates = crates.concat(GenerateLinearPlacement(lineCenter, new Point(lineCenter.x - width/4, lineCenter.y - height/4), Std.int(numberOfCrates/4)));
        var lineCenter = center.sub(new Point(-width*0.2, height*0.2));
        crates = crates.concat(GenerateLinearPlacement(lineCenter, new Point(lineCenter.x - width/4, lineCenter.y - height/4), Std.int(numberOfCrates/4)));
        return crates;
    }
}