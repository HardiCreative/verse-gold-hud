using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }

gold_hud_device := class(creative_device):
    var PlayerGold : [player]int = map{}
    var PlayerTier : [player]int = map{}
    var PlayerWidgets : [player]text_block = map{}
    GoldThresholds : []int = array{0, 100, 300, 600, 1000, 1500}

    @editable
    GoldPowerup300 : stat_powerup_device = stat_powerup_device{}
    @editable
    GoldPowerup100 : stat_powerup_device = stat_powerup_device{}
    @editable
    GoldPowerup25 : stat_powerup_device = stat_powerup_device{}

    # Vending machines for each weapon tier
    @editable
    GreyVending : item_granter_device = item_granter_device{}
    @editable
    GreenVending : item_granter_device = item_granter_device{}
    @editable
    BlueVending : item_granter_device = item_granter_device{}
    @editable
    PurpleVending : item_granter_device = item_granter_device{}
    @editable
    OrangeVending : item_granter_device = item_granter_device{}
    @editable
    MythicVending : item_granter_device = item_granter_device{}

    StringToMessage<localizes>(InString : string) : message = "{InString}"

    OnBegin<override>()<suspends> : void =
        for (Player : GetPlayspace().GetPlayers()):
            InitializePlayerHUD(Player)
            if (Character := Player.GetFortCharacter[]):
                Character.EliminatedEvent().Subscribe(OnPlayerSpawn)
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
        GoldPowerup300.ItemPickedUpEvent.Subscribe(OnPowerup300PickedUp)
        GoldPowerup100.ItemPickedUpEvent.Subscribe(OnPowerup100PickedUp)
        GoldPowerup25.ItemPickedUpEvent.Subscribe(OnPowerup25PickedUp)

    InitializePlayerHUD(Player : player) : void =
        if (not PlayerWidgets[Player]):
            if (PlayerUI := GetPlayerUI[Player]):
                GoldWidget := text_block{
                    DefaultText := StringToMessage("Gold: 0"),
                    DefaultTextColor := NamedColors.Yellow
                }
                PlayerUI.AddWidget(GoldWidget)
                if( set PlayerWidgets[Player] = GoldWidget){}
                if(set PlayerGold[Player] = 0){}

    UpdatePlayerGold(Player : player) : void =
        if (GoldWidget := PlayerWidgets[Player]):
            if (Gold := PlayerGold[Player]):
                GoldWidget.SetText(StringToMessage("Gold: {Gold}"))
            else:
                GoldWidget.SetText(StringToMessage("Gold: 0"))

    UpdatePlayerWeapons(Player : player, Gold : int) : void =
        if (Gold >= 1500):
            MythicVending.CycleToRandomItem(Player)
        else:
            if (Gold >= 1000):
                OrangeVending.CycleToRandomItem(Player)
            else:
                if (Gold >= 600):
                    PurpleVending.CycleToRandomItem(Player)
                else:
                    if (Gold >= 300):
                        BlueVending.CycleToRandomItem(Player)
                    else:
                        if (Gold >= 100):
                            GreenVending.CycleToRandomItem(Player)
                        else:
                            GreyVending.CycleToRandomItem(Player)

    OnPlayerAdded(Player : player) : void =
        InitializePlayerHUD(Player)

    OnPlayerCollectedGold(Player : player, Amount : int) : void =
        var OldGold : int =
            if (Gold := PlayerGold[Player]):
                Gold
            else:
                0
        var NewGold : int = OldGold + Amount
        set PlayerGold[Player] = NewGold
        UpdatePlayerGold(Player)
 
        var OldTier : int =
            if (Tier := PlayerTier[Player]):
                Tier
            else:
                0
        var NewTier : int = 0
        for (Index -> Threshold : GoldThresholds):
            if (NewGold >= Threshold):
                set NewTier = Index
 
        if (NewTier > OldTier):
            set PlayerTier[Player] = NewTier
            UpdatePlayerWeapons(Player, NewGold)

    OnPowerup300PickedUp(Agent : agent) : void =
        if (Player := player[Agent]):
            OnPlayerCollectedGold(Player, 300)

    OnPowerup100PickedUp(Agent : agent) : void =
        if (Player := player[Agent]):
            OnPlayerCollectedGold(Player, 100)

    OnPowerup25PickedUp(Agent : agent) : void =
        if (Player := player[Agent]):
            OnPlayerCollectedGold(Player, 25)

    OnPlayerSpawn(Result : elimination_result) : void =
        if (ElimChar := Result.EliminatedCharacter, Agent := ElimChar.GetAgent[], Player := player[Agent], Gold := PlayerGold[Player]):
            UpdatePlayerWeapons(Player, Gold)
