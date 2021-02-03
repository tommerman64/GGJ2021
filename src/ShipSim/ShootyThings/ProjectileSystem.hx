package shipSim.shootyThings;

import shipSim.physics.CollisionSystem;
import shipSim.shootyThings.ShootyData.ShootableShip;
import shipSim.shootyThings.ShootyData.ShootableCrate;
import h3d.Vector;
import haxe.Log;
import SimEntityReps.ProjectileEntityRepresentation;
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
    var _projectileRepresentations: Map<EntityId, ProjectileEntityRepresentation>;
    var _spawner:SpawnSystem;
    var _colliderProvider:EntityId->ColliderData;
    var _positionMax:Vector;
    var _pickupSystem:ShipPickupSystem;

    public function new() {
        super();
        _shootables = new Array<Shootable>();
        _activeProjectiles = new Array<ProjectileData>();
        _positionMax = new Vector();
    }

    public function SetProjectileRepresentations(projectiles: Map<EntityId, ProjectileEntityRepresentation>){
        _projectileRepresentations = projectiles;
    }

    public function SetColliderProvider(provider:EntityId->ColliderData){
        _colliderProvider = provider;
    }

    public function SetSpawner(spawner:SpawnSystem){
        _spawner = spawner;
    }

    public function SetPickupSystem(sys:ShipPickupSystem){
        _pickupSystem = sys;
    }

    public function SetPlayfieldSize(x:Float, y:Float) {
        _positionMax.x = x;
        _positionMax.y = y;
    }

    public override function Init(entities:Array<Entity>) {
        _shootables = new Array<Shootable>();
        for(entity in entities){
            OnNewEntity(entity);
        }
    }

    public override function OnNewEntity(entity:Entity){
        if(entity.GetSystemTags().contains("Crate")) {
            var crate = new ShootableCrate(entity.GetId());
            crate.spawnSystem = _spawner;
            crate.sim = _sim;
            var collisionData = _colliderProvider(entity.GetId());
            if(collisionData != null) {
                crate.colliderData = collisionData;
            }
            _shootables.push(crate);
        }
        if(entity.GetSystemTags().contains("Player")) {
            var ship = new ShootableShip(entity.GetId());
            ship.pickupSystem = _pickupSystem;
            _shootables.push(ship);
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

    public override function EarlyTick() {
        for(projectile in _activeProjectiles){
            projectile.position.x += projectile.direction.x * projectile.speed;
            projectile.position.y += projectile.direction.y * projectile.speed;

            if (projectile.position.x < 0 || projectile.position.x > _positionMax.x
                || projectile.position.y < 0 || projectile.position.y > _positionMax.y) {
                _sim.DestroyEntity(projectile.entityId);
            }
        }
    }

    public override function LateTick() {
        for(shootable in _shootables){
            var collisionData = _colliderProvider(shootable.entityId);
            if(collisionData != null) {
                var collider = collisionData.collider;
                for(projectile in _activeProjectiles){
                    if(shootable.entityId != projectile.ownerId){
                        if(collider.contains(projectile.position)){
                            shootable.TakeHit(projectile);
                            _sim.DestroyEntity(projectile.entityId);
                        }
                    }
                }
            }
        }
    }

    public function FireProjectile(projectileData:ProjectileData) {
        var projectile= new Projectile();
        _spawner.SpawnEntity(projectile, projectileData.position.x, projectileData.position.y);
        projectileData.entityId = projectile.GetId();
        _projectileRepresentations[projectile.GetId()].SetProjectileData(projectileData);
        _activeProjectiles.push(projectileData);
    }
}