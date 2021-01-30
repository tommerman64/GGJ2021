import haxe.Log;
import h2d.Anim;
import h2d.Tile;
import haxe.Resource;
import h3d.mat.Texture;

class ResourceLoading {
    public static function LoadAnim(tex:Texture, jsonResource:hxd.res.Resource) : Anim {

        var frames = new Array<Tile>();
        var jsonString = jsonResource.entry.getText();
        jsonString = jsonString.substr(1);
        var jsonData = haxe.Json.parse(jsonString);
        var frameCount : Int = jsonData.meta.FrameCount;

        var currentFrame = 0;
        while (currentFrame < frameCount) {
            var spriteData = jsonData.ATLAS.SPRITES[currentFrame].SPRITE;
            var t = h2d.Tile.fromTexture(tex);
            t.setPosition(spriteData.x, spriteData.y);
            t.setSize(spriteData.w, spriteData.h);
            t.dx = -t.width/2;
            t.dy = -t.height/2;
            frames.push(t);
            currentFrame++;
        }

        return new Anim(frames);
    }
}