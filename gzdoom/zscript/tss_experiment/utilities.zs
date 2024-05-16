class TSS_Utils : Object play
{
    const DIALOG_START_X = 160.0;
    const DIALOG_START_Y = 150.0;
    const DIALOG_HOLD_TIME = 3 * TICRATE;
    const DIALOG_FADE_OUT_TIME = 1 * TICRATE;

    static TSS_HudMessage DisplayMessage(string text, uint id = 0, name fontName = 'BigFont', int fontColor = Font.CR_WHITE, vector2 position = (160.0, 50.0), int alignment = TSS_HudMessage.ALIGN_CENTER, uint fadeInTime = 0, uint typeTime = 0, uint holdTime = 1 * TICRATE, uint fadeOutTime = 0, vector2 scale = (0.5, 0.5), PlayerInfo viewer = null)
    {
        TSS_HudMessage message = TSS_HudMessage.Create(text, id, fontName, fontColor, position, alignment, fadeInTime, typeTime, holdTime, fadeOutTime, scale, viewer);
		if (message)
		{
            ZSHudMessage().hudmessages.Push(message);
		}
        return message;
    }

    static TSS_HudMessage DisplayLabel(string text, uint id = 0, int fontColor = Font.CR_WHITE, vector2 position = (160.0, 50.0), int alignment = TSS_HudMessage.ALIGN_CENTER, uint holdTime = 1, uint fadeOutTime = 0, PlayerInfo viewer = null)
    {
        return DisplayMessage(text, id, 'SmallFont', fontColor, position, alignment, 0, 0, holdTime, fadeOutTime, (0.75, 0.75), viewer);
    }

    static bool IsActorFriendly(Actor anActor)
    {
        return (anActor.Player || (anActor.bIsMonster && anActor.bFriendly));
    }

    // Shorthand functions for getting event handlers.
    static TSS_SkillModifiers SkillModifiers()
    {
        return TSS_SkillModifiers(EventHandler.Find('TSS_SkillModifiers'));
    }

    static TSS_MissionHandler MissionHandler()
    {
        return TSS_MissionHandler(EventHandler.Find('TSS_MissionHandler'));
    }

    static TSS_PlayerLifeSystem PlayerLifeSystem()
    {
        return TSS_PlayerLifeSystem(EventHandler.Find('TSS_PlayerLifeSystem'));
    }

    static TSS_DefenseObjectTracker DefenseObjectTracker()
    {
        return TSS_DefenseObjectTracker(EventHandler.Find('TSS_DefenseObjectTracker'));
    }

    static TSS_BossTracker BossTracker()
    {
        return TSS_BossTracker(EventHandler.Find('TSS_BossTracker'));
    }

    static TSS_HudMessageHandler ZSHudMessage()
    {
        return TSS_HudMessageHandler(StaticEventHandler.Find('TSS_HudMessageHandler'));
    }
}