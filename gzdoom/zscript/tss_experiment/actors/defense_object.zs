class TSS_DefenseObject : TSS_Actor
{
    private array<Actor> LinkedActors;
    int PatrolPointId;

    default
    {
        +ISMONSTER
        +BOSS
        +FRIENDLY
        +SOLID
        +SHOOTABLE
        +DONTTHRUST
        +NOBLOOD
        +DONTGIB
        TSS_Actor.ExcludeLevelFromTag true;
    }

    override void PostBeginPlay()
    {
        super.PostBeginPlay();
        SpawnLinkedActor('MapMarker');
        Actor patrolPoint = SpawnLinkedActor('PatrolPoint');
        if (patrolPoint)
        {
            PatrolPointId = ACS_NamedExecuteWithResult("GetUniqueThingId");
            patrolPoint.ChangeTid(PatrolPointId);
        }
        TSS_Utils.DefenseObjectTracker().TrackedDefenseObjects.Push(self);
    }

    override int TakeSpecialDamage(Actor inflictor, Actor source, int hitDamage, name hitDamageType)
    {
        if (!TSS_Utils.SkillModifiers().FriendlyFire && (source && TSS_Utils.IsActorFriendly(source) || inflictor && TSS_Utils.IsActorFriendly(inflictor)))
        {
            return 0;
        }
        return super.TakeSpecialDamage(inflictor, source, hitDamage, hitDamageType);
    }

    override void Die(Actor source, Actor inflictor, int hitFlags, name hitDamageType)
    {
        OnDestroy();
        super.Die(source, inflictor, hitFlags, hitDamageType);
    }

    override void OnDestroy()
    {
        foreach (LinkedActor : LinkedActors)
        {
            if (LinkedActor)
            {
                LinkedActor.Destroy();
            }
        }
    }

    override bool CanCollideWith(Actor other, bool passive)
	{
		return !(TSS_Utils.IsActorFriendly(other) || (!TSS_Utils.SkillModifiers().FriendlyFire && other.bMissile && other.Target && TSS_Utils.IsActorFriendly(other.Target)));
	}

    protected void SpawnExplosion(class<TSS_Effect> explosionType, double spawnOffsetXY, double spawnOffsetZ)
    {
        Spawn(explosionType, Vec3Offset(FRandom(-spawnOffsetXY, spawnOffsetXY), FRandom(-spawnOffsetXY, spawnOffsetXY), FRandom(0.0, spawnOffsetZ)));
    }

    private Actor SpawnLinkedActor(class<Actor> actorType)
    {
        Actor anActor = Spawn(actorType, Pos);
        if (anActor)
        {
            LinkedActors.Push(anActor);
        }
        return anActor;
    }
}