class TSS_Core : TSS_DefenseObject
{
    default
    {
        Tag "Power Generator";
        Health 2500;
        TSS_Actor.Shield 500;
        TSS_Actor.ShieldRegenDelay 5 * TICRATE;
        TSS_Actor.ShieldRegenRate 2;
        TSS_Actor.ShieldRegenAmount 1;
        Radius 25.5;
        Height 118.0;
    }

    override void Tick()
    {
        super.Tick();
        if (!InStateSequence(CurState, ResolveState("Death")) && Health <= StartHealth * 0.25)
        {
            A_StartSound("core/alarm", CHAN_BODY, CHANF_NOSTOP, 1.0, ATTN_NONE);
        }
    }

    private void SpawnDebris()
    {
        Actor debris = Spawn('TSS_Debris', Vec3Offset(0.0, 0.0, 24.0));
        if (debris)
        {
            debris.VelFromAngle(FRandom(0.0, 15.0), FRandom(-180.0, 180.0));
            debris.Vel.Z = FRandom(0.0, 15.0);
        }
    }

    private void HC_SpawnExplosion()
    {
        SpawnExplosion('TSS_SmallExplosion', Radius * 1.25, Height * 0.75);
    }

    states
    {
        Spawn:
            SECR ABCD 4 bright;
            loop;
        Death:
            SECR E 5 bright
            {
                A_NoBlocking();
                SpawnDebris();
                HC_SpawnExplosion();
                A_StopSound(CHAN_BODY);
            }
            SECR FGH 5 bright SpawnDebris();
            SECR I 5 bright
            {
                SpawnDebris();
                HC_SpawnExplosion();
            }
            SECR J 5 SpawnDebris();
            SECR K 5
            {
                SpawnDebris();
                HC_SpawnExplosion();
            }
            SECR L 5 SpawnDebris();
            SECR M 5
            {
                SpawnDebris();
                HC_SpawnExplosion();
            }
            SECR N 5 SpawnDebris();
            SECR O 5
            {
                SpawnDebris();
                HC_SpawnExplosion();
            }
            SECR P -1;
            stop;
    }
}