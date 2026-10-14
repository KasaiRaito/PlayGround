
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
VS_PlayGroun := class(creative_device):

    # Static Variables
    @editable WeaponGranter : item_granter_device = item_granter_device{} 
    @editable Spawners : []player_spawner_device = array{}
    @editable ElimsToWin : int = 5
    @editable EliminationManager : elimination_manager_device = elimination_manager_device{}
    @editable RoundSettings : round_settings_device = round_settings_device{}
    
    # Dinamic Variables
    var PlayerScore : [player]int = map{} # Stores player score
    
    # void start
    OnBegin<override>()<suspends>:void=
        for (Spawner : Spawners): # Foreach (spawner in spawners)
            Spawner.SpawnedEvent.Subscribe(OnPlayerSpawn)

        EliminationManager.EliminationEvent.Subscribe(OnPlayerMakeElimination)

        AllPlayers := GetPlayspace().GetPlayers()

        for (Player : AllPlayers):
            OnPlayerSpawn(Player)

    OnPlayerSpawn(Agent : agent):void=
        if (Player := player[Agent]):
            if(PlayerScore[Player]):
                GrantWeapon(Player)

            else if (set PlayerScore[Player] = 0):
                GrantWeapon(Player)

    OnPlayerMakeElimination(Agent : ?agent): void=
        if(Player := player[Agent?]):
            if (var IDX : int = PlayerScore[Player]):
                set IDX += 1

                if (set PlayerScore[Player] = IDX) {}
                
                if (IDX >= ElimsToWin):
                    RoundSettings.EndRound(Player)

                else:
                    GrantWeapon(Player)

    GrantWeapon(Player : player): void=
        if(WeaponIDX := PlayerScore[Player]):
            WeaponGranter.GrantItemIndex(Player, WeaponIDX)

        else:
            Print("GrantWeapon: PlayerScore entry not found!")

    GetPlayerScore(Player : player): int=
        if(Score := PlayerScore[Player]):
            return Score

        else:
            Print("GetPlayerScore: Player entry not found!")
            return -1

<#
    SetPlayerScore(Player : player, NewScore : int): void=
        if(PlayerScore[Player]):
            set PlayerScore[Player] = NewScore

        else:
            Print("SetPlayerScore: PlayerScore entry not found!")
#>