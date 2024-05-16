class TSS_PlayerLifeSystem : EventHandler
{
    override void PlayerSpawned(PlayerEvent event)
    {
        Actor pawn = Players[event.PlayerNumber].Mo;
        if (pawn && pawn.CountInv('TSS_PlayerLife') < MAX_PLAYER_LIVES)
        {
            pawn.GiveInventory('TSS_PlayerLife', MAX_PLAYER_LIVES);
        }
    }

    override void PlayerDied(PlayerEvent event)
    {
        Actor pawn = Players[event.PlayerNumber].Mo;
        if (pawn)
        {
            pawn.TakeInventory('TSS_PlayerLife', 1);
        }
    }
}

class TSS_PlayerLife : Inventory
{
    default
    {
        +INVENTORY.INVBAR
        +INVENTORY.HUBPOWER
        +INVENTORY.PERSISTENTPOWER
        +INVENTORY.KEEPDEPLETED
        +INVENTORY.UNDROPPABLE
        Inventory.Icon "I_LIFE";
        Inventory.MaxAmount MAX_PLAYER_LIVES;
    }
}