
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

#Added
using { /UnrealEngine.com/Temporary/UI}
using { /Fortnite.com/UI }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

#######################################################################################################################
# Custom event class to hold an Event, Cancel, and Await function
	event_subscription := class:
	    CancelEvent:event() = event(){}
	 
	    Cancel():void=
	        CancelEvent.Signal()
	 
	# Async function that holds until the event is signaled or canceled
	AwaitForEvent(Event:event(t), Callback(:t):void, Subscription:event_subscription where t : type)<suspends>:void=
	    race:
	        loop:
	            # Await till event is signaled
	            Payload := Event.Await()
	            Callback(Payload)
	        # Await till event is cancelled
	        Subscription.CancelEvent.Await() 
	 
	# Call this function to subscribe to an event which spawns the AwaitForEvent async function to fire when the event is signaled
	(Event:event(t) where t : type).Subscribe(Callback(:t):void):event_subscription=
	    Subscription := event_subscription{}
	    spawn{ AwaitForEvent(Event, Callback, Subscription) }
	    return Subscription
#######################################################################################################################

# A Verse-authored creative device that can be placed in a level
VS_FieldUIDispalyer := class(creative_device):

    WidgetRef : UI.WB_MyVerseEventsUI = UI.WB_MyVerseEventsUI{}

    var MyUIPerPlayer : [player]?UI.WB_MyVerseEventsUI = map{}

    @editable
    ItemGranter : item_granter_device = item_granter_device{}

    @editable
    Button : button_device = button_device{}

    StringToMesage<localizes>(value:string) : message = "{value}"

    Text1: string = "Count Up"
    Text2: string = "Count Down"
    Text3: string = "Grant Gold"
    Text4: string = "Close"


    CreatePlayerWidget(Agent : agent): void= 
        if(Player := player[Agent]):
            NewWidget := WidgetRef #Newwidget:= UI.WB_MyVerseEventsUI
            if(PlayerUI := GetPlayerUI[Player], set MyUIPerPlayer[Player] = option{NewWidget}):
                PlayerUI.AddWidget(NewWidget, player_ui_slot{InputMode := ui_input_mode.All})
                PlayerUI.SetFocus(NewWidget)
                
                set NewWidget.Button1Text = StringToMesage(Text1)
                set NewWidget.Button2Text = StringToMesage(Text2)
                set NewWidget.Button3Text = StringToMesage(Text3)
                set NewWidget.Button4Text = StringToMesage(Text4)

                #Subscrbe Buttons to Verse Events
                NewWidget.Button1Press.Subscribe(OnClickButton1)

                spawn { WaitForPlayer(Player, NewWidget) }

    OnClickButton1():void=
        ()

    WaitForPlayer(Player : player, UIInstance : UI.WB_MyVerseEventsUI)<suspends>:void=
        var Close :logic = false
        loop:
            if(Close = false):
                race:
                    block:
                        UIInstance.Button1Press.Await()
                        UpdatePlayerWidgetFields(Player, +1)
                    block:
                        UIInstance.Button2Press.Await()
                        UpdatePlayerWidgetFields(Player, -1)
                    block:
                        UIInstance.Button3Press.Await()
                        ItemGranter.GrantItem(Player)
                    block:
                        UIInstance.Button4Press.Await()
                        OnPlayerRemoved(Player)
                        set Close = true

            else:
                break

    UpdatePlayerWidgetFields(Player : player, NewCount: int): void=
        if(WidgetOpt := MyUIPerPlayer[Player], Widget := WidgetOpt?):
            set Widget.CountInt += NewCount
    
    OnPlayerRemoved(Player:player):void=
        if(WidgetOpt := MyUIPerPlayer[Player], Widget := WidgetOpt?):
            if(PlayerUI:= GetPlayerUI[Player]):
                PlayerUI.RemoveWidget(Widget)
        
        var NewMap : [player]? UI.WB_MyVerseEventsUI= map{}
        for (key -> Value : MyUIPerPlayer, key <> Player):
            if( set NewMap[key] = Value):
                set MyUIPerPlayer = NewMap
            

    OnBegin<override>()<suspends>:void=
        
        Button.InteractedWithEvent.Subscribe(CreatePlayerWidget)

        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerRemoved)
