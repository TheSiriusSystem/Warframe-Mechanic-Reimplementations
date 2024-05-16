mixin class TSS_ActorMixin
{
    // Args[0]: health_override
    // Args[1]: shield_override
    // Args[2]: armor_override
    // Args[3]: level_override
    // Args[4]: disable_level_scaling
    bool ExcludeLevelFromTag; property ExcludeLevelFromTag: ExcludeLevelFromTag;
    uint8 Level; property Level: Level;
    int Shield; property Shield: Shield;
    double Armor; property Armor: Armor;
    int Overguard; property Overguard: Overguard;
    uint HealthRegenDelay; property HealthRegenDelay: HealthRegenDelay;
    uint HealthRegenRate; property HealthRegenRate: HealthRegenRate;
    uint HealthRegenAmount; property HealthRegenAmount: HealthRegenAmount;
    uint ShieldRegenDelay; property ShieldRegenDelay: ShieldRegenDelay;
    uint ShieldRegenRate; property ShieldRegenRate: ShieldRegenRate;
    uint ShieldRegenAmount; property ShieldRegenAmount: ShieldRegenAmount;

    private int CurrentHealth;
    private int CurrentShield;
    private bool HadShield;
    private bool HadArmor;
    protected uint HealthRegenDelayTic;
    protected uint HealthRegenTic;
    protected uint ShieldRegenDelayTic;
    protected uint ShieldRegenTic;

    override void PostBeginPlay()
    {
        super.PostBeginPlay();
        double healthFactor = 1.0;
        if (!Player)
        {
            healthFactor = !bFriendly ? TSS_Utils.SkillModifiers().EnemyHealthFactor : TSS_Utils.SkillModifiers().AllyHealthFactor;
        }

        if (!ExcludeLevelFromTag)
        {
            SetTag(string.Format(StringTable.Localize("$TSS_TAG_WARFRAME_ACTOR"), GetTag(), Level));
        }
        Level = Max(Level, 1);
        if (Args[3] != 0)
        {
            Level = Args[3];
        }
        StartHealth = Args[0] == 0 ? Default.Health : Args[0];
        if (Args[1] != 0)
        {
            Shield = Args[1];
        }
        Shield *= healthFactor;
        if (Args[2] != 0)
        {
            Armor = Args[2];
        }
        Overguard *= healthFactor;
        if (ShieldRegenAmount <= 0)
        {
            ShieldRegenAmount = Max(Shield * 0.01, 1);
        }

        // https://warframe.fandom.com/wiki/Enemy_Level_Scaling#Scaling_of_Fundamental_Stats
        // https://warframe.fandom.com/wiki/Armor#Damage_Reduction_Formula
        if (Args[4] == 0)
        {
            Shield = ScaleStatInt(Shield, 0.0075, 2.0);
            Armor = ScaleStatDouble(Armor, 0.005, 1.75);
            Overguard = ScaleStatInt(Overguard, 0.0015, 4.0);
        }

        if (Shield > 0)
        {
            GiveInventory('TSS_Shield', Shield);
            CurrentShield = Shield;
            HadShield = true;
        }
        InitializeArmor();
        HealthRegenDelayTic = HealthRegenDelay;
        ShieldRegenDelayTic = ShieldRegenDelay;
    }

    override void Tick()
    {
        super.Tick();

        // EventHandler.WorldThingSpawned() is called after Actor.PostBeginPlay() and
        // before Actor.Tick() so this accounts for any changes in that timeframe.
        if (GetAge() == 0)
        {
            if (Args[4] == 0)
            {
                StartHealth = ScaleStatInt(StartHealth, 0.015, 2.0);
                DamageMultiply = ScaleStatDouble(DamageMultiply, 0.015, 1.55);
            }
            if (HealthRegenAmount <= 0)
            {
                HealthRegenAmount = Max(StartHealth * 0.01, 1);
            }

            Health = StartHealth;
            CurrentHealth = Health;
        }

        // Shield regeneration.
        BasicArmor basicArmor = BasicArmor(FindInventory('BasicArmor'));
        if (basicArmor)
        {
            if (!HadShield)
            {
                if (basicArmor.Amount > 0)
                {
                    HadShield = true;
                }
            } else
            {
                if (basicArmor.Amount < CurrentShield)
                {
                    ResetRegenTics(ShieldRegenDelay, ShieldRegenDelayTic, ShieldRegenTic);
                }
                if (RegenSelf(ShieldRegenDelay, ShieldRegenRate, ShieldRegenDelayTic, ShieldRegenTic))
                {
                    int regenAmount = ShieldRegenAmount;
                    if (basicArmor.Amount + regenAmount > Shield)
                    {
                        regenAmount = Max(Shield - basicArmor.Amount, 0);
                    }
                    GiveInventory('TSS_Shield', regenAmount);
                }
                CurrentShield = basicArmor.Amount;
            }
        }

        // Health regeneration.
        if (Health < CurrentHealth)
        {
            ResetRegenTics(HealthRegenDelay, HealthRegenDelayTic, HealthRegenTic);
            if (basicArmor && HadShield && basicArmor.Amount <= 0)
            {
                ResetRegenTics(ShieldRegenDelay, ShieldRegenDelayTic, ShieldRegenTic);
            }
        }
        if (RegenSelf(HealthRegenDelay, HealthRegenRate, HealthRegenDelayTic, HealthRegenTic))
        {
            Health = Min(Health + HealthRegenAmount, StartHealth);
        }
        CurrentHealth = Health;

        if (!HadArmor)
        {
            InitializeArmor();
        } else
        {
            ScaleDamageFactorWithArmor();
        }
    }

    override int DamageMobj(Actor inflictor, Actor source, int hitDamage, name hitDamageType, int hitFlags, double hitAngle)
    {
        int actualDamage = hitDamage;
        if (source)
        {
            actualDamage *= source.DamageMultiply;
        } else if (inflictor)
        {
            actualDamage *= inflictor.DamageMultiply;
        }
        actualDamage *= DamageFactor;

        if (Overguard > 0)
        {
            Overguard = Max(Overguard - actualDamage, 0);
            return -1;
        }

        if (!(hitFlags & DMG_NO_ARMOR) && GetShield() - actualDamage > 0)
        {
            hitFlags |= DMG_NO_PAIN | DMG_NO_FACTOR;
        }
        return super.DamageMobj(inflictor, source, hitDamage, hitDamageType, hitFlags, hitAngle);
    }

    void RestoreShield()
    {
        if (HadShield)
        {
            BasicArmor basicArmor = BasicArmor(FindInventory('BasicArmor'));
            if (basicArmor)
            {
                GiveInventory('TSS_Shield', Shield - basicArmor.Amount);
            }
        }
    }

    private void InitializeArmor()
    {
        if (Armor > 0.0)
        {
            ScaleDamageFactorWithArmor();
            HadArmor = true;
        }
    }

    private void ResetRegenTics(uint regenDelayProperty, out uint regenDelayTic, out uint regenTic)
    {
        regenDelayTic = regenDelayProperty;
        regenTic = 0;
    }

    private bool RegenSelf(uint regenDelayProperty, uint regenRateProperty, out uint regenDelayTic, out uint regenTic)
    {
        if (!IsFrozen() && !InStateSequence(CurState, ResolveState("Death")) && regenDelayProperty > 0 && regenRateProperty > 0)
        {
            regenDelayTic = Max(regenDelayTic - 1, 0);
            if (regenDelayTic <= 0)
            {
                regenTic = Max(regenTic - 1, 0);
                if (regenTic <= 0)
                {
                    regenTic = regenRateProperty;
                    return true;
                }
            }
        }
        return false;
    }

    private clearScope double ScaleStatDouble(double stat, double t, double s)
    {
        return !Player ? stat * (1.0 + t * (Level - 1) ** s) : stat;
    }

    private clearScope int ScaleStatInt(int stat, double t, double s)
    {
        return !Player ? int(Min(ScaleStatDouble(stat, t, s), int.Max)) : stat;
    }

    private void ScaleDamageFactorWithArmor()
    {
        DamageFactor = 1.0 - (Armor / (Armor + 300.0));
    }

    clearScope int GetShield()
    {
        if (hadShield)
        {
            BasicArmor basicArmor = BasicArmor(FindInventory('BasicArmor'));
            if (basicArmor)
            {
                return basicArmor.Amount;
            }
        }
        return -1;
    }
}