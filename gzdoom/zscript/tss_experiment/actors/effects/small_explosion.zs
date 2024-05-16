class TSS_SmallExplosion : TSS_Effect
{
    states
    {
        Spawn:
            BNG4 A 3 bright noDelay A_Explode(125, 128, 0, damagetype: 'Explosion');
            BNG4 BCDEFGHIJKLMN 3 bright;
            stop;
    }
}