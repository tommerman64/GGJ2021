package shipSim.shootyThings;

import shipSim.shootyThings.ShootyData.ProjectileData;
import h2d.col.Point;
import shipSim.physics.PhysData.ColliderData;
import jamSim.Entity;
import shipSim.shootyThings.ShootyData.Shootable;
import shipSim.GameEntities.Projectile;
import jamSim.Entity.EntityId;
import jamSim.SimSystem;

class ProjectileSystem extends SimSystem {
    var _activeProjectiles:Array<ProjectileData>;
    var _shootables:Array<Shootable>;
    var _colliderData:Map<EntityId, ColliderData>;
    var _spawner:SpawnSystem;

    public function new() {
        super();
        _activeProjectiles = new Array<ProjectileData>();
        _shootables = new Array<Shootable>();
    }

    public function SetColliderData(colliderData:Map<EntityId, ColliderData>){
        _colliderData = colliderData;
    }

    public function SetSpawner(spawner:SpawnSystem){
        _spawner = spawner;
    }

    public override function Init(entities:Array<Entity>) {
        _shootables = new Array<Shootable>();
        for(entity in entities){
            OnNewEntity(entity);
        }
    }

    public override function OnNewEntity(entity:Entity){
        if(entity.GetSystemTags().contains("Crate")
        || entity.GetSystemTags().contains("Player")) {
            _shootables.push(new Shootable(entity.GetId()));
        }
    }

    public override function OnEntityDestroyed(entityId:EntityId){
        for(shootable in _shootables.filter(function(e) {return e.entityId == entityId;})) {
            _shootables.remove(shootable);
        }
        for(projectile in _activeProjectiles.filter(function(e) {return e.entityId == entityId;})) {
            _activeProjectiles.remove(projectile);
        }
    }

    public override function LateTick() {
        for(shootable in _shootables){
            if(_colliderData.exists(shootable.entityId)){
                var collider = _colliderData[shootable.entityId].collider;
                for(projectile in _activeProjectiles){
                    if(collider.contains(projectile.position)){
                        shootable.TakeHit(projectile);
                    }
                }
            }
        }
    }

    public function FireProjectile(projectileData:ProjectileData) {
        var projectile= new Projectile();
        _spawner.SpawnEntity(projectile, projectileData.position.x, projectileData.position.y);
        projectileData.entityId = projectile.GetId();
        _activeProjectiles.push(projectileData);
    }
}