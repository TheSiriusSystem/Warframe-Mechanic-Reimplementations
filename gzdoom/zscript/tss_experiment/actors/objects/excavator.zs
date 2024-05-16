class TSS_Excavator : TSS_DefenseObject
{
    const POWER_CELL_GIVE_AMOUNT = 20;

    uint8 MaxTime;
    uint8 TimePassed;
    uint8 Power;
    private uint8 PowerDrainTic;

    default
    {
        Tag "Excavator";
        TSS_Actor.Level 1;
        Health 1000;
        TSS_Actor.Shield 200;
        TSS_Actor.ShieldRegenDelay 3 * TICRATE;
        TSS_Actor.ShieldRegenRate 1;
        Radius 21.0;
        Height 96.0;
        Scale 3.0;
    }

    override void PostBeginPlay()
    {
        super.PostBeginPlay();
        ShieldRegenAmount = Max(Shield * 0.005, 1);
        switch (G_SkillPropertyInt(SKILLP_ACSRETURN))
        {
            case SKILL_NIGHTMARE:
            case SKILL_HELLISH:
            case SKILL_IMPOSSIBLE:
                MaxTime = 180;
                break;
            default:
                MaxTime = 100;
                break;
        }
        Power = 20;
    }

    override void Tick()
    {
        super.Tick();
        if (!IsFrozen() && !InStateSequence(CurState, ResolveState("Death")))
        {
            if (Power > 0)
            {
                ++PowerDrainTic;
                if (PowerDrainTic >= 1 * TICRATE)
                {
                    ++TimePassed;
                    if (TimePassed >= MaxTime)
                    {
                        OnDone();
                        Destroy();
                        return;
                    }
                    --Power;
                    PowerDrainTic = 0;
                }
            } else if (!InStateSequence(CurState, ResolveState("Spawn.NoPower")))
            {
                SetStateLabel("Spawn.NoPower");
            }
        }
    }

    override bool CanCollideWith(Actor other, bool passive)
	{
        if (other.Player && other.FindInventory('TSS_PowerCell'))
        {
            other.TakeInventory('TSS_PowerCell', 1);
            Power += 20;
            RestoreShield();
            SetState(SpawnState);
            A_StartSound("excavator/getcell", CHAN_ITEM);
            TSS_Utils.DisplayMessage(
                string.Format(StringTable.Localize("$TSS_MESSAGE_EXCAVATOR_POWERED"), POWER_CELL_GIVE_AMOUNT),
                id: HUD_ID_TOP_MESSAGE,
                fontName: 'BigUpper',
                scale: (0.5, 0.5),
                viewer: other.Player
            );
        }
		return super.CanCollideWith(other, passive);
	}

    private void HC_SpawnExplosion()
    {
        SpawnExplosion('TSS_SmallExplosion', Radius, Height * 0.5);
    }

    private void OnDone()
    {
        TSS_MissionHandler global = TSS_Utils.MissionHandler();
        if (global.MissionType == MISSION_TYPE_EXCAVATION)
        {
            uint amount = (double(TimePassed) / MaxTime) * 100.0;
            if (amount >= 100)
            {
                ++global.e_DigsCompleted;
            }
            global.e_CryoticExcavated += amount;
            TSS_Utils.DisplayMessage(
                string.Format(StringTable.Localize("$TSS_MESSAGE_EXCAVATOR_DONE"), amount),
                id: HUD_ID_TOP_MESSAGE,
                fontName: 'BigUpper',
                holdTime: 3 * TICRATE,
                scale: (0.5, 0.5)
            );
        }
    }

    states
    {
        Spawn:
            CRYS A 4 noDelay A_StartSound("excavator/drill", CHAN_BODY, CHANF_LOOP | CHANF_NOSTOP);
            CRYS B 4;
            CRYS CDEF 3;
            loop;
        Spawn.NoPower:
            CRYS A 0 A_StartSound("excavator/drillstop", CHAN_BODY);
            #### # -1;
            stop;
        Death:
            TNT1 A 6
            {
                OnDone();
                SpawnExplosion('TSS_LargeExplosion', 0.0, 0.0);   
            } 
            TNT1 A 9 HC_SpawnExplosion();
            TNT1 A 7 HC_SpawnExplosion();
            TNT1 AAA 3 HC_SpawnExplosion();
            TNT1 A 6;
            TNT1 A 33 HC_SpawnExplosion();
            stop;
    }
}

class TSS_PowerCell : Inventory
{
    default
    {
        +FLOATBOB
        +INVENTORY.INVBAR
        +INVENTORY.HUBPOWER
        +INVENTORY.PERSISTENTPOWER
        Inventory.Icon "I_ECEL";
        Inventory.MaxAmount 1;
    }

    states
    {
        Spawn:
            CELL A -1;
            stop;
    }
}