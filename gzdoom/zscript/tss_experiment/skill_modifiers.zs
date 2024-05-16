class TSS_SkillModifiers : EventHandler
{
    array<double> PlayerDamageFactors;
    array<double> EnemyHealthFactors;
    array<double> EnemyDamageFactors;
    array<double> AllyHealthFactors;

    double PlayerDamageMultiplier;
    double EnemyHealthFactor;
    double EnemyDamageMultiplier;
    double AllyHealthFactor;
    bool FriendlyFire;

    override void WorldLoaded(WorldEvent event)
    {
        switch (G_SkillPropertyInt(SKILLP_ACSRETURN))
        {
            case SKILL_BABY:
                PlayerDamageMultiplier = 0.7;
                EnemyHealthFactor = 0.5;
                EnemyDamageMultiplier = 0.5;
                AllyHealthFactor = 1.2;
                FriendlyFire = false;
                break;
            case SKILL_EASY:
                PlayerDamageMultiplier = 1.0;
                EnemyHealthFactor = 1.0;
                EnemyDamageMultiplier = 0.75;
                AllyHealthFactor = 1.0;
                FriendlyFire = false;
                break;
            case SKILL_NORMAL:
                PlayerDamageMultiplier = 1.3;
                EnemyHealthFactor = 1.5;
                EnemyDamageMultiplier = 1.0;
                AllyHealthFactor = 0.9;
                FriendlyFire = false;
                break;
            case SKILL_HARD:
                PlayerDamageMultiplier = 1.6;
                EnemyHealthFactor = 2.0;
                EnemyDamageMultiplier = 1.5;
                AllyHealthFactor = 0.8;
                FriendlyFire = false;
                break;
            case SKILL_NIGHTMARE:
                PlayerDamageMultiplier = 1.9;
                EnemyHealthFactor = 2.5;
                EnemyDamageMultiplier = 1.75;
                AllyHealthFactor = 0.75;
                FriendlyFire = false;
                break;
            case SKILL_HELLISH:
                PlayerDamageMultiplier = 2.2;
                EnemyHealthFactor = 3.0;
                EnemyDamageMultiplier = 2.0;
                AllyHealthFactor = 0.7;
                FriendlyFire = false;
                break;
            case SKILL_IMPOSSIBLE:
                PlayerDamageMultiplier = 2.8;
                EnemyHealthFactor = 4.0;
                EnemyDamageMultiplier = 2.5;
                AllyHealthFactor = 0.6;
                FriendlyFire = true;
                break;
            default:
                PlayerDamageMultiplier = 1.0;
                EnemyHealthFactor = 1.0;
                EnemyDamageMultiplier = 1.0;
                AllyHealthFactor = 1.0;
                FriendlyFire = false;
                break;
        }
    }

    override void OnRegister()
    {
        PlayerDamageFactors.Push(0.825);        // SKILL_BABY
        PlayerDamageFactors.Push(1.0);          // SKILL_EASY
        PlayerDamageFactors.Push(1.15);         // SKILL_NORMAL
        PlayerDamageFactors.Push(1.3);          // SKILL_HARD
        PlayerDamageFactors.Push(1.45);         // SKILL_NIGHTMARE
        PlayerDamageFactors.Push(1.6);          // SKILL_HELLISH
        PlayerDamageFactors.Push(2.05);         // SKILL_IMPOSSIBLE

        EnemyHealthFactors.Push(0.5);           // SKILL_BABY
        EnemyHealthFactors.Push(1.0);           // SKILL_EASY
        EnemyHealthFactors.Push(1.5);           // SKILL_NORMAL
        EnemyHealthFactors.Push(2.0);           // SKILL_HARD
        EnemyHealthFactors.Push(2.5);           // SKILL_NIGHTMARE
        EnemyHealthFactors.Push(3.0);           // SKILL_HELLISH
        EnemyHealthFactors.Push(4.0);           // SKILL_IMPOSSIBLE

        EnemyDamageFactors.Push(0.5);           // SKILL_BABY
        EnemyDamageFactors.Push(0.75);          // SKILL_EASY
        EnemyDamageFactors.Push(1.0);           // SKILL_NORMAL
        EnemyDamageFactors.Push(1.5);           // SKILL_HARD
        EnemyDamageFactors.Push(1.75);          // SKILL_NIGHTMARE
        EnemyDamageFactors.Push(2.0);           // SKILL_HELLISH
        EnemyDamageFactors.Push(2.5);           // SKILL_IMPOSSIBLE

        AllyHealthFactors.Push(1.2);            // SKILL_BABY
        AllyHealthFactors.Push(1.0);            // SKILL_EASY
        AllyHealthFactors.Push(0.9);            // SKILL_NORMAL
        AllyHealthFactors.Push(0.8);            // SKILL_HARD
        AllyHealthFactors.Push(0.75);           // SKILL_NIGHTMARE
        AllyHealthFactors.Push(0.7);            // SKILL_HELLISH
        AllyHealthFactors.Push(0.6);            // SKILL_IMPOSSIBLE
    }

    override void WorldThingSpawned(WorldEvent event)
    {
        if (event.Thing)
        {
            int skill = G_SkillPropertyInt(SKILLP_ACSRETURN);
            if (event.Thing.Player)
            {
                event.Thing.DamageMultiply *= PlayerDamageMultiplier;
            } else if (event.Thing.bIsMonster)
            {
                if (event.Thing.StartHealth == 0)
                {
                    event.Thing.StartHealth = event.Thing.Default.Health;
                }
                if (!event.Thing.bFriendly)
                {
                    event.Thing.StartHealth *= EnemyHealthFactor;
                    event.Thing.DamageMultiply *= EnemyDamageMultiplier;
                } else
                {
                    event.Thing.StartHealth *= AllyHealthFactor;
                    event.Thing.DamageMultiply *= PlayerDamageMultiplier;
                }
                event.Thing.Health = event.Thing.StartHealth;
            }
        }
    }

    static double, double, double, double, bool CurrentSkillProperties()
    {
        // player_damage_factor, enemy_health_factor, enemy_damage_factor, ally_health_factor, friendly_fire
        switch (G_SkillPropertyInt(SKILLP_ACSRETURN))
        {
            case SKILL_BABY:
                return 0.825, 0.5, 0.5, 1.2, false;
            case SKILL_EASY:
                return 1.0, 1.0, 0.75, 1.0, false;
            case SKILL_NORMAL:
                return 1.15, 1.5, 1.0, 0.9, false;
            case SKILL_HARD:
                return 1.3, 2.0, 1.5, 0.8, false;
            case SKILL_NIGHTMARE:
                return 1.45, 2.5, 1.75, 0.75, false;
            case SKILL_HELLISH:
                return 1.6, 3.0, 2.0, 0.7, false;
            case SKILL_IMPOSSIBLE:
                return 2.05, 4.0, 2.5, 0.6, true;
        }
        return 1.0, 1.0, 1.0, 1.0, false;
    }

    static double DependentHealthFactor(Actor anActor)
    {
        TSS_SkillModifiers self = TSS_Utils.SkillModifiers();
        int skill = G_SkillPropertyInt(SKILLP_ACSRETURN);
        return !anActor.bFriendly ? self.EnemyHealthFactors[skill] : self.AllyHealthFactors[skill];
    }

    static bool IsFriendlyFireAllowed()
    {
        return G_SkillPropertyInt(SKILLP_ACSRETURN) == SKILL_IMPOSSIBLE;
    }
}