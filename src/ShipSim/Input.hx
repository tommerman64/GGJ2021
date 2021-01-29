package shipSim;

import jamSim.Entity;
import jamSim.SimSystem;

typedef InputState =
{
    Left:Bool,
    Right:Bool,
    Throttle:Bool,
    Shoot:Bool,
    Jettison:Bool
}


class InputSystem extends jamSim.SimSystem {
    var  _inputStates : Array<InputState>;
    var  _keySets : Array<Array<Int>>;

    public function new() {
        super();
        _inputStates = new Array<InputState>();
    }

    public function MapKeys(keyCodes:Array<Int>)
    {
        if (_keySets == null) {
            _keySets = new Array<Array<Int>>();
        }
        _keySets.push(keyCodes);
    }

    public function GetInputState(playerIndex:Int) : InputState{
        return _inputStates[playerIndex];
    }

    public override function EarlyTick() {
        super.EarlyTick();
        for (i in 0..._keySets.length) {
            _inputStates[i].Left = hxd.Key.isDown(_keySets[i][0]);
            _inputStates[i].Right = hxd.Key.isDown(_keySets[i][1]);
            _inputStates[i].Throttle = hxd.Key.isDown(_keySets[i][2]);
            _inputStates[i].Shoot = hxd.Key.isDown(_keySets[i][3]);
            _inputStates[i].Jettison = hxd.Key.isDown(_keySets[i][4]);
        }
    }

    public override function Init(entities:Array<Entity>) {
        super.Init(entities);

        for(ent in entities) {
            OnNewEntity(ent);
        }
    }

    public override function OnNewEntity(ent:Entity) {
        if (ent.GetSystemTags().contains("Player")) {
            _inputStates.push({
                Left:false,
                Right:false,
                Throttle:false,
                Shoot:false,
                Jettison:false,
            });
        }
    }

    public function GetPlayerCount() {
        return _inputStates.length;
    }
}