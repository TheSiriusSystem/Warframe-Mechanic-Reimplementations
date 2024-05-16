class TSS_DefenseObjectTracker : EventHandler
{
    const COUNT_FORMAT = "\c[%s]%i";
    const HUD_START_X = -40.0;
    const HUD_ALIGNMENT = TSS_HudMessage.ALIGN_LEFT;
    const HUD_FONT = "SMALLFONT";
    const HUD_FONT_COLOR_HEALTH = "Red";
    const HUD_FONT_COLOR_SHIELD = "LightBlue";
    const HUD_FONT_COLOR_OVERGUARD = "Cyan";
    const HUD_FONT_COLOR_INVULNERABLE_HEALTH = "DarkGray";
    const HUD_FONT_COLOR_INVULNERABLE_SHIELD = "White";
    const HUD_FONT_COLOR_INVULNERABLE_OVERGUARD = "Ice";
    const HUD_FONT_COLOR_EXCAVATOR_STAT = "Ice";

    array<TSS_DefenseObject> TrackedDefenseObjects;
    private bool WarnExcavatorLowPower;

    override void WorldTick()
    {
        if (Level.MapTime % TICRATE == 17 || Level.MapTime % TICRATE == 0)
        {
            WarnExcavatorLowPower = !WarnExcavatorLowPower;
        }

        for (int i = 0; i < Min(TrackedDefenseObjects.Size(), 3); i++)
        {
            TSS_DefenseObject defenseObject = TrackedDefenseObjects[i];
            if (defenseObject && !defenseObject.InStateSequence(defenseObject.CurState, defenseObject.ResolveState("Death")))
            {
                TSS_Excavator excavator = TSS_Excavator(TrackedDefenseObjects[i]);
                double startY = TSS_Utils.MissionHandler().MissionType == MISSION_TYPE_NONE ? 25.0 : 40.0;
                vector2 headerPosition = (HUD_START_X, OffsetYByIndex(startY, i));
                vector2 subheaderPosition = (HUD_START_X, OffsetYByIndex(startY + 5.0, i));
                if (!excavator)
                {
                    TSS_Utils.DisplayLabel(
                        GetStatsString(defenseObject, false),
                        id: HUD_ID_DEFENSE_OBJECT_MESSAGE_1 + i,
                        position: headerPosition,
                        alignment: HUD_ALIGNMENT
                    );
                    TSS_Utils.DisplayLabel(
                        defenseObject.GetTag(),
                        id: HUD_ID_DEFENSE_OBJECT_MESSAGE_2 + i,
                        position: subheaderPosition,
                        alignment: HUD_ALIGNMENT
                    );
                } else
                {
                    uint timeLeft = excavator ? excavator.MaxTime - excavator.TimePassed : 0;
                    string powerText;
                    if (excavator.Power < timeLeft)
                    {
                        powerText = string.Format(COUNT_FORMAT.."%s", excavator.Power <= 25 && WarnExcavatorLowPower ? "Brick" : HUD_FONT_COLOR_EXCAVATOR_STAT, excavator.Power, "%");
                        if (excavator.Power <= 0)
                        {
                            powerText = powerText.." HALTED";
                        }
                    } else
                    {
                        powerText = "\c[DarkGray]FULL";
                    }

                    TSS_Utils.DisplayLabel(
                        string.Format("%s "..GetStatsString(excavator, true), excavator.GetTag()),
                        id: HUD_ID_DEFENSE_OBJECT_MESSAGE_1 + i,
                        position: headerPosition,
                        alignment: HUD_ALIGNMENT
                    );
                    TSS_Utils.DisplayLabel(
                        string.Format("Time: "..COUNT_FORMAT.."s \c-Power: %s", HUD_FONT_COLOR_EXCAVATOR_STAT, timeLeft, powerText),
                        id: HUD_ID_DEFENSE_OBJECT_MESSAGE_2 + i,
                        position: subheaderPosition,
                        alignment: HUD_ALIGNMENT
                    );
                }
            } else
            {
                TrackedDefenseObjects.Delete(i);
            }
        }
    }

    private int OffsetYByIndex(double y, double index)
    {
        return y + (15.0 * (index));
    }

    private string GetStatsString(TSS_DefenseObject defenseObject, bool reverse)
    {
        string stats = defenseObject.Overguard <= 0 ? "" : string.Format(COUNT_FORMAT, defenseObject.DamageFactor > 0.1 ? HUD_FONT_COLOR_OVERGUARD : HUD_FONT_COLOR_INVULNERABLE_OVERGUARD, defenseObject.Overguard);
        string format = !reverse ? "%s"..COUNT_FORMAT : COUNT_FORMAT.."%s";
        int shield = defenseObject.GetShield();
        if (!reverse)
        {
            if (shield != -1)
            {
                stats = string.Format(format, stats, defenseObject.DamageFactor > 0.1 ? HUD_FONT_COLOR_SHIELD : HUD_FONT_COLOR_INVULNERABLE_SHIELD, shield);
            }
            stats = string.Format(format, stats, defenseObject.DamageFactor > 0.1 ? HUD_FONT_COLOR_HEALTH : HUD_FONT_COLOR_INVULNERABLE_HEALTH, defenseObject.Health);
        } else
        {
            if (shield != -1)
            {
                stats = string.Format(format, defenseObject.DamageFactor > 0.1 ? HUD_FONT_COLOR_SHIELD : HUD_FONT_COLOR_INVULNERABLE_SHIELD, shield, stats);
            }
            stats = string.Format(format, defenseObject.DamageFactor > 0.1 ? HUD_FONT_COLOR_HEALTH : HUD_FONT_COLOR_INVULNERABLE_HEALTH, defenseObject.Health, stats);
        }
        return stats;
    }
}