package jamSim;

import haxe.iterators.StringIterator;

class Sim {
    var _nextAvailableId:Int;

    // array of all entities in the sim, kept in order of ID
    var _entities:Array<Entity>;

    // array of all systems, manually manage the order if necessary
    var _systems:Array<SimSystem>;

    var _inputs:Array<String>;

    public function new() {
        _nextAvailableId = 1;
        _entities = new Array<Entity>();
        _systems = new Array<SimSystem>();
        _inputs = new Array<String>();
    }

    // Entities
    public function AddEntity(ent:Entity) : Bool {
        if (!ent.SetId(_nextAvailableId)) {
            return false;
        }
        _nextAvailableId++;
        _entities.push(ent);
        for (sys in _systems) {
            sys.OnNewEntity(ent);
        }
        return true;
    }

    public function GetEntities() : Array<Entity> {
        return _entities;
    }

    // Systems
    public function AddSystem(sys:SimSystem) {
        _systems.push(sys);
        sys.Init(_entities);
    }

    public function AddSystemAt(sys:SimSystem, index:Int) {
        _systems.insert(index, sys);
        sys.Init(_entities);
    }

    public function GetSystemIndex(sys:SimSystem) : Int {
        return _systems.indexOf(sys);
    }

    public function Tick() : Void {
        // Run systems
        for (sys in _systems) {
            sys.EarlyTick();
        }

        for (sys in _systems) {
            sys.Tick();
        }

        for (sys in _systems) {
            sys.LateTick();
        }
    }
}