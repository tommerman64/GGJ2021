package jamSim;

class SimSystem {
    public function new() {}

    // Quick way to add all relevant entities to the system
    public function Init(entities:Array<Entity>) {}

    // when a new entity is made after Ini 
    public function OnNewEntity(ent:Entity) {}

    // Notify System that entity has been destroyed using Id
    public function OnEntityDestroyed(entityId:Int) {}

    public function EarlyTick() {}

    public function Tick() {}

    public function LateTick() {}

}