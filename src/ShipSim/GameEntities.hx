package shipSim;

import jamSim.Entity;

class PlayerShipEntity extends Entity
{
    public override function GetSystemTags():Array<String> {
        return ["Player"];
    }
}

class SpaceCrate extends Entity
{
    public override function GetSystemTags():Array<String> {
        return ["Crate"];
    }
}

class Pickup extends Entity
{
    public override function GetSystemTags():Array<String> {
        return ["Pickup"];
    }
}

class Projectile extends Entity
{
    public override function GetSystemTags():Array<String> {
        return ["Projectile"];
    }
}