package jamSim;

class Entity
{
    var _id:Int;
    public function new() {
        _id = -1;
    }

    public function IsValid():Bool {
        return _id > 0;
    }

    public function SetId(id:Int):Bool {
        _id = id;
        return IsValid();
    }

    public function GetId():Int {
        return _id;
    }

    public function GetSystemTags():Array<String> {
        return [];
    }
}