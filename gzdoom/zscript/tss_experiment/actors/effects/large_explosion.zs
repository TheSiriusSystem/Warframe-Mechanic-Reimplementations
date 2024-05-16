class TSS_LargeExplosion : TSS_Effect
{
    states
    {
        Spawn:
            BOOM A 1 bright noDelay A_Explode(2500, 256, 0, damagetype: 'Explosion');
            BOOM B 3 bright;
            BOOM C 2 bright;
            BOOM DEFG 3 bright;
            BOOM H 1 bright;
            BOOM IJKLMNOPQRST 3 bright;
            BOOM UVWXY 3 bright;
            stop;
    }
}