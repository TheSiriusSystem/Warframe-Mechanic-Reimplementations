class TSS_Actor : Actor
{
    mixin TSS_ActorMixin;
}

class TSS_Shield : BasicArmorBonus
{
    default
    {
        Armor.SavePercent 100.0;
        Armor.SaveAmount 1;
        Armor.MaxSaveAmount int.Max;
    }
}