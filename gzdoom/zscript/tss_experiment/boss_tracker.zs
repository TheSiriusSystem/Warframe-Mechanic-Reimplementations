class TSS_BossTracker : EventHandler
{
    const HUD_START_X = 160.0;
    const HUD_START_Y = 25.0;

    array<Actor> TrackedBosses;

    override void WorldTick()
    {
        for (int i = 0; i < Min(TrackedBosses.Size(), 3); i++)
        {
            Actor boss = TrackedBosses[i];
            if (boss && !boss.InStateSequence(boss.CurState, boss.ResolveState("Death")))
            {
                double startY = 25.0 + (15.0 * i);
                TSS_Utils.DisplayMessage(
                    boss.GetTag(),
                    id: HUD_ID_BOSS_TAG + i,
                    fontName: 'BigFont',
                    position: (HUD_START_X, startY),
                    holdTime: 0,
                    scale: (0.5, 0.5)
                );
                TSS_Utils.DisplayLabel(
                    string.Format("\c[Red]%i", boss.Health),
                    id: HUD_ID_BOSS_HEALTH + i,
                    position: (HUD_START_X, startY + 8.0)
                );
            } else
            {
                TrackedBosses.Delete(i);
            }
        }
    }
}