class TSS_MapScript_RBLXDTS : TSS_MapScript
{
    const ALLY_SPAWN_DELAY = 15 * TICRATE;
    const CORE_INVULNERABLE_DAMAGE_FACTOR = 0.1;
    const WALL_MOVE_SPEED = 32;
    const WALL_HEIGHT = 92;
    const UPGRADE_MAX_LEVEL_CORE_SELF_REPAIR = 2;
    const UPGRADE_MAX_LEVEL_CORE_SHIELD = 2;
    const UPGRADE_MAX_LEVEL_ALLY_SPAWN = 3;
	const UPGRADE_COST_CORE_SELF_REPAIR = 1;
	const UPGRADE_COST_CORE_SHIELD = 1;
	const UPGRADE_COST_ALLY_SPAWN = 1;
	const POWERUP_COST_OVERGUARD = 5;
	const POWERUP_COST_INVULNERABLE = 5;
	const POWERUP_COST_WALL = 5;
    const POWERUP_DURATION_INVULNERABLE = 15 * TICRATE;
    const POWERUP_DURATION_WALL = 10 * TICRATE;
    const POWERUP_COOLDOWN_OVERGUARD = 120 * TICRATE;
    const POWERUP_COOLDOWN_INVULNERABLE = 180 * TICRATE;
    const POWERUP_COOLDOWN_WALL = 180 * TICRATE;

    private double CoreInitialDamageFactor;
	private map<int, string> AllySpawns;
	private MapIterator<int, string> AllySpawnIterator;
    private array<Actor> TrackedAllies;
	private int CoreSelfRepairLevel;
	private int CoreShieldLevel;
	private int AllySpawnLevel;
    private int AllySpawnTic;
    private int OverguardCooldownTic;
    private int InvulnerableActiveTic;
    private int InvulnerableCooldownTic;
    private array<int> WallActiveTics;
    private array<int> WallCooldownTics;

    override void PostBeginPlay()
    {
        super.PostBeginPlay();

        AllySpawns.Insert(0, "MarineFist,MarinePistol,MarineShotgun");
        AllySpawns.Insert(1, "MarineChainsaw,MarineSSG,MarineChaingun");
        AllySpawns.Insert(2, "MarineBerserk,MarinePlasma,MarineRailgun");
        AllySpawnIterator.Init(AllySpawns);
        AllySpawnTic = ALLY_SPAWN_DELAY - AllySpawnLevel;
        for (int i = 1; i <= 4; i++)
        {
            WallActiveTics.Insert(i, 0);
            WallCooldownTics.Insert(i, 0);
        }

		int mainKillGoal;
        switch (G_SkillPropertyInt(SKILLP_ACSRETURN))
        {
            case SKILL_BABY:
				mainKillGoal = 1;
				D_MakeWaveData(
					1,
					"ZombieMan,ShotgunGuy,DoomImp",
					killGoal: mainKillGoal
				);
                /*D_MakeWaveData(
					2,
					"ZombieMan,ShotgunGuy,DoomImp",
					killGoal: mainKillGoal
				);
                D_MakeWaveData(
					3,
					"ZombieMan,ShotgunGuy,DoomImp",
					killGoal: mainKillGoal
				);
				D_MakeWaveData(
					4,
					"ZombieMan,ShotgunGuy,DoomImp,Demon",
					killGoal: mainKillGoal
				);*/
				D_MakeWaveData(
					1,
					"Demon,Spectre",
                    waveName: "\c[Brick]Demon Rush",
					waveSpawnGroupSizeMin: 1,
					waveSpawnGroupSizeMax: 1,
					waveSpawnIntervalMin: 2 * TICRATE,
					waveSpawnIntervalMax: 2 * TICRATE,
					waveMusic: "D_DOOM",
                    weaponItems: "Chaingun",
                    ammoItems: "ClipBox,ClipBox,ClipBox,ClipBox,ShellBox,ShellBox",
                    powerupItems: "Backpack",
					killGoal: 100
				);
                D_MakeWaveData(
					6,
					"CyberImp,HellKnightF",
					waveMinibosses: "RevenantF=0.25",
					killGoal: mainKillGoal
				);
                D_MakeWaveData(
					7,
					"CyberImp,HellKnightF",
					waveMinibosses: "RevenantF=0.25",
					killGoal: mainKillGoal
				);
                D_MakeWaveData(
					8,
					"CyberImp,HellKnightF,BaronOfHellF",
					waveMinibosses: "RevenantF=0.25",
					killGoal: mainKillGoal
				);
                D_MakeWaveData(
					9,
					"CyberImp,HellKnightF,BaronOfHellF",
					waveMinibosses: "RevenantF=0.25",
					killGoal: mainKillGoal
				);
                D_MakeWaveData(
					10,
					"CyberImp,HellKnightF,BaronOfHellF",
                    finaleEnemies: "[boss]CyberdemonF,[boss]SpiderMastermindF",
                    finaleMusic: "music/20171_newgrounds_showno.mp3",
					killGoal: mainKillGoal
				);
				break;
            case SKILL_EASY:
				mainKillGoal = 30;
				break;
            case SKILL_NORMAL:
				mainKillGoal = 50;
				break;
            case SKILL_HARD:
				mainKillGoal = 50;
                D_MakeWaveData(
					1,
					"ZombieMan,ShotgunGuy,DoomImp",
					killGoal: mainKillGoal
				);
				D_MakeWaveData(
					1,
					"Demon,Spectre",
                    waveName: "\c[Brick]Demon Rush",
					waveSpawnGroupSizeMin: 1,
					waveSpawnGroupSizeMax: 1,
					waveSpawnIntervalMin: 3 * TICRATE,
					waveSpawnIntervalMax: 3 * TICRATE,
					waveMusic: "D_DOOM",
                    weaponItems: "Chaingun", // 200
                    ammoItems: "ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ClipBox,ShellBox,ShellBox,ShellBox,ShellBox,ShellBox,Clip,Clip,Clip,Clip,Clip,Shell,Shell,Shell,Shell,Shell",
                    powerupItems: "Backpack",
					killGoal: 100
				);
				break;
            case SKILL_NIGHTMARE:
				mainKillGoal = 70;
				D_MakeWaveData(
					1,
					"Demon",
					waveMusic: "D_MAP05",
                    finaleEnemies: "[boss]TSS_ZombieBoss1",
                    finaleMusic: "music/show_no_tears.mp3",
					killGoal: 2
				);
				break;
            case SKILL_HELLISH:
				mainKillGoal = 75;
                D_MakeWaveData(
					1,
					"Demon",
					waveMusic: "D_MAP05",
                    finaleEnemies: "[boss]TSS_ZombieBoss2",
                    finaleMusic: "music/show_no_tears_remix.mp3",
					killGoal: 2
				);
				break;
            case SKILL_IMPOSSIBLE:
				mainKillGoal = 100;
                D_MakeWaveData(
					1,
					"Demon",
					waveMusic: "D_MAP05",
                    finaleEnemies: "[boss]TSS_ZombieBoss2",
                    finaleMusic: "music/show_no_tears_remix.mp3",
					killGoal: 2
				);
                break;
        }
    }

    override void Tick()
    {
        TSS_MissionHandler global = TSS_Utils.MissionHandler();

        // This is deferred to Tick() so we can be sure d_Core was set in MissionHandler.
        if (GetAge() == 0 && global.d_Core)
        {
            CoreInitialDamageFactor = global.d_Core.DamageFactor;
        }

        // Handle ally spawning.
        for (int i = 0; i < TrackedAllies.Size(); i++)
        {
            Actor ally = TrackedAllies[i];
            if (!ally || ally.Health <= 0)
            {
                TrackedAllies.Delete(i);
            }
        }

        if ((global.MissionState == MISSION_STATE_DEFENSE_ACTIVE_WAVE || global.MissionState == MISSION_STATE_DEFENSE_INTERMISSION_FINALE || global.MissionState == MISSION_STATE_DEFENSE_ACTIVE_FINALE) && global.d_Core && TrackedAllies.Size() < AllySpawnLevel + 3 && DecrementTic(AllySpawnTic))
        {
            array<string> allySpawns;
            while (AllySpawnIterator.Next())
            {
                if (AllySpawnLevel >= AllySpawnIterator.GetKey())
                {
                    AllySpawnIterator.GetValue().Split(allySpawns, ",", TOK_SKIPEMPTY);
                }
            }
            AllySpawnIterator.ReInit();

            if (allySpawns.Size() > 0)
            {
                Actor ally = Spawn(allySpawns[Random(0, allySpawns.Size() - 1)], global.d_Core.Vec3Offset(FRandom(-192.0, 192.0), FRandom(-192.0, 192.0), 0.0), ALLOW_REPLACE);
                if (ally)
                {
                    ally.bFriendly = true;
                    Spawn('TeleportFog', ally.Pos);
                    TrackedAllies.Push(ally);
                }
            }
            AllySpawnTic = ALLY_SPAWN_DELAY - AllySpawnLevel;
        }

        // Handle powerups.
        DecrementTic(OverguardCooldownTic);
        if (global.d_Core && DecrementTic(InvulnerableActiveTic))
        {
            global.d_Core.DamageFactor = CoreInitialDamageFactor;
        }
        DecrementTic(InvulnerableCooldownTic);
        for (int i = 1; i <= 4; i++)
        {
            if (DecrementTic(WallActiveTics[i]))
            {
                Floor_LowerByValue(i, WALL_MOVE_SPEED, WALL_HEIGHT);
            }
            DecrementTic(WallCooldownTics[i]);
        }
    }

    override void MapEvent(int arg1, int arg2, int arg3)
    {
        TSS_MissionHandler global = TSS_Utils.MissionHandler();
        if (global.d_Core)
        {
            switch (arg1)
            {
				case 10:
                    if (PurchaseUpgrade(CoreSelfRepairLevel, UPGRADE_MAX_LEVEL_CORE_SELF_REPAIR, UPGRADE_COST_CORE_SELF_REPAIR))
                    {
                        switch (CoreSelfRepairLevel)
                        {
                            case 1:
                                --global.d_Core.HealthRegenRate;
                                break;
                            case 2:
                                global.d_Core.HealthRegenDelay *= 0.85;
                                break;
                        }
                    }
					break;
				case 11:
                    if (PurchaseUpgrade(CoreShieldLevel, UPGRADE_MAX_LEVEL_CORE_SELF_REPAIR, UPGRADE_COST_CORE_SELF_REPAIR))
                    {
                        switch (CoreShieldLevel)
                        {
                            case 1:
                                --global.d_Core.ShieldRegenRate;
                                break;
                            case 2:
                                global.d_Core.ShieldRegenDelay *= 0.9;
                                break;
                        }
                    }
					break;
				case 12:
                    if (PurchaseUpgrade(AllySpawnLevel, UPGRADE_MAX_LEVEL_ALLY_SPAWN, UPGRADE_COST_ALLY_SPAWN) && AllySpawnLevel == 1);
                    {
                        AllySpawnTic = Random(1, 35) * TICRATE;
                    }
					break;
                case 0: // Core Powerup "Overguard" activated.
                    if (DisplayPowerupUnavailableMessage(OverguardCooldownTic, false))
                    {
                        return;
                    }

                    global.d_Core.Overguard = global.d_Core.Shield * 2.0;
                    OverguardCooldownTic = POWERUP_COOLDOWN_OVERGUARD;
                    TSS_Utils.DisplayMessage(
                        StringTable.Localize("$TSS_MESSAGE_DEFENSE_POWERUP_USED_OVERGUARD"),
                        id: HUD_ID_TOP_MESSAGE,
                        typeTime: 2,
                        holdTime: 3 * TICRATE,
                        scale: (0.5, 0.5)
                    );
                    break;
                case 1: // Core Powerup "Invulnerability" activated.
                    if (DisplayPowerupUnavailableMessage(InvulnerableActiveTic, true) || DisplayPowerupUnavailableMessage(InvulnerableCooldownTic, false))
                    {
                        return;
                    }

                    if (global.d_Core.DamageFactor > CORE_INVULNERABLE_DAMAGE_FACTOR)
                    {
                        global.d_Core.DamageFactor = CORE_INVULNERABLE_DAMAGE_FACTOR;
                    }
                    InvulnerableActiveTic = POWERUP_DURATION_INVULNERABLE;
                    InvulnerableCooldownTic = POWERUP_COOLDOWN_INVULNERABLE + POWERUP_DURATION_INVULNERABLE;
                    TSS_Utils.DisplayMessage(
                        string.Format(StringTable.Localize("$TSS_MESSAGE_DEFENSE_POWERUP_USED_INVULNERABLE"), POWERUP_DURATION_INVULNERABLE / TICRATE),
                        id: HUD_ID_TOP_MESSAGE,
                        typeTime: 2,
                        holdTime: 3 * TICRATE,
                        scale: (0.5, 0.5)
                    );
                    break;
                case 2: // Protective Barrier raised.
                    if (DisplayPowerupUnavailableMessage(WallActiveTics[arg2], true) || DisplayPowerupUnavailableMessage(WallCooldownTics[arg2], false))
                    {
                        return;
                    }

                    WallActiveTics[arg2] = POWERUP_DURATION_WALL;
                    WallCooldownTics[arg2] = POWERUP_COOLDOWN_WALL + POWERUP_DURATION_WALL;
                    Floor_RaiseByValue(arg2, WALL_MOVE_SPEED, WALL_HEIGHT);
                    TSS_Utils.DisplayMessage(
                        string.Format(StringTable.Localize("$TSS_MESSAGE_DEFENSE_POWERUP_USED_WALL"), POWERUP_DURATION_WALL / TICRATE),
                        id: HUD_ID_TOP_MESSAGE,
                        typeTime: 2,
                        holdTime: 3 * TICRATE,
                        scale: (0.5, 0.5)
                    );
                    break;
            }
        }
    }

    private bool DecrementTic(out int powerupTic)
    {
        if (powerupTic > 0)
        {
            --powerupTic;
            if (powerupTic <= 0)
            {
                return true;
            }
        }
        return false;
    }

	private bool PurchaseUpgrade(out int upgradeVariable, int maxLevel, int cost)
	{
		TSS_MissionHandler global = TSS_Utils.MissionHandler();
		if (upgradeVariable >= maxLevel)
		{
			TSS_Utils.DisplayMessage(
				StringTable.Localize("$TSS_MESSAGE_UPGRADE_MAXED"),
				id: HUD_ID_TOP_MESSAGE,
				typeTime: 2,
				holdTime: 3 * TICRATE,
				scale: (0.5, 0.5)
			);
			return false;
		}
		if (global.d_Kills < cost)
		{
			TSS_Utils.DisplayMessage(
				string.Format(StringTable.Localize("$TSS_MESSAGE_NOT_ENOUGH_CURRENCY"), global.d_Kills, cost),
				id: HUD_ID_TOP_MESSAGE,
				typeTime: 2,
				holdTime: 3 * TICRATE,
				scale: (0.5, 0.5)
			);
			return false;
		}
		global.d_Kills -= cost;
		++upgradeVariable;
        return true;
	}

    private bool DisplayPowerupUnavailableMessage(uint powerupTic, bool isActiveTic)
    {
        if (powerupTic > 0)
        {
            TSS_Utils.DisplayMessage(
                string.Format(StringTable.Localize(!isActiveTic ? "$TSS_MESSAGE_DEFENSE_POWERUP_COOLDOWN" : "$TSS_MESSAGE_DEFENSE_POWERUP_ACTIVE"), powerupTic / TICRATE),
                id: HUD_ID_TOP_MESSAGE,
                typeTime: 2,
                holdTime: 3 * TICRATE,
                scale: (0.5, 0.5)
            );
            return true;
        }
        return false;
    }
}