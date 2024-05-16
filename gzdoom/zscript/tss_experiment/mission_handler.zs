class TSS_MissionHandler : EventHandler
{
#region Main Variables
    const BOSS_HINT = "[boss]";
    const LABEL_COUNT_FORMAT = "\c[Ice]%i";
    const LABEL_START_X = -40.0;
    const LABEL_START_Y = 25.0;
    const LABEL_ALIGNMENT = TSS_HudMessage.ALIGN_LEFT;

    uint8 MissionType;
    uint8 MissionState;
    private int GeneralTic;
#endregion

#region Defense Variables
    const D_THING_ID_CORE = 1;
    const D_THING_ID_HEALTH_SPOT = 2;
    const D_THING_ID_WEAPON_SPOT = 4;
    const D_THING_ID_AMMO_SPOT = 5;
    const D_THING_ID_POWERUP_SPOT = 3;
    const D_THING_ID_WAVE_ENEMY_SPOT = 6;
    const D_THING_ID_FINALE_ENEMY_SPOT = 7;
    const D_WALL_MOVE_SPEED = 32;
    const D_WALL_HEIGHT = 92;
    const D_WAVE_DELAY = 11 * TICRATE;
    const D_WAVE_ANNOUNCE_TIME = 5 * TICRATE;
    static const string D_RANDOM_WAVE_MUSIC[] = {
        "defense_wave/danger.mus",
        "defense_wave/intro.mus",
        "defense_wave/march.mus",
        "defense_wave/slide.mus"
    };
    const D_FINALE_DELAY = 5 * TICRATE;
    static const string D_RANDOM_FINALE_MUSIC[] = {
        "defense_boss/action.mus",
        "defense_boss/fight.mus",
        "defense_boss/industry.mus",
        "defense_boss/tribal.mus"
    };
    const D_POWERUP_DURATION_INVULNERABLE = 10 * TICRATE;
    const D_POWERUP_DURATION_WALL = 10 * TICRATE;
    const D_POWERUP_COOLDOWN_OVERGUARD = 120 * TICRATE;
    const D_POWERUP_COOLDOWN_INVULNERABLE = 180 * TICRATE;
    const D_POWERUP_COOLDOWN_WALL = 180 * TICRATE;

    TSS_Core d_Core;
    private array<Actor> d_FinaleEnemies;
    int d_Kills;
    private int d_KillGoalProgress;
    private uint d_Wave;
    private int d_KillGoal;
    map<uint, string> d_WaveData;
    string d_WaveName;
    array<string> d_WaveEnemySpawns;
    array<string> d_WaveMinibossSpawns;
    int d_WaveSpawnGroupSizeMin;
    int d_WaveSpawnGroupSizeMax;
    int d_WaveSpawnIntervalMin;
    int d_WaveSpawnIntervalMax;
    array<string> d_FinaleEnemySpawns;
    string d_FinaleMusic;
    private array<MapSpot> d_WaveEnemySpots;
    private array<MapSpot> d_FinaleEnemySpots;
#endregion

#region Excavation Variables
    const E_THING_ID_DIG_SPOT = 1;
    const E_THING_ID_ENEMY_SPOT = 2;
    const E_POWER_CELL_CARRIER_TAG = "Power Cell Carrier";

    uint e_DigsCompleted;
    uint e_CryoticExcavated;
    array<string> e_RandomEnemies;
    private array<MapSpot> e_DigSpots;
    private array<MapSpot> e_EnemySpots;
    private uint16 e_NextDigTic;
#endregion

#region Main Functions
    // TODO: Make the mission loop more pleasant to read.
    override void WorldTick()
    {
        switch (MissionType)
        {
            case MISSION_TYPE_DEFENSE:
                uint maxWaves = d_WaveData.CountUsed();
                uint nextWave = d_Wave + 1;

                if (MissionState != MISSION_STATE_DEFENSE_COMPLETE && MissionState != MISSION_STATE_DEFENSE_FAIL && (!d_Core || d_Core.Health <= 0))
                {
                    MissionState = MISSION_STATE_DEFENSE_FAIL;
                    GeneralTic = 0;
                    d_Core = null;
                }

                TSS_Utils.DisplayLabel(
                    string.Format(StringTable.Localize("$TSS_LABEL_DEFENSE_WAVE_COUNT"), d_Wave, d_WaveData.CountUsed(), d_WaveName),
                    id: HUD_ID_MISSION_MESSAGE_1,
                    position: (LABEL_START_X, LABEL_START_Y),
                    alignment: LABEL_ALIGNMENT
                );
                TSS_Utils.DisplayLabel(
                    string.Format(StringTable.Localize("$TSS_LABEL_DEFENSE_KILL_GOAL_COUNT"), d_KillGoalProgress, d_KillGoal),
                    id: HUD_ID_MISSION_MESSAGE_2,
                    position: (LABEL_START_X, LABEL_START_Y + 5.0),
                    alignment: LABEL_ALIGNMENT
                );
                if (MissionState == MISSION_STATE_DEFENSE_INTERMISSION_WAVE && GeneralTic % TICRATE == 0)
                {
                    TSS_Utils.DisplayLabel(
                        string.Format(StringTable.Localize("$TSS_LABEL_DEFENSE_WAVE_COUNTDOWN"), GeneralTic / TICRATE),
                        id: 55,
                        position: (LABEL_START_X, LABEL_START_Y + 30.0),
                        alignment: LABEL_ALIGNMENT,
                        holdTime: 1 * TICRATE,
                        fadeOutTime: uint(0.5 * TICRATE)
                    );
                }

                switch (MissionState)
                {
                    case MISSION_STATE_DEFENSE_INTERMISSION_WAVE:
                        --GeneralTic;
                        if (GeneralTic == 10 * TICRATE && d_Wave == 0)
                        {
                            PlayAnnouncement("firstwave");
                            TSS_Utils.DisplayMessage(
                                StringTable.Localize("$TSS_MESSAGE_DEFENSE_FIRST_WAVE"),
                                id: HUD_ID_TOP_MESSAGE,
                                typeTime: 1,
                                holdTime: 3 * TICRATE,
                                fadeOutTime: 1 * TICRATE
                            );
                        } else if (GeneralTic == 5 * TICRATE && d_Wave > 0)
                        {
                            PlayAnnouncement(nextWave < maxWaves ? string.Format("wave%i", nextWave) : "lastwave");
                            TSS_Utils.DisplayMessage(
                                nextWave < maxWaves ? string.Format(StringTable.Localize("$TSS_MESSAGE_DEFENSE_NEW_WAVE"), nextWave) : StringTable.Localize("$TSS_MESSAGE_DEFENSE_LAST_WAVE"),
                                id: HUD_ID_TOP_MESSAGE,
                                typeTime: 1,
                                holdTime: 3 * TICRATE,
                                fadeOutTime: 1 * TICRATE
                            );
                        } else if (GeneralTic == 0)
                        {
                            MissionState = MISSION_STATE_DEFENSE_ACTIVE_WAVE;
                            GeneralTic = 1;
                            d_KillGoalProgress = 0;
                            ++d_Wave;
                            d_WaveEnemySpawns.Clear();
                            d_WaveMinibossSpawns.Clear();
                            d_FinaleEnemySpawns.Clear();
                            dictionary waveDictionary = dictionary.FromString(d_WaveData.GetIfExists(d_Wave));

                            dictionary waveInfo = dictionary.FromString(waveDictionary.At("wave")); // dictionary<enemies: array<string>, minibosses: dictionary<string, double>, music: string>
                            d_WaveName = waveInfo.At("name");
                            waveInfo.At("enemies").Split(d_WaveEnemySpawns, ",", TOK_SKIPEMPTY);
                            waveInfo.At("minibosses").Split(d_WaveMinibossSpawns, ",", TOK_SKIPEMPTY);
                            array<string> rangeArray;
                            waveInfo.At("spawn_group_size").Split(rangeArray, ":", TOK_SKIPEMPTY);
                            d_WaveSpawnGroupSizeMin = rangeArray[0].ToInt();
                            d_WaveSpawnGroupSizeMax = rangeArray[1].ToInt();
                            rangeArray.Clear();
                            waveInfo.At("spawn_interval").Split(rangeArray, ":", TOK_SKIPEMPTY);
                            d_WaveSpawnIntervalMin = rangeArray[0].ToInt();
                            d_WaveSpawnIntervalMax = rangeArray[1].ToInt();
                            if (waveInfo.At("music") != "keep")
                            {
                                S_ChangeMusic(waveInfo.At("music") != "random" ? waveInfo.At("music") : D_RANDOM_WAVE_MUSIC[Random(0, D_RANDOM_WAVE_MUSIC.Size() - 1)]);
                            }

                            dictionary finaleInfo = dictionary.FromString(waveDictionary.At("finale")); // dictionary<enemies: array<string>, music: string>
                            finaleInfo.At("enemies").Split(d_FinaleEnemySpawns, ",", TOK_SKIPEMPTY);
                            d_FinaleMusic = finaleInfo.At("music");

                            dictionary itemInfo = dictionary.FromString(waveDictionary.At("items")); // dictionary<health: array<string>, weapons: array<string>, ammo: array<string>, powerups: array<string>>
                            map<uint, string> itemSpawns;
                            itemSpawns.Insert(D_THING_ID_HEALTH_SPOT, itemInfo.At("health"));
                            itemSpawns.Insert(D_THING_ID_WEAPON_SPOT, itemInfo.At("weapons"));
                            itemSpawns.Insert(D_THING_ID_AMMO_SPOT, itemInfo.At("ammo"));
                            itemSpawns.Insert(D_THING_ID_POWERUP_SPOT, itemInfo.At("powerups"));
                            MapIterator<uint, string> itemIterator;
                            itemIterator.Init(itemSpawns);
                            while (itemIterator.Next())
                            {
                                array<MapSpot> spots;
                                ActorIterator spotIterator = Level.CreateActorIterator(itemIterator.GetKey(), 'MapSpot');
                                MapSpot spot;
                                while (spot = MapSpot(spotIterator.Next()))
                                {
                                    spots.Push(spot);
                                }

                                if (spots.Size() > 0)
                                {
                                    array<string> items;
                                    itemIterator.GetValue().Split(items, ",", TOK_SKIPEMPTY);
                                    foreach (item : items)
                                    {
                                        SpawnThing(item, spots[Random(0, spots.Size() - 1)], 'TeleportFog', 16.0);
                                    }
                                } else
                                {
                                    Console.PrintF("ItemGroup %s could not spawn because no MapSpot with tag %i exists.", itemIterator.GetValue(), itemIterator.GetKey());
                                }
                            }

                            d_KillGoal = waveDictionary.At("kill_goal").ToInt();
                        }
                        break;
                    case MISSION_STATE_DEFENSE_ACTIVE_WAVE:
                        if (d_KillGoalProgress < d_KillGoal)
                        {
                            --GeneralTic;
                            if (GeneralTic == 0)
                            {
                                for (int i = 0; i < Random(d_WaveSpawnGroupSizeMin, d_WaveSpawnGroupSizeMax); i++)
                                {
                                    string enemyType = d_WaveEnemySpawns[Random(0, d_WaveEnemySpawns.Size() - 1)];
                                    if (d_WaveMinibossSpawns.Size() > 0)
                                    {
                                        array<string> minibossTypeInfo;
                                        foreach (minibossType : d_WaveMinibossSpawns)
                                        {
                                            minibossType.Split(minibossTypeInfo, "=", TOK_SKIPEMPTY);
                                        }
                                        for (int i = 0; i < minibossTypeInfo.Size(); i += 2)
                                        {
                                            string minibossType = minibossTypeInfo[i];
                                            double minibossChance = minibossTypeInfo[i + 1].ToDouble();
                                            if (FRandom(0.0, 1.0) <= minibossChance)
                                            {
                                                enemyType = minibossType;
                                                break;
                                            }
                                        }
                                    }

                                    let [enemy, _, enemyId] = SpawnThing(enemyType, d_WaveEnemySpots[Random(0, d_WaveEnemySpots.Size() - 1)], 'SpawnFire');
                                    if (enemy)
                                    {
                                        if (d_Core)
                                        {
                                            Thing_SetGoal(enemyId, d_Core.PatrolPointId, 0, true);
                                        }
                                        Thing_Hate(enemyId, D_THING_ID_CORE, 2);
                                    }
                                    GeneralTic = Random(d_WaveSpawnIntervalMin, d_WaveSpawnIntervalMax);
                                }
                            }
                        } else
                        {
                            if (d_FinaleEnemySpawns.Size() == 0)
                            {
                                D_EndWave();
                            } else
                            {
                                MissionState = MISSION_STATE_DEFENSE_INTERMISSION_FINALE;
                                GeneralTic = D_FINALE_DELAY;
                            }
                        }
                        break;
                    case MISSION_STATE_DEFENSE_INTERMISSION_FINALE:
                        if (GeneralTic % TICRATE == 0)
                        {
                            // If this state just started, attempt a music change.
                            if (GeneralTic == D_FINALE_DELAY && d_FinaleMusic != "none")
                            {
                                S_ChangeMusic("");
                            }

                            // Update the finale countdown message every 35 tics.
                            TSS_Utils.DisplayMessage(
                                string.Format(StringTable.Localize("$TSS_MESSAGE_DEFENSE_FINALE_COUNTDOWN"), GeneralTic / TICRATE),
                                id: HUD_ID_TOP_MESSAGE,
                                holdTime: 1 * TICRATE,
                                fadeOutTime: uint(0.5 * TICRATE)
                                //scale: (TOP_MESSAGE_SCALE_X, TOP_MESSAGE_SCALE_Y)
                            );
                        }

                        --GeneralTic;

                        // If the finale countdown has been exhausted, begin the finale.
                        if (GeneralTic == 0)
                        {
                            MissionState = MISSION_STATE_DEFENSE_ACTIVE_FINALE;
                            foreach (enemyType : d_FinaleEnemySpawns)
                            {
                                let [enemy, isBoss, enemyId] = SpawnThing(enemyType, d_FinaleEnemySpots[Random(0, d_FinaleEnemySpots.Size() - 1)], 'SpawnFire');
                                if (enemy)
                                {
                                    d_FinaleEnemies.Push(enemy);
                                    if (isBoss)
                                    {
                                        TSS_Utils.BossTracker().TrackedBosses.Push(enemy);
                                    }
                                }
                            }
                            if (d_FinaleMusic != "none")
                            {
                                S_ChangeMusic(d_FinaleMusic != "random" ? d_FinaleMusic : D_RANDOM_FINALE_MUSIC[Random(0, D_RANDOM_FINALE_MUSIC.Size() - 1)]);
                            }
                        }
                        break;
                    case MISSION_STATE_DEFENSE_ACTIVE_FINALE:
                        for (int i = 0; i < d_FinaleEnemies.Size(); i++)
                        {
                            Actor enemy = d_FinaleEnemies[i];
                            if (!enemy || enemy.Health <= 0)
                            {
                                d_FinaleEnemies.Delete(i);
                            }
                        }
                        if (d_FinaleEnemies.Size() == 0)
                        {
                            D_EndWave();
                            if (d_FinaleMusic != "none")
                            {
                                S_ChangeMusic("");
                            }
                        }
                        break;
                    case MISSION_STATE_DEFENSE_COMPLETE:
                        break;
                    case MISSION_STATE_DEFENSE_FAIL:
                        if (GeneralTic < 10 * TICRATE)
                        {
                            if (GeneralTic == 0)
                            {
                                for (int i = 0; i < d_FinaleEnemies.Size(); i++)
                                {
                                    Actor enemy = d_FinaleEnemies[i];
                                    enemy.Destroy();
                                    d_FinaleEnemies.Delete(i);
                                }
                                S_ChangeMusic("D_READ_M");
                                TSS_Utils.DisplayMessage(
                                    StringTable.Localize("$TSS_MESSAGE_DEFENSE_LOSS"),
                                    id: HUD_ID_TOP_MESSAGE,
                                    typeTime: 1,
                                    holdTime: 3 * TICRATE,
                                    fadeOutTime: 1 * TICRATE
                                );
                            }
                            ++GeneralTic;
                        } else
                        {
                            TSS_Utils.DisplayLabel(
                                string.Format(StringTable.Localize("$TSS_MESSAGE_DEFENSE_LOSS_ENDOOM"), d_Wave, d_WaveData.CountUsed(), d_Kills),
                                id: HUD_ID_TOP_MESSAGE
                            );
                        }
                        break;
                }
                break;
            case MISSION_TYPE_EXCAVATION:
                TSS_Utils.DisplayLabel(
                    string.Format(StringTable.Localize("$TSS_LABEL_EXCAVATION_DIG_COUNT"), e_DigsCompleted),
                    id: HUD_ID_MISSION_MESSAGE_1,
                    position: (LABEL_START_X, LABEL_START_Y),
                    alignment: LABEL_ALIGNMENT
                );
                TSS_Utils.DisplayLabel(
                    string.Format(StringTable.Localize("$TSS_LABEL_EXCAVATION_RESOURCE_COUNT"), e_CryoticExcavated),
                    id: HUD_ID_MISSION_MESSAGE_2,
                    position: (LABEL_START_X, LABEL_START_Y + 5.0),
                    alignment: LABEL_ALIGNMENT
                );
                break;
        }
    }

    override void WorldThingSpawned(WorldEvent event)
    {
        if (event.Thing && !TSS_Utils.IsActorFriendly(event.Thing))
        {
            event.Thing.bSeeFriendlyMonsters = true;
            event.Thing.FriendlySeeBlocks = 16; // 2048 map units
            switch (MissionType)
            {
                case MISSION_TYPE_EXCAVATION:
                    if (Random(0, 9) == 0)
                    {
                        TSS_Actor customActor = TSS_Actor(event.Thing);
                        if (customActor && !customActor.ExcludeLevelFromTag)
                        {
                            customActor.SetTag(string.Format(StringTable.Localize("$TSS_TAG_WARFRAME_ACTOR"), E_POWER_CELL_CARRIER_TAG, customActor.Level));
                        } else
                        {
                            event.Thing.SetTag(E_POWER_CELL_CARRIER_TAG);
                        }
                    }
                    break;
            }
        }
        if (MissionType != MISSION_TYPE_NONE)
        {
            event.Thing.bSeeFriendlyMonsters = true;
        }
    }

    override void WorldThingDied(WorldEvent event)
    {
        if (event.Thing && !TSS_Utils.IsActorFriendly(event.Thing))
        {
            switch (MissionType)
            {
                case MISSION_TYPE_DEFENSE:
                    if (event.Thing.Target && TSS_Utils.IsActorFriendly(event.Thing.Target))
                    {
                        if (MissionState != MISSION_STATE_DEFENSE_FAIL)
                        {
                            ++d_Kills;
                        }
                        if (MissionState == MISSION_STATE_DEFENSE_ACTIVE_WAVE && d_KillGoalProgress < d_KillGoal)
                        {
                            ++d_KillGoalProgress;
                        }
                    }
                    break;
                case MISSION_TYPE_EXCAVATION:
                    if (event.Thing.GetTag().Left(E_POWER_CELL_CARRIER_TAG.Length()) == E_POWER_CELL_CARRIER_TAG)
                    {
                        Actor.Spawn('TSS_PowerCell', event.Thing.Pos);
                    }
                    break;
            }
        }
    }

    private Actor, bool, int SpawnThing(string thingType, MapSpot spawnSpot, class<Actor> spawnEffect = null, double xyOffsetRange = 0.0)
    {
        bool isBoss = (thingType.Left(BOSS_HINT.Length()) == BOSS_HINT);
        thingType = !isBoss ? thingType : thingType.Mid(BOSS_HINT.Length());
        Actor thing = Actor.Spawn(thingType, spawnSpot.Vec3Offset(FRandom(-spawnSpot.Args[0], spawnSpot.Args[0]), FRandom(-spawnSpot.Args[1], spawnSpot.Args[1]), 0.0), ALLOW_REPLACE);
        int thingId;
        if (thing)
        {
            thingId = ACS_NamedExecuteWithResult("GetUniqueThingId");
            thing.ChangeTid(thingId);
            thing.Angle = spawnSpot.Angle;
            if (spawnEffect)
            {
                Actor.Spawn(spawnEffect, spawnSpot.Pos);
            }
        } else
        {
            isBoss = false;
        }
        return thing, isBoss, thingId;
    }

    private void PushMapSpotsToArray(array<MapSpot> spotArray, int thingId)
    {
        ActorIterator iterator = Level.CreateActorIterator(thingId, 'MapSpot');
        MapSpot spot;
        while (spot = MapSpot(iterator.Next()))
        {
            spotArray.Push(spot);
        }
    }

    private void MissionTypeError(string text)
    {
        MissionType = MISSION_TYPE_NONE;
        Console.PrintF("\c[Red]"..text);
    }

    static void StartMission(int newMissionType)
    {
        TSS_MissionHandler self = TSS_Utils.MissionHandler();
        if (self.MissionType == MISSION_TYPE_NONE)
        {
            self.MissionType = newMissionType;
            switch (newMissionType)
            {
                case MISSION_TYPE_DEFENSE:
                    ActorIterator coreIterator = Level.CreateActorIterator(D_THING_ID_CORE, 'TSS_Core');
                    while (self.d_Core = TSS_Core(coreIterator.Next()))
                    {
                        self.MissionState = MISSION_STATE_DEFENSE_INTERMISSION_WAVE;
                        self.GeneralTic = D_WAVE_DELAY;
                        self.PushMapSpotsToArray(self.d_WaveEnemySpots, D_THING_ID_WAVE_ENEMY_SPOT);
                        self.PushMapSpotsToArray(self.d_FinaleEnemySpots, D_THING_ID_FINALE_ENEMY_SPOT);
                        break;
                    }
                    if (!self.d_Core)
                    {
                        self.MissionTypeError("No TSS_Core things with tag 1 found.");
                    }
                    break;
                case MISSION_TYPE_EXCAVATION:
                    self.PushMapSpotsToArray(self.e_DigSpots, E_THING_ID_DIG_SPOT);
                    self.PushMapSpotsToArray(self.e_EnemySpots, E_THING_ID_ENEMY_SPOT);
                    break;
                default:
                    self.MissionTypeError(string.Format("%i is not a valid mission type.", newMissionType));
                    break;
            }
        }
    }

    void PlayAnnouncement(string soundName)
    {
        if (Players.Size() > 0 && Players[0].Mo)
        {
            Players[0].Mo.A_StartSound("announcer/"..soundName, CHAN_AUTO, CHANF_OVERLAP, attenuation: ATTN_NONE);
        }
    }
#endregion

#region Defense Functions
    private void D_EndWave()
    {
        if (MissionType != MISSION_TYPE_DEFENSE)
        {
            Console.PrintF("D_EndWave() is accessible only in Defense missions.");
            return;
        }

        MissionState = d_Wave + 1 < d_WaveData.CountUsed() ? MISSION_STATE_DEFENSE_INTERMISSION_WAVE : MISSION_STATE_DEFENSE_COMPLETE;
        GeneralTic = D_WAVE_DELAY;
        if (d_Core)
        {
            d_Core.RestoreShield();
        }
        PlayAnnouncement("wavecomplete");
        TSS_Utils.DisplayMessage(
            StringTable.Localize("$TSS_MESSAGE_DEFENSE_WAVE_COMPLETE"),
            id: HUD_ID_TOP_MESSAGE,
            typeTime: 1,
            holdTime: 3 * TICRATE,
            fadeOutTime: 1 * TICRATE
        );
    }
#endregion

#region Excavation Functions
#endregion
}