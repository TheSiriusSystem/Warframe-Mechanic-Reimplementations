class TSS_ZombieBoss2 : ZombieMan
{
    static const class<Actor> RANDOM_ENEMIES[] = {
        'ZombieMan',
        'ShotgunGuy',
        'DoomImp'
    };
    const BOMB_VELOCITY = 20.0;

    int AbilityCooldown;
    int InvulnerableTime;

    default
    {
        +BOSS
        Tag "Zombie Boss II";
        Health 2500;
        Mass 1000;
    }

    override void Tick()
    {
        super.Tick();
        if (bInvulnerable && GetAge() >= InvulnerableTime)
        {
            bInvulnerable = false;
        }
    }

    states
    {
        See:
            POSS AABBCCDD 3
            {
                int skill = G_SkillPropertyInt(SKILLP_ACSRETURN);
                if (GetAge() >= AbilityCooldown && Random(0, 24) == 0)
                {
                    AbilityCooldown = GetAge() + (7 * TICRATE);
                    switch (Random(0, 2))
                    {
                        case 0: // Spawn Enemies+
                            for (int i = 0; i < 10; i++)
                            {
                                class<Actor> enemyType = RANDOM_ENEMIES[Random(0, RANDOM_ENEMIES.Size() - 1)];
                                if (Random(0, 4) == 0)
                                {
                                    enemyType = 'Demon';
                                }
                                Actor enemy = Spawn(enemyType, Pos, ALLOW_REPLACE);
                                if (enemy)
                                {
                                    enemy.Master = self;
                                    enemy.Angle = Angle;
                                }
                            }
                            break;
                        case 1: // Buncha' Bomb Blitz
                            for (int i = 0; i < 30; i++)
                            {
                                A_SpawnItemEx('TSS_ZombieBoss2Bomb', 0.0, 0.0, Height * 0.5, FRandom(-BOMB_VELOCITY, BOMB_VELOCITY), FRandom(-BOMB_VELOCITY, BOMB_VELOCITY), FRandom(0.0, BOMB_VELOCITY), FRandom(-180.0, 180.0), SXF_NOCHECKPOSITION | SXF_SETTARGET);
                            }
                            break;
                        case 2: // Console Abuse
                            switch (Random(0, 2))
                            {
                                case 0:
                                    ThinkerIterator iterator = ThinkerIterator.Create('Actor', STAT_DEFAULT);
                                    Actor anActor;
                                    while (anActor = Actor(iterator.Next()))
                                    {
                                        if (anActor != self && (anActor.Player || (anActor.bIsMonster && anActor.bFriendly)))
                                        {
                                            anActor.DamageMobj(self, self, 75, 'Normal', DMG_THRUSTLESS);
                                        }
                                    }
                                    Console.PrintF("\c[Gold]%s: Doomsphere!", GetTag());
                                    break;
                                case 1:
                                    Health = Min(Health + StartHealth * 0.05, StartHealth);
                                    Console.PrintF("\c[Gold]%s: Soulsphere!", GetTag());
                                    break;
                                case 2:
                                    bInvulnerable = true;
                                    InvulnerableTime = GetAge() + (5 * TICRATE);
                                    Console.PrintF("\c[Gold]%s: Invulnerability!", GetTag());
                                    break;
                            }
                            break;
                    }
                }
                A_Chase("Melee", null);
            }
            loop;
        Melee:
            POSS EE 4 A_Face(Target);
            POSS F 4 A_CustomMeleeAttack(3 * Random(1, 10), "demon/melee", "");
            goto See;
        Missile:
            stop;
        Pain:
            stop;
    }
}

class TSS_ZombieBoss2Bomb : TSS_ZombieBossBomb
{
	default
	{
        TSS_ZombieBossBomb.ExplodeTics 5 * TICRATE;
        Radius 6.0;
        Height 11.0;
        Scale 1.0;
	}

	states
	{
		Death:
            MISL B 8 bright
            {
                bNoGravity = true;
                Vel = (0.0, 0.0, 0.0);
                Scale = (2.0, 2.0);
                A_Explode(48, 256, 0);
                for (int i = 0; i < 6; i++)
                {
                    A_SpawnItemEx('TSS_ZombieBossBomb', 0.0, 0.0, 0.0, 4.0, 0.0, 8.0, 60.0 * i, SXF_NOCHECKPOSITION | SXF_SETTARGET);
                }
            }
            MISL C 6 bright;
            MISL D 4 bright;
            stop;
	}
}