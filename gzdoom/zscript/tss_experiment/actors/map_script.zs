class TSS_MapScript : Actor
{
    default
    {
        +NOBLOCKMAP
        +NOSECTOR
        +NOINTERACTION
    }

    // args[0]: mission_type
    override void PostBeginPlay()
    {
        TSS_Utils.MissionHandler().StartMission(Args[0]);
    }

    virtual void MapEvent(int arg1, int arg2, int arg3) {}

    static void MapEventBridge(Actor activator, int arg1, int arg2, int arg3)
    {
        ActorIterator iterator = Level.CreateActorIterator(1, 'TSS_MapScript');
        TSS_MapScript self;
        while (self = TSS_MapScript(iterator.Next()))
        {
            self.MapEvent(arg1, arg2, arg3);
            break;
        }
    }

    protected void D_MakeWaveData(uint wave, string waveEnemies, string waveName = "", string waveMinibosses = "", int waveSpawnGroupSizeMin = 3, int waveSpawnGroupSizeMax = 5, int waveSpawnIntervalMin = 5 * TICRATE, int waveSpawnIntervalMax = 15 * TICRATE, string waveMusic = "keep", string finaleEnemies = "", string finaleMusic = "none", string healthItems = "", string weaponItems = "", string ammoItems = "", string powerupItems = "", int killGoal = 50)
    {
        TSS_MissionHandler global = TSS_Utils.MissionHandler();
        if (global.MissionType != MISSION_TYPE_DEFENSE)
        {
            Console.PrintF("MapScript.D_MakeWaveData() is accessible only in Defense missions.");
            return;
        }

        dictionary waveInfo = dictionary.Create();
        waveInfo.Insert("name", waveName);
        waveInfo.Insert("enemies", waveEnemies);          // wave.enemies: enemy1,enemy2
        waveInfo.Insert("minibosses", waveMinibosses);    // wave.minibosses: enemy1=chance,enemy2=chance
        waveInfo.Insert("spawn_group_size", string.Format("%i:%i", waveSpawnGroupSizeMin, waveSpawnGroupSizeMax));
        waveInfo.Insert("spawn_interval", string.Format("%i:%i", waveSpawnIntervalMin, waveSpawnIntervalMax));
        waveInfo.Insert("music", waveMusic);              // wave.music: LUMPNAME or path/to/music

        dictionary finaleInfo = dictionary.Create();
        finaleInfo.Insert("enemies", finaleEnemies);        // finale.enemies: \bossenemy1,enemy2
        finaleInfo.Insert("music", finaleMusic);            // finale.music: LUMPNAME or path/to/music

        dictionary itemInfo = dictionary.Create();
        itemInfo.Insert("health", healthItems);             // items.health: item1,item2
        itemInfo.Insert("weapons", weaponItems);            // items.weapons: item1,item2
        itemInfo.Insert("ammo", ammoItems);                 // items.ammo: item1,item2
        itemInfo.Insert("powerups", powerupItems);          // items.powerups: item1,item2

        dictionary waveData = dictionary.Create();
        waveData.Insert("kill_goal", string.Format("%i", Max(killGoal, 1)));
        waveData.Insert("wave", waveInfo.ToString());
        waveData.Insert("finale", finaleInfo.ToString());
        waveData.Insert("items", itemInfo.ToString());

        TSS_Utils.MissionHandler().d_WaveData.Insert(wave, waveData.ToString());
    }
}