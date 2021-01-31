import h2d.Anim;
import h2d.Tile;
import h3d.mat.Texture;

class ResourceLoading {
    public static function LoadAnimFromTexAtlas(tex:Texture, jsonResource:hxd.res.Resource) : Anim {

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

    public static function LoadAnimFromSpriteSheet(tex:Texture, jsonResource:hxd.res.Resource) : Anim {
        return new Anim(LoadTilesFromSpriteSheet(tex, jsonResource));
    }

    public static function LoadTilesFromSpriteSheet(tex:Texture, jsonResource:hxd.res.Resource) : Array<Tile> {
        var frames = new Array<Tile>();
        var jsonString = jsonResource.entry.getText();
        jsonString = jsonString.substr(1);
        var jsonData = haxe.Json.parse(jsonString);
        var frameCount : Int = jsonData.meta.FrameCount;

        var currentFrame = 0;
        while (currentFrame < frameCount) {
            var frameData = jsonData.frames[currentFrame].frame;
            var t = h2d.Tile.fromTexture(tex);
            t.setPosition(frameData.x, frameData.y);
            t.setSize(frameData.w, frameData.h);
            t.dx = -t.width/2;
            t.dy = -t.height/2;
            frames.push(t);
            currentFrame++;
        }

        return frames;
    }
}