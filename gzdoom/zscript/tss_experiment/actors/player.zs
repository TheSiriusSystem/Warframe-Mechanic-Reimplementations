class TSS_Player : DoomPlayer
{
    mixin TSS_ActorMixin;

    default
    {
        TSS_Player.ExcludeLevelFromTag true;
        Health 200;
        TSS_Player.Shield 300;
        TSS_Player.ShieldRegenDelay 10 * TICRATE;
        TSS_Player.ShieldRegenRate 1;
        TSS_Player.ShieldRegenAmount 1;
    } 
}