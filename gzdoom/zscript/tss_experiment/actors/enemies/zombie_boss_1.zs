class TSS_ZombieBoss1 : ZombieMan
{
    static const class<Actor> RANDOM_ENEMIES[] = {
        'ZombieMan',
        'ShotgunGuy',
        'DoomImp'
    };
    const BOMB_VELOCITY = 20.0;

    int AbilityCooldown;

    default
    {
        +BOSS
        Tag "Zombie Boss I";
        Health 2000;
        Mass 1000;
    }

    states
    {
        See:
            POSS AABBCCDD 3
            {
                int skill = G_SkillPropertyInt(SKILLP_ACSRETURN);
                if (skill >= SKILL_NORMAL && GetAge() >= AbilityCooldown && Random(0, skill < SKILL_HARD ? 99 : 49) == 0)
                {
                    AbilityCooldown = GetAge() + ((skill < SKILL_HARD ? 10 : 7) * TICRATE);
                    switch (Random(0, 2))
                    {
                        case 0: // Spawn Enemies
                            int enemyAmount = G_SkillPropertyInt(SKILLP_ACSRETURN) < SKILL_HARD ? 5 : 10;
                            for (int i = 0; i < enemyAmount; i++)
                            {
                                Actor enemy = Spawn(RANDOM_ENEMIES[Random(0, RANDOM_ENEMIES.Size() - 1)], Pos, ALLOW_REPLACE);
                                if (enemy)
                                {
                                    enemy.Master = self;
                                    enemy.Angle = Angle;
                                }
                            }
                            break;
                        case 1: // Bomb Blitz
                        case 2:
                            int bombAmount = G_SkillPropertyInt(SKILLP_ACSRETURN) < SKILL_HARD ? 10 : 30;
                            for (int i = 0; i < bombAmount; i++)
                            {
                                A_SpawnItemEx('TSS_ZombieBossBomb', 0.0, 0.0, Height * 0.5, FRandom(-BOMB_VELOCITY, BOMB_VELOCITY), FRandom(-BOMB_VELOCITY, BOMB_VELOCITY), FRandom(0.0, BOMB_VELOCITY), FRandom(-180.0, 180.0), SXF_NOCHECKPOSITION | SXF_SETTARGET);
                            }
                            break;
                    }
                }
                A_Chase("Melee", null);
            }
            loop;
        Melee:
            POSS EE 4 A_Face(Target);
            POSS F 4 A_CustomMeleeAttack(2 * Random(1, 10), "demon/melee", "");
            goto See;
        Missile:
            stop;
        Pain:
            stop;
    }
}

class TSS_ZombieBossBomb : Rocket
{
    protected int ExplodeTics; property ExplodeTics: ExplodeTics;

	default
	{
        +FORCERADIUSDMG
		-NOGRAVITY
        +CANBOUNCEWATER
        +BOUNCEONACTORS
        -ROCKETTRAIL
		DamageFunction (0);
        TSS_ZombieBossBomb.ExplodeTics 3 * TICRATE;
		Radius 4.0;
		Height 8.0;
        BounceType "Doom";
        BounceFactor 0.5;
		Speed 15.0;
		Scale 0.667;
		SeeSound "";
	}

    override void Tick()
    {
        super.Tick();

        --ExplodeTics;
        if (ExplodeTics <= 0 && !InStateSequence(CurState, ResolveState("Death")))
        {
            SetStateLabel("Death");
        }
    }

    override int DoSpecialDamage(Actor victim, int hitDamage, name hitDamageType)
    {
        if (Target && victim.Master == Target)
        {
            return 0;
        }
        return super.DoSpecialDamage(victim, hitDamage, hitDamageType);
    }

	states
	{
		Spawn:
			TNT1 A 0 noDelay A_Jump(128, "Spawn2");
			CBLT ABCDE 2 bright;
			goto Spawn + 1;
		Spawn2:
			CBLT CBAED 2 bright;
			loop;
		Death:
            MISL B 8 bright
            {
                double multiplier = G_SkillPropertyInt(SKILLP_ACSRETURN) < SKILL_HARD ? 1.0 : 1.5;
                bNoGravity = true;
                Vel = (0.0, 0.0, 0.0);
                Scale = (1.0, 1.0) * multiplier;
                A_Explode(24, 128 * multiplier, 0);
            }
            MISL C 6 bright;
            MISL D 4 bright;
            stop;
	}
}