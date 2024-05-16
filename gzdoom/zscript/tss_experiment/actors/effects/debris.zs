class TSS_Debris : Actor
{
    default
    {
        +NOBLOCKMAP
        Radius 12.0;
        Height 8.0;
    }

    states
    {
        Spawn: // 30 seconds lifetime
            JUNK A 1015 {Frame = Random(0, 19);}
            #### # 1 A_FadeOut(1.0 / 35, FTF_REMOVE);
            stop;
    }
}