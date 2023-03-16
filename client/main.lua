QBCore = Config.CoreExport
AdminPanel = { -- This should not need saying, but do not mess with these unless you know what you're doing.
    PlayerBlips = {},
    PlayerBlipsOnline = {},
    ServerInformation = {
        StaffCount = 0,
    },
    Spectating = false,
    DisplayingRadar = false,
    DisplayingBlips = false,
    DisplayingNames = false,
    FastSpeed = false,
    SpectatingPlayer = nil,
    SpectatingID = nil,
    ShowBlips = false,
    isInvisible = false,
    isFrozen = false,
    SavedCoords = nil,
    CurrentLogs = nil,
    SuperJump = false,
    NoRagdoll = false,
    GodMode = false,
    InfiniteStamina = false,
    NoClip = false,
    NewNoClip = false,
}
local ShowNames = false

local curLocation = {}
local curRotation = 0
local curHeading = 0

RegisterCommand('*adminpanel', function()
    TriggerServerEvent("919-admin:server:RefreshMenu", true)
    Wait(500)
    TriggerServerEvent("919-admin:server:RequestPanel")
end, false)
RegisterKeyMapping('*adminpanel', 'Open Panel (919ADMIN)', 'keyboard', Config.AdminPanelKey)

RegisterCommand('*noclip', function()
    TriggerServerEvent("919-admin:server:RequestNoClip")
end, false)
RegisterKeyMapping('*noclip', 'Noclip (919ADMIN)', 'keyboard', Config.NoClipKey)

RegisterCommand('*showNames', function()
    if Config.EnableNames then
        if not Config.AllPlayersUseNames then
            QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
                AdminPanel.DisplayingNames = not AdminPanel.DisplayingNames
                if AdminPanel.DisplayingNames then
                    ShowNames = true
                    TriggerServerEvent('919-admin:server:GetPlayersForBlips')
                else
                    ShowNames = false
                    TriggerServerEvent('919-admin:server:GetPlayersForBlips')
                end
            end, "playernames")
        else
            AdminPanel.DisplayingNames = not AdminPanel.DisplayingNames
            if AdminPanel.DisplayingNames then
                ShowNames = true
                TriggerServerEvent('919-admin:server:GetPlayersForBlips')
            else
                ShowNames = false
                TriggerServerEvent('919-admin:server:GetPlayersForBlips')
            end
        end
    end
end, false)
RegisterKeyMapping('*showNames', 'Show/hide player names (919ADMIN)', 'keyboard', Config.ShowNamesKey)

if Config.EnableReportCommand then
    RegisterCommand(Config.ReportCommand, function()
        SendNUIMessage({
            action = "reportscreen"
        })
        SetNuiFocus(true, true)
    end, false)
end

RegisterNetEvent('919-admin:client:ToggleNoClip', function()
    if Config.NoClipType == 2 then
        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), false))
        curLocation = { x = x, y = y, z = z }
        curRotation = GetEntityRotation(playerPed, false)
        curHeading = GetEntityHeading(playerPed)
        AdminPanel.NoClip = not AdminPanel.NoClip
        NoClip(AdminPanel.NoClip)
    elseif Config.NoClipType == 1 then
        AdminPanel.NewNoClip = not AdminPanel.NewNoClip
        toggleFreecam(AdminPanel.NewNoClip, AdminPanel.isInvisible)
    elseif Config.NoClipType == 3 then
        AdminPanel.NewNoClip = not AdminPanel.NewNoClip
        ToggleNoClip(AdminPanel.NewNoClip)
    end
    if AdminPanel.NewNoClip or AdminPanel.NoClip then
        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>ENABLED:</strong> Noclip enabled.")
    else
        TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', "<strong>DISABLED:</strong> Noclip disabled.")
    end
end)

RegisterNetEvent('919-admin:client:OpenMenu', function(playerList, DarkMode, SeeThrough, Notifications, ServerInformation, MaxPlayers, Version, hasPerms)
    SendNUIMessage({
        action = "open",
        name = GetPlayerName(PlayerId()),
        playerlist = playerList,
        darkmode = DarkMode,
        seethrough = SeeThrough,
        Notifications = Notifications,
        serverData = ServerInformation,
        maxplayers = MaxPlayers,
        version = Version,
        hasPerms = hasPerms
    })
    SetNuiFocus(true,true)
end)


RegisterNetEvent('919-admin:client:RefreshMenu', function(playerList, silent)
    SendNUIMessage({
        action = "refresh",
        name = GetPlayerName(PlayerId()),
        playerlist = playerList,
        serverData = AdminPanel.ServerInformation,
    })
    if not silent then
        TriggerEvent("919-admin:client:ShowPanelAlert", "success", "<strong>SUCCESS:</strong> Player list and info refreshed.")
    end
end)

RegisterNetEvent('919-admin:client:ViewPlayer', function(online, playerData)
    if online then
        SendNUIMessage({
            action = "viewonlineplayer",
            playerid = playerData
        })
        DebugTrace("NUIMessage: viewonlineplayer")
    else
        SendNUIMessage({
            action = "viewofflineplayer",
            playerdata = playerData
        })
        DebugTrace("NUIMessage: viewofflineplayer")
    end
    DebugTrace("Received player data. Online: "..(online and 'yes' or 'no'))
end)

RegisterNetEvent('919-admin:client:ResetMenu', function()
    SendNUIMessage({
        action = "noperms"
    })
end)

RegisterNetEvent('919-admin:client:WarnPlayer', function(warnedBy, reason)
    SendNUIMessage({
        action = "showwarning",
        by = warnedBy,
        reason = reason
    })
    SetNuiFocus(true, true)
    FreezeEntityPosition(PlayerPedId(), true)
end)

RegisterNUICallback('GiveItem', function(data)
    TriggerServerEvent("919-admin:server:GiveItem", data.Id, data.Item, data.Amount)
end)

RegisterNUICallback('SpawnVehicle', function(data)
    TriggerServerEvent('919-admin:server:RequestVehicleSpawn', data.Vehicle)
end)

RegisterNUICallback('ReportReply', function(data)
    if data ~= nil then
        TriggerServerEvent('919-admin:server:ReportReply', data)
    end
end)

RegisterNUICallback('ExitWarn', function()
    SetNuiFocus(false, false)
    FreezeEntityPosition(PlayerPedId(), false)
end)

RegisterNetEvent('919-admin:client:ShowPanelAlert', function(type, text)
    if type == "success" then 
        PlaySoundFrontend(-1, "Confirm", "GTAO_Exec_SecuroServ_Warehouse_PC_Sounds", true)
    elseif type == "danger" or type == "warning" or type == "error" then
        PlaySoundFrontend(-1, "Cancel", "GTAO_Exec_SecuroServ_Warehouse_PC_Sounds", true)
    end
    SendNUIMessage({
        action = "showalert",
        type = type,
        text = text
    })
end)

RegisterNetEvent('919-admin:client:ShowReportAlert', function(title, text)
    PlaySoundFrontend(-1, "Cancel", "GTAO_Exec_SecuroServ_Warehouse_PC_Sounds", true)
    SendNUIMessage({
        action = "showreportalert",
        title = title,
        text = text
    })
end)

RegisterNetEvent('919-admin:client:ForceReloadResources', function()
    TriggerServerEvent("919-admin:server:RequestResourcePageInfo")
end)

RegisterNetEvent('919-admin:client:ReceiveJobPageInfo', function(JobPageInfo)
    DebugTrace("Received job page info")
    SendNUIMessage({
        action = "jobinfo",
        jobinfo = JobPageInfo,
    })
end)

RegisterNetEvent('919-admin:client:ReceiveGangPageInfo', function(GangPageInfo)
    DebugTrace("Received gang page info")
    SendNUIMessage({
        action = "ganginfo",
        ganginfo = GangPageInfo,
    })
end)

RegisterNetEvent('919-admin:client:ReceiveResourcePageInfo', function(ResourcePageInfo)
    DebugTrace("Received resource page info")
    SendNUIMessage({
        action = "resourceinfo",
        resourceinfo = ResourcePageInfo,
    })
end)

RegisterNetEvent('919-admin:client:ReceiveBansInfo', function(BansInfo)
    DebugTrace("Received bans page info")
    SendNUIMessage({
        action = "bansinfo",
        bansinfo = BansInfo,
    })
end)

RegisterNetEvent('919-admin:client:ReceiveReportsInfo', function(ReportsInfo)
    DebugTrace("Received reports page info")
    SendNUIMessage({
        action = "reportsinfo",
        reportsinfo = ReportsInfo,
    })
end)

RegisterNetEvent('919-admin:client:ReceiveAdminChat', function(AdminChat)
    DebugTrace("Received admin chat")
    SendNUIMessage({
        action = "adminchat",
        adminchat = AdminChat,
    })
end)

RegisterNetEvent('919-admin:client:ReceiveVehiclesInfo', function(VehiclesInfo)
    DebugTrace("Received vehicles page info")
    SendNUIMessage({
        action = "vehiclesinfo",
        vehiclesinfo = VehiclesInfo,
    })
end)

RegisterNetEvent('919-admin:client:ReceiveLeaderboardInfo', function(money, vehicles)
    DebugTrace("Received leaderboard page info")
    SendNUIMessage({
        action = "leaderboardinfo",
        money = money,
        vehicles = vehicles,
    })
end)

RegisterNetEvent('919-admin:client:ReceiveItemsInfo', function(ItemsInfo)
    DebugTrace("Received items page info")
    SendNUIMessage({
        action = "itemsinfo",
        itemsinfo = ItemsInfo,
    })
end)


RegisterNetEvent('919-admin:client:ReceiveCharacters', function(players)
    DebugTrace("Received characters page info")
    SendNUIMessage({
        action = "characterslist",
        characters = players
    })
end)

RegisterNetEvent("919-admin:client:ReceiveCurrentLogs", function(currentLogs)
    AdminPanel.CurrentLogs = currentLogs
    SendNUIMessage({
        action = "logslist",
        logs = AdminPanel.CurrentLogs
    })
end)

RegisterNetEvent('919-admin:client:ToggleBlips', function()

end)

RegisterNetEvent("919-admin:client:ViewWarnings", function(warnings)
    DebugTrace("[919-admin:client:ViewWarnings] Received warnings")
    SendNUIMessage({
        action = "viewwarnings",
        warnings = warnings,
    })
end)

RegisterNetEvent('919-admin:client:SetPedModel', function(model)
    if model then
        Citizen.CreateThread(function()
            model = GetHashKey(model)
            RequestModel(model)
            while not HasModelLoaded(model) do
                RequestModel(model)
                Citizen.Wait(0)
            end
            SetPlayerModel(PlayerId(), model)
            SetPedComponentVariation(PlayerPedId(), 0, 0, 0, 2)
        end)
    end
end)

RegisterNetEvent('919-admin:client:DeleteAllEntities', function(entityType)
    if entityType == 1 then
        for vehicle in EnumerateVehicles() do
            if (not IsPedAPlayer(GetPedInVehicleSeat(vehicle, -1))) then 
                SetVehicleHasBeenOwnedByPlayer(vehicle, false) 
                SetEntityAsMissionEntity(vehicle, false, false) 
                DeleteVehicle(vehicle)
                if (DoesEntityExist(vehicle)) then 
                    DeleteVehicle(vehicle) 
                end
            end
        end
    elseif entityType == 2 then
        for ped in EnumeratePeds() do
            if (not IsPedAPlayer(ped)) then 
                SetEntityAsMissionEntity(ped, false, false) 
                DeleteEntity(ped)
                if (DoesEntityExist(ped)) then 
                    DeleteEntity(ped) 
                end
            end
        end
    elseif entityType == 3 then
        for object in EnumerateObjects() do
            SetEntityAsMissionEntity(object, false, false) 
            DeleteEntity(object)
            if (DoesEntityExist(object)) then 
                DeleteEntity(object) 
            end
        end
    end
end)

RegisterNetEvent('919-admin:client:RequestSpectate', function(playerServerId, tgtCoords, name)
	local localPlayerPed = PlayerPedId()
    AdminPanel.SpectatingPlayer = name
    AdminPanel.SpectatingID = playerServerId
    if playerServerId == -1 then 
        AdminPanel.SpectatePlayer(-1,-1,"")
    else
        if ((not tgtCoords) or (tgtCoords.z == 0.0)) then tgtCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerServerId))) end
        if playerServerId == GetPlayerServerId(PlayerId()) then 
            if AdminPanel.SavedCoords then
                RequestCollisionAtCoord(AdminPanel.SavedCoords.x, AdminPanel.SavedCoords.y, AdminPanel.SavedCoords.z)
                Wait(500)
                SetEntityCoords(playerPed, AdminPanel.SavedCoords.x, AdminPanel.SavedCoords.y, AdminPanel.SavedCoords.z, 0, 0, 0, false)
                AdminPanel.SavedCoords = nil
            end
            AdminPanel.SpectatePlayer(GetPlayerPed(PlayerId()),GetPlayerFromServerId(PlayerId()),GetPlayerName(PlayerId()))
            return
        else
            if not AdminPanel.SavedCoords then
                AdminPanel.SavedCoords = GetEntityCoords(PlayerPedId())
            end
        end
        SetEntityCoords(localPlayerPed, tgtCoords.x, tgtCoords.y, tgtCoords.z - 10.0, 0, 0, 0, false)
        local adminPed = localPlayerPed
        local playerId = GetPlayerFromServerId(playerServerId)
        repeat
            Wait(200)
            playerId = GetPlayerFromServerId(playerServerId)
        until ((GetPlayerPed(playerId) > 0) and (playerId ~= -1))
        AdminPanel.SpectatePlayer(GetPlayerPed(playerId),playerId,GetPlayerName(playerId))
    end
end)

RegisterNetEvent('919-admin:client:RequestInventory', function(TargetId)
    TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", TargetId)
end)
  
RegisterNetEvent('919-admin:client:setLivery', function(livery)
    local Veh = GetVehiclePedIsIn(PlayerPedId())
    if Veh then
        SetVehicleLivery(Veh, livery)
    end
end)

RegisterNetEvent('919-admin:client:SetPosition', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
end)

RegisterNetEvent('919-admin:client:Freeze', function()
    AdminPanel.isFrozen = not AdminPanel.isFrozen
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped)

    if veh ~= 0 then
        FreezeEntityPosition(ped, AdminPanel.isFrozen)
        FreezeEntityPosition(veh, AdminPanel.isFrozen)
    else
        FreezeEntityPosition(ped, AdminPanel.isFrozen)
    end
end)

RegisterNetEvent('919-admin:client:SendReport', function(name, src, msg, subject)
    TriggerServerEvent('919-admin:server:SendReport', name, src, msg, subject)
end)

RegisterNetEvent('919-admin:client:SaveCar', function(senderId)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped)

    if veh ~= nil and veh ~= 0 then
        local plate = QBCore.Functions.GetPlate(veh)
        local props = QBCore.Functions.GetVehicleProperties(veh)
        local hash = props.model
        local vehname = GetDisplayNameFromVehicleModel(hash):lower()
        if QBCore.Shared.Vehicles[vehname] ~= nil and next(QBCore.Shared.Vehicles[vehname]) ~= nil then
            TriggerServerEvent('919-admin:server:SaveCar', props, QBCore.Shared.Vehicles[vehname], `veh`, plate, senderId)
        else
            QBCore.Functions.Notify('You can\'t store this vehicle in your garage.', 'error')
        end
    else
        QBCore.Functions.Notify('You are not in a vehicle.', 'error')
    end
end)

RegisterNetEvent('919-admin:client:SetModel', function(skin)
    local ped = PlayerPedId()
    local model = GetHashKey(skin)

    SetEntityInvincible(ped, true)

    if IsModelInCdimage(model) and IsModelValid(model) then
        RequestModel(model)
        repeat Wait(0) until HasModelLoaded(model)
        SetPlayerModel(PlayerId(), model)

        if isPedAllowedRandom() then
            SetPedRandomComponentVariation(ped, true)
            SetPedDefaultComponentVariation(ped)
        end
        
		SetModelAsNoLongerNeeded(model)
	end
	SetEntityInvincible(ped, false)
end)

RegisterNetEvent("919-admin:client:MassDespawn", function ()
    for vehicle in EnumerateVehicles() do
        if (not IsPedAPlayer(GetPedInVehicleSeat(vehicle, -1))) then 
            SetVehicleHasBeenOwnedByPlayer(vehicle, false) 
            SetEntityAsMissionEntity(vehicle, false, false) 
            DeleteVehicle(vehicle)
            if (DoesEntityExist(vehicle)) then 
                DeleteVehicle(vehicle) 
            end
        end
    end
end)

RegisterNetEvent("919-admin:client:MassPedDespawn", function ()
    for ped in EnumeratePeds() do
        if (not IsPedAPlayer(ped)) then 
            SetEntityAsMissionEntity(ped, false, false) 
            DeleteEntity(ped)
            if (DoesEntityExist(ped)) then 
                DeleteEntity(ped) 
            end
        end
    end
end)

RegisterNetEvent("919-admin:client:MassObjDespawn", function ()
    for object in EnumerateObjects() do
        if (IsEntityAnObject(object)) then 
            SetEntityAsMissionEntity(object, false, false) 
            DeleteEntity(object)
            if (DoesEntityExist(object)) then 
                DeleteEntity(object) 
            end
        end
    end
end)

RegisterNetEvent("919-admin:client:MassEverythingDespawn", function ()
    for entity in EnumerateEntities() do
        if (IsEntityAPed(entity)) then 
            if not IsPedAPlayer(entity) then
                SetEntityAsMissionEntity(entity, false, false) 
                DeleteEntity(entity)
                if (DoesEntityExist(entity)) then 
                    DeleteEntity(entity) 
                end
            end
        else
            SetEntityAsMissionEntity(entity, false, false) 
            DeleteEntity(entity)
            if (DoesEntityExist(entity)) then 
                DeleteEntity(entity) 
            end
        end
    end
end)

RegisterNetEvent('919-admin:client:SetNuiFocus', function(focus, mouse)
    SetNuiFocus(focus, mouse)
end)

RegisterNetEvent('919-admin:client:ReceiveServerMetrics', function(serverMetrics)
    DebugTrace("Received server metrics")
    SendNUIMessage({
        action = "servermetrics",
        metrics = serverMetrics,
    })
end)

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------

RegisterNUICallback('close', function()
    SetNuiFocus(false, false)
    TriggerServerEvent('919-admin:server:ClosePanel')
    DebugTrace("NUICallback: close")
end)

RegisterNUICallback('LoadJobInfo', function()
    TriggerServerEvent("919-admin:server:RequestJobPageInfo")
    DebugTrace("NUICallback: LoadJobInfo")
end)

RegisterNUICallback('LoadGangInfo', function()
    TriggerServerEvent("919-admin:server:RequestGangPageInfo")
    DebugTrace("NUICallback: LoadGangInfo")
end)

RegisterNUICallback('LoadResourcesInfo', function()
    TriggerServerEvent("919-admin:server:RequestResourcePageInfo")
    DebugTrace("NUICallback: LoadResourcesInfo")
end)

RegisterNUICallback('LoadServerMetrics', function()
    TriggerServerEvent("919-admin:server:RequestServerMetrics")
    DebugTrace("NUICallback: LoadServerMetrics")
end)

RegisterNUICallback('LoadBansInfo', function()
    TriggerServerEvent("919-admin:server:RequestBansInfo")
    DebugTrace("NUICallback: LoadBansInfo")
end)

RegisterNUICallback('LoadReportsInfo', function()
    TriggerServerEvent("919-admin:server:RequestReportsInfo")
    DebugTrace("NUICallback: LoadReportsInfo")
end)

RegisterNUICallback('LoadAdminChat', function()
    TriggerServerEvent("919-admin:server:RequestAdminChat")
    DebugTrace("NUICallback: LoadAdminChat")
end)

RegisterNUICallback('AdminChatSend', function(info)
    TriggerServerEvent("919-admin:server:AdminChatSend", info['message'])
    DebugTrace("NUICallback: AdminChatSend")
end)

RegisterNUICallback('LoadItemsInfo', function()
    TriggerServerEvent("919-admin:server:RequestItemsInfo")
    DebugTrace("NUICallback: LoadItemsInfo")
end)

RegisterNUICallback('LoadVehiclesInfo', function()
    TriggerServerEvent("919-admin:server:RequestVehiclesInfo")
    DebugTrace("NUICallback: LoadVehiclesInfo")
end)

RegisterNUICallback('LoadLeaderboardInfo', function()
    TriggerServerEvent("919-admin:server:RequestLeaderboardInfo")
    DebugTrace("NUICallback: LoadLeadeaderboardInfo")
end)

RegisterNUICallback('LoadLogs', function()
    TriggerServerEvent("919-admin:server:RequestCurrentLogs")
    DebugTrace("NUICallback: LoadLogs")
end)

RegisterNUICallback('LoadCharacters', function()
    TriggerServerEvent("919-admin:server:RequestCharacters")
    DebugTrace("NUICallback: LoadCharacters")
end)

RegisterNUICallback('RequestViewPlayer', function(player)
    TriggerServerEvent("919-admin:server:RequestViewPlayer", player)
    DebugTrace("NUICallback: RequestViewPlayer")
end)

RegisterNUICallback('SendReport', function(info)
    TriggerServerEvent('919-admin:server:SendReport', info['subject'], info['info'], info['type'])
    DebugTrace("NUICallback: SendReport")
end)

RegisterNUICallback('ResourceAction', function(info)
    local currentResource = info['resource']
    if info['action'] == 'start' or info['action'] == 'stop' or info['action'] == 'restart' then
        TriggerServerEvent('919-admin:server:ResourceAction', currentResource, info['action'])
    end
    DebugTrace("NUICallback: ResourceAction ["..info['action'].."]")
end)

RegisterNUICallback('Action', function(info)
    local currentPlayer = info['id']
    if currentPlayer == 0 then
        local currentPlayer = GetPlayerServerId(PlayerId())
        TriggerServerEvent("qb-log:server:CreateLog", "adminactions", "Admin action used", "red", GetPlayerName(PlayerId())..'('..currentPlayer..') has used the following action: '..string.lower(info['text']), false)
    else
        TriggerServerEvent("qb-log:server:CreateLog", "adminactions", "Admin action used", "red", GetPlayerName(currentPlayer)..'('..currentPlayer..') has used the following action: '..string.lower(info['text']), false)
    end
    if info['action'] == 'uncuffSelf' then
        TriggerServerEvent('police:client:GetCuffed')
        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>SUCCESS:</strong> Uncuffed yourself!.')
    elseif info['action'] == 'revive' then
        TriggerServerEvent('919-admin:server:RevivePlayer', currentPlayer)
    elseif info['action'] == 'goto' then
        TriggerServerEvent('919-admin:server:GotoPlayer', currentPlayer)
    elseif info['action'] == 'bring' then
        local target = GetPlayerPed(currentPlayer)
        local plyCoords = GetEntityCoords(PlayerPedId())
        TriggerServerEvent('919-admin:server:BringPlayer', currentPlayer, plyCoords)
    elseif info['action'] == 'sendtolegion' then
        TriggerServerEvent('919-admin:server:SetPosition', currentPlayer, 215.75, -804.26, 30.81)
        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>SUCCESS:</strong> Sent player to Legion Square.')
    elseif info['action'] == 'sendtopillbox' then
        TriggerServerEvent('919-admin:server:SetPosition', currentPlayer, 299.01, -577.48, 43.26)
        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>SUCCESS:</strong> Sent player to Pillbox Hospital.')
    elseif info['action'] == 'sendtolsc' then
        TriggerServerEvent('919-admin:server:SetPosition', currentPlayer, -366.58, -126.01, 38.69)
        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>SUCCESS:</strong> Sent player to LS Customs.')
    elseif info['action'] == 'sendtomrpd' then
        TriggerServerEvent('919-admin:server:SetPosition', currentPlayer, 415.41, -993.4, 29.38)
        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>SUCCESS:</strong> Sent player to MRPD.')
    elseif info['action'] == 'sendtosandy' then
        TriggerServerEvent('919-admin:server:SetPosition', currentPlayer, 1963.56, 3735.19, 32.2)
        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>SUCCESS:</strong> Sent player to Sandy Shores.')
    elseif info['action'] == 'sendtograpeseed' then
        TriggerServerEvent('919-admin:server:SetPosition', currentPlayer, 1692.89, 4942.49, 42.32)
        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>SUCCESS:</strong> Sent player to Grapeseed.')
    elseif info['action'] == 'sendtopaleto' then
        TriggerServerEvent('919-admin:server:SetPosition', currentPlayer, 125.64, 6611.6, 31.86)
        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>SUCCESS:</strong> Sent player to Paleto Bay.')
    elseif info['action'] == 'sendtolsia' then
        TriggerServerEvent('919-admin:server:SetPosition', currentPlayer, -1021.81, -2701.25, 13.76)
        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>SUCCESS:</strong> Sent player to LS International Airport.')
    elseif info['action'] == 'kill' then
        TriggerServerEvent('919-admin:server:KillPlayer', currentPlayer)
    elseif info['action'] == 'save' then
        TriggerServerEvent('919-admin:server:SavePlayer', currentPlayer)
    elseif info['action'] == 'clothing' then
        TriggerServerEvent('919-admin:server:OpenSkinMenu', currentPlayer)
    elseif info['action'] == 'sclothing' then
        SendNUIMessage({
            action = "close"
        })
        SetNuiFocus(false, false)
        TriggerServerEvent('919-admin:server:OpenSkinMenu', GetPlayerServerId(PlayerId()))
    elseif info['action'] == 'feed' then
        TriggerServerEvent('919-admin:server:FeedPlayer', currentPlayer)
        Citizen.Wait(50)
        TriggerServerEvent("919-admin:server:RefreshMenu", true)
    elseif info['action'] == 'stress' then
        TriggerServerEvent('919-admin:server:RelieveStress', currentPlayer)
        Citizen.Wait(50)
        TriggerServerEvent("919-admin:server:RefreshMenu", true)
    elseif info['action'] == 'openinv' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            SendNUIMessage({
                action = "close"
            })
            SetNuiFocus(false, false)
            TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>SUCCESS:</strong> Opening player\'s inventory...')
            TriggerEvent('919-admin:client:RequestInventory', currentPlayer)
        end, "openinventory")
    elseif info['action'] == 'clearinv' then
        TriggerServerEvent('919-admin:server:ClearInventory', currentPlayer)
    elseif info['action'] == 'screenshot' then
        TriggerServerEvent('919-admin:server:ScreenshotSubmit', currentPlayer)
    elseif info['action'] == 'spectate' then
        TriggerServerEvent('919-admin:server:RequestSpectate', currentPlayer)
        SendNUIMessage({
            action = "close"
        })
        SetNuiFocus(false, false)
    elseif info['action'] == 'freeze' then
        TriggerServerEvent("919-admin:server:Freeze", currentPlayer)
    elseif info['action'] == 'revives' then
        TriggerServerEvent('919-admin:server:RevivePlayer', GetPlayerServerId(PlayerId()))
    elseif info['action'] == 'sendback' then
        TriggerServerEvent('919-admin:server:SendPlayerBack', currentPlayer)
    elseif info['action'] == 'goback' then
        TriggerServerEvent('919-admin:server:SendBackSelf')
    elseif info['action'] == 'tpm' then
        if IsWaypointActive() then
            TriggerEvent("QBCore:Command:GoToMarker")
            TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>SUCCESS:</strong> Teleported to marker!')
        else
            TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>ERROR:</strong> You have no marker set!')
        end
    elseif info['action'] == 'setpedmodel' then
        if info['model'] then
            TriggerServerEvent('919-admin:server:SetPedModel', currentPlayer, info['model'])
        end
    elseif info['action'] == 'invisible' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if not AdminPanel.isInvisible then
                SetEntityVisible(PlayerPedId(), false, false)
                AdminPanel.isInvisible = true
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>ENABLED:</strong> You are now invisible!')
            else
                SetEntityVisible(PlayerPedId(), true, false)
                AdminPanel.isInvisible = false
                TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', '<strong>DISABLED:</strong> You are now visible!')
            end
        end, "invisibility")
    elseif info['action'] == 'togradar' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            AdminPanel.DisplayingRadar = not AdminPanel.DisplayingRadar
            if AdminPanel.DisplayingRadar then
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>ENABLED:</strong> Force radar enabled!")
            else
                TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', "<strong>DISABLED:</strong> Force radar disabled!")
            end
        end, "forceradar")
    elseif info['action'] == 'togblips' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            AdminPanel.DisplayingBlips = not AdminPanel.DisplayingBlips
            if AdminPanel.DisplayingBlips then
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>ENABLED:</strong> Player blips enabled!")
            else
                TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', "<strong>DISABLED:</strong> Player blips disabled!")
            end
        end, "playerblips")
    elseif info['action'] == 'tognames' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            AdminPanel.DisplayingNames = not AdminPanel.DisplayingNames
            if AdminPanel.DisplayingNames then
                ShowNames = true
                TriggerServerEvent('919-admin:server:GetPlayersForBlips')
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>ENABLED:</strong> Player Names enabled!")
            else
                ShowNames = false
                TriggerServerEvent('919-admin:server:GetPlayersForBlips')
                TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', "<strong>DISABLED:</strong> Player Names disabled!")
            end
        end, "playerblips")
    elseif info['action'] == 'togspeed' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            AdminPanel.FastSpeed = not AdminPanel.FastSpeed
            if AdminPanel.FastSpeed then
                SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
                SetSwimMultiplierForPlayer(PlayerId(), 1.49)
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>ENABLED:</strong> Fast run enabled!")
            else
                SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                SetSwimMultiplierForPlayer(PlayerId(), 1.0)
                TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', "<strong>DISABLED:</strong> Fast run disabled!")
            end
        end, "fastrun")
    elseif info['action'] == 'god' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if not AdminPanel.GodMode then
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', '<strong>ENABLED:</strong> God mode enabled!')
                godModeChange()
            else
                TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', '<strong>DISABLED:</strong> God mode disabled!')
                godModeChange()
            end
        end, "godmode")
    elseif info['action'] == 'setmedriver' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local vehicle = QBCore.Functions.GetClosestVehicle()
            if vehicle then
                if IsVehicleSeatFree(vehicle,-1) then
                    SetPedIntoVehicle(PlayerPedId(),vehicle,-1)
                    TriggerEvent('919-admin:client:ShowPanelAlert', "success", "<strong>SUCCESS:</strong> You were teleported into the closest vehicle.")
                else
                    TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', '<strong>ERROR:</strong> Vehicle driver seat is occupied!')
                end
            end
        end, "setmedriver")
    elseif info['action'] == 'setmepass' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local vehicle = QBCore.Functions.GetClosestVehicle()
            if vehicle then
                if seat == nil then
                    seat = 0 
                elseif tonumber(seat) == 3 then
                    seat = 1
                elseif tonumber(seat) == 4 then
                    seat = 2
                end
                if IsVehicleSeatFree(vehicle,seat) then
                    SetPedIntoVehicle(PlayerPedId(),vehicle,seat)
                    TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> You were teleported into the closest vehicle.")
                else
                    TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', '<strong>ERROR:</strong> Vehicle passenger seat is occupied!')
                end
            end
        end, "setmepassenger")
    elseif info['action'] == 'clearblood' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            ClearPedBloodDamage(PlayerPedId())
            TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Blood is now gone.")
        end, "clearblood")
    elseif info['action'] == 'wetclothes' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            SetPedWetnessHeight(PlayerPedId(), 2.0)
            TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Your clothes are now wet.")
        end, "wetclothes")
    elseif info['action'] == 'dryclothes' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            ClearPedWetness(PlayerPedId())
            TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Your clothes are now dry.")
        end, "dryclothes")
    elseif info['action'] == 'deleteclosestveh' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local entity, distance = QBCore.Functions.GetClosestVehicle()
            if entity then
                if distance < 10.0 then
                    AdminPanel.DeleteEntity(entity)
                else
                    TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', '<strong>ERROR:</strong> Vehicle is over 10 units away (get closer)!')
                end
            end
        end, "deleteclosestvehicle")
    elseif info['action'] == 'deleteclosestped' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local entity, distance = AdminPanel.GetClosestPedNotPlayer()
            if entity then
                if not IsPedAPlayer(entity) then
                    if distance < 10.0 then
                        AdminPanel.DeleteEntity(entity)
                    else
                        TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', '<strong>ERROR:</strong> Ped is over 10 units away (get closer)!')
                    end
                else
                    TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', '<strong>ERROR:</strong> Can\'t delete - ped is a player!')
                end
            end
        end, "deleteclosestped")
    elseif info['action'] == 'deleteclosestobj' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local entity, distance = QBCore.Functions.GetClosestObject()
            if entity then
                if distance < 10.0 then                
                    AdminPanel.DeleteEntity(entity)
                else
                    TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', '<strong>ERROR:</strong> Object is over 10 units away (get closer)!')
                end
            end
        end, "deleteclosestobject")
    elseif info['action'] == 'repairv' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local vehicle = QBCore.Functions.GetClosestVehicle()
            if vehicle then
                SetVehicleUndriveable(vehicle, false)
                SetVehicleBodyHealth(vehicle, 1000)
                SetVehicleDeformationFixed(vehicle)
                SetVehicleEngineHealth(vehicle, 1000)
                SetVehicleEngineOn(vehicle, true, true)
                SetVehicleFixed(vehicle)
                SetVehicleOnGroundProperly(vehicle)
                SetVehicleGravity(vehicle, true)
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Repaired closest vehicle.")
            end
        end, "repairvehicle")
    elseif info['action'] == 'wash' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local vehicle = QBCore.Functions.GetClosestVehicle()
            if vehicle then
                SetVehicleDirtLevel(vehicle, 0)
                TriggerEvent('919-admin:client:ShowPanelAlert', "success", "<strong>SUCCESS:</strong> Washed closest vehicle.")
            end
        end, "washvehicle")
    elseif info['action'] == 'hotwire' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local vehicle = GetVehiclePedIsIn(PlayerPedId())
            if vehicle then
                exports['qb-vehiclekeys']:SetVehicleKey(GetVehicleNumberPlateText(vehicle), true)
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Hotwired your vehicle.")
            end
        end, "hotwirevehicle")
    elseif info['action'] == 'lockv' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local vehicle = QBCore.Functions.GetClosestVehicle()
            if vehicle then
                SetVehicleDoorsLocked(vehicle, 2)
                TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', "<strong>SUCCESS:</strong> Locked closest vehicle.")
            end
        end, "lockvehicle")
    elseif info['action'] == 'openBennys' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if hasPermission then
                TriggerEvent('qb-customs:client:EnterCustoms', {
                    coords = GetEntityCoords(PlayerPedId()),
                    heading = GetEntityHeading(PlayerPedId()),
                    categories = {
                        repair = true,
                        mods = true,
                        armor = true,
                        respray = true,
                        liveries = true,
                        wheels = true,
                        tint = true,
                        plate = true,
                        extras = true,
                        neons = true,
                        xenons = true,
                        horn = true,
                        turbo = true,
                        cosmetics = true,
                    }
                })
            end
        end, "openBennys")
    elseif info['action'] == 'unlockv' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local vehicle = QBCore.Functions.GetClosestVehicle()
            if vehicle then
                SetVehicleDoorsLocked(vehicle, 1)
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Unlocked closest vehicle.")
            end
        end, "unlockvehicle")
    elseif info['action'] == 'spawnvehicle' then
        if info['model'] then
            SendNUIMessage({
                action = "close"
            })
            SetNuiFocus(false, false)
            TriggerServerEvent('919-admin:server:RequestVehicleSpawn', info['model'])
        end
    elseif info['action'] == 'maxpupgrades' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle then
                SetVehicleModKit(vehicle, 0)
                SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false)
                SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false)
                SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false)
                SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 2, false)
                SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false)
                ToggleVehicleMod(vehicle, 17, true)
                ToggleVehicleMod(vehicle, 18, true)
                ToggleVehicleMod(vehicle, 19, true)
                ToggleVehicleMod(vehicle, 21, true)
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Gave your vehicle max performance upgrades.")
                SendNUIMessage({
                    action = "close"
                })
                SetNuiFocus(false, false)
            end
        end, "maxperformanceupgrades")
    elseif info['action'] == 'randvisualparts' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local vehicle, distance = QBCore.Functions.GetClosestVehicle()
            if vehicle then
                if distance < 10.0 then
                    SetVehicleModKit(vehicle, 0)
                    for i=1, 47 do
                        SetVehicleMod(vehicle, i, math.random(1, 4), true)
                    end
                    SetVehicleMod(vehicle, 49, math.random(1, 4), true)
                    TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Gave your vehicle random visual upgrades.")
                    SendNUIMessage({
                        action = "close"
                    })
                    SetNuiFocus(false, false)
                    --PlaySoundFrontend(-1, "CONTINUE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                else
                    TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', '<strong>ERROR:</strong> Vehicle is over 10 units away (get closer)!')
                end
            end
        end, "randomvisualparts")
    elseif info['action'] == 'setlivery' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local vehicle, distance = QBCore.Functions.GetClosestVehicle()
            if vehicle then
                if distance < 10.0 then
                    if info['livery'] then
                        SetVehicleModKit(vehicle, 0)
                        SetVehicleMod(vehicle, 48, tonumber(info['livery']), true)
                        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Set closest vehicle livery to "..GetLabelText(GetLiveryName(vehicle, tonumber(info['livery'])))..".")
                        SendNUIMessage({
                            action = "close"
                        })
                        SetNuiFocus(false, false)
                    end
                else
                    TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', '<strong>ERROR:</strong> Vehicle is over 10 units away (get closer)!')
                end
            end
        end, "setlivery")
    elseif info['action'] == 'setcolor' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if info['primarycolor'] and info['secondarycolor'] then
                local PrimaryColor = info['primarycolor']
                local SecondaryColor = info['secondarycolor']
                local vehicle, distance = QBCore.Functions.GetClosestVehicle()
                if vehicle then
                    if distance < 10.0 then
                        SetVehicleCustomPrimaryColour(vehicle, PrimaryColor.r, PrimaryColor.g, PrimaryColor.b)
                        SetVehicleCustomSecondaryColour(vehicle, SecondaryColor.r, SecondaryColor.g, SecondaryColor.b)
                        TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Set closest vehicle color.")
                        SendNUIMessage({
                            action = "close"
                        })
                        SetNuiFocus(false, false)
                    else
                        TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', '<strong>ERROR:</strong> Vehicle is over 10 units away (get closer)!')
                    end
                end
            end
        end, "setcolor")
    elseif info['action'] == 'filltank' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            local vehicle = QBCore.Functions.GetClosestVehicle()
            if vehicle then
                exports[Config.FuelScript]:SetFuel(vehicle, 100)
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Filled closest vehicle's fuel tank.")
            end
        end, "fillgastank")
    elseif info['action'] == 'kick' then       
        TriggerServerEvent("919-admin:server:KickPlayer", currentPlayer, info['reason'])
    elseif info['action'] == 'warn' then       
        TriggerServerEvent("919-admin:server:WarnPlayer", currentPlayer, info['reason'], info['citizenid'])
    elseif info['action'] == 'checkwarn' then
        TriggerServerEvent("919-admin:server:ViewWarnings", currentPlayer, info['citizenid'])
    elseif info['action'] == 'ban' then       
        info['timeamt'] = info['timeamt'] * 60 * 60
        TriggerServerEvent("919-admin:server:BanPlayer", currentPlayer, info['timeamt'], info['reason'], info['citizenid'])
    elseif info['action'] == 'givecash' or info['action'] == 'removecash' or info['action'] == 'givebank' or info['action'] == 'removebank' then
        local cashAmount = tonumber(info['amount'])
        TriggerServerEvent("919-admin:server:MonetaryAction", currentPlayer, info['action'], cashAmount)
        Citizen.Wait(50)
        TriggerServerEvent("919-admin:server:RefreshMenu", true)
    elseif info['action'] == 'setjob' then
        TriggerServerEvent("919-admin:server:SetJob", currentPlayer, info['jobname'], info['jobgrade'])
        Citizen.Wait(50)
        TriggerServerEvent("919-admin:server:RefreshMenu", true)
    elseif info['action'] == 'giveitem' then
        TriggerServerEvent("919-admin:server:GiveItem", currentPlayer, info['itemname'], info['itemamount'])
    elseif info['action'] == 'setgang' then
        TriggerServerEvent("919-admin:server:SetGang", currentPlayer, info['gangname'], info['ganggrade'])
        Citizen.Wait(50)
        TriggerServerEvent("919-admin:server:RefreshMenu", true)
    elseif info['action'] == 'loadipl' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if info['ipl'] ~= '' and info['ipl'] ~= nil then
                RequestIpl(info['ipl'])
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Requested IPL.")
            end
        end, "ipl")
    elseif info['action'] == 'unloadipl' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if info['ipl'] ~= '' and info['ipl'] ~= nil then
                RemoveIpl(info['ipl'])
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Unloaded IPL.")
            end
        end, "ipl")
    elseif info['action'] == 'setViewDistance' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if hasPermission then
                SetEntityViewDistance(info)
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> View distance changed!")
            end
        end, "setViewDistance")
    elseif info['action'] == 'copyEntityInfo' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if hasPermission then
                CopyToClipboard()
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Copied to clipbard!")
            end
        end, "copyEntityInfo")
    elseif info['action'] == 'freeaimMode' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if hasPermission then
                ToggleEntityFreeView()
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Freemode aim toggled!")
            end
        end, "freeaimMode")
    elseif info['action'] == 'displayVehicles' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if hasPermission then
                ToggleEntityVehicleView()
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Display vehicles toggled!")
            end
        end, "displayVehicles")
    elseif info['action'] == 'displayPeds' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if hasPermission then
                ToggleEntityPedView()
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Display Peds toggled.")
            end
        end, "displayPeds")
    elseif info['action'] == 'displayObjects' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if hasPermission then
                ToggleEntityObjectView()
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>SUCCESS:</strong> Display Entities toggled.")
            end
        end, "displayObjects")
    elseif info['action'] == 'vec3' then
        local Position = GetEntityCoords(PlayerPedId())
        local InVehicle = IsPedInAnyVehicle(PlayerPedId(), false)
        if InVehicle then
            Position = GetEntityCoords(GetVehiclePedIsIn(PlayerPedId(), false))
        end
        local string = "vector3("..string.format("%.2f", Position.x)..", "..string.format("%.2f", Position.y)..", "..string.format("%.2f", Position.z)..")"
        SendNUIMessage({
            action = "clipboard",
            string = string
        })
    elseif info['action'] == 'vec4' then
        local Position = GetEntityCoords(PlayerPedId())
        local Heading = GetEntityHeading(PlayerPedId())
        local InVehicle = IsPedInAnyVehicle(PlayerPedId(), false)
        if InVehicle then
            Position = GetEntityCoords(GetVehiclePedIsIn(PlayerPedId(), false))
            Heading = GetEntityHeading(GetVehiclePedIsIn(PlayerPedId(), false))
        end
        local string = "vector4("..string.format("%.2f", Position.x)..", "..string.format("%.2f", Position.y)..", "..string.format("%.2f", Position.z)..", "..math.floor(Heading)..")"
        SendNUIMessage({
            action = "clipboard",
            string = string
        })
    elseif info['action'] == 'heading' then
        local Heading = GetEntityHeading(PlayerPedId())
        if InVehicle then
            Heading = GetEntityHeading(GetVehiclePedIsIn(PlayerPedId(), false))
        end
        local string = "heading: "..math.floor(Heading)
        SendNUIMessage({
            action = "clipboard",
            string = string
        })
    elseif info['action'] == 'setweather' then
        if info['weather'] ~= '' and info['weather'] ~= nil then
            TriggerServerEvent('919-admin:server:SetWeather', info['weather'])
        end
    elseif info['action'] == 'noclip' then
        TriggerServerEvent("919-admin:server:RequestNoClip")
    elseif info['action'] == 'superjump' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            AdminPanel.SuperJump = not AdminPanel.SuperJump
            if AdminPanel.SuperJump then
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>ENABLED:</strong> Super jump enabled.")
            else
                TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', "<strong>DISABLED:</strong> Super jump disabled.")
            end
        end, "superjump")
    elseif info['action'] == 'noragdoll' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            AdminPanel.NoRagdoll = not AdminPanel.NoRagdoll
            if AdminPanel.NoRagdoll then
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>ENABLED:</strong> No ragdoll mode enabled.")
            else
                TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', "<strong>DISABLED:</strong> No ragdoll mode disabled.")
            end
        end, "noragdoll")
    elseif info['action'] == 'infinitestam' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            AdminPanel.InfiniteStamina = not AdminPanel.InfiniteStamina
            if AdminPanel.InfiniteStamina then
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>ENABLED:</strong> Infinite stamina enabled.")
            else
                TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', "<strong>DISABLED:</strong> Infinite stamina disabled.")
            end
        end, "infinitestam")
    elseif info['action'] == 'settime' then
        TriggerServerEvent('919-admin:server:SetTime', info['time'], info['time'])
    elseif info['action'] == 'reviveall' then
        TriggerServerEvent("919-admin:server:ReviveAll")
    elseif info['action'] == 'messageall' then
        if info['message'] then
            if #info['message'] > 5 then
                TriggerServerEvent("919-admin:server:MessageAll", info['message'])
            else
                TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', "<strong>ERROR:</strong> Message must be longer than 5 characters.")
            end
        else
            TriggerEvent('919-admin:client:ShowPanelAlert', 'danger', "<strong>ERROR:</strong> Please enter a message.")
        end
    elseif info['action'] == 'removejob' then
        TriggerServerEvent("919-admin:server:FireJob", currentPlayer)
    elseif info['action'] == 'removegang' then
        TriggerServerEvent("919-admin:server:FireGang", currentPlayer)
    elseif info['action'] == 'savecar' then
        TriggerServerEvent("919-admin:server:AddVehicleToGarage", currentPlayer)
    elseif info['action'] == 'massdv' then
        TriggerServerEvent("919-admin:server:DeleteAllEntities", 1) -- Vehicles
    elseif info['action'] == 'massdp' then
        TriggerServerEvent("919-admin:server:DeleteAllEntities", 2) -- Peds
    elseif info['action'] == 'massdo' then
        TriggerServerEvent("919-admin:server:DeleteAllEntities", 3) -- Objects
    elseif info['action'] == 'clearreports' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if hasPermission then
                TriggerServerEvent('919-admin:server:ClearJSON', 'reports')
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>CLEARED:</strong> reports!")
            end
        end, "clearreports")
    elseif info['action'] == 'clearadminchat' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if hasPermission then
                TriggerServerEvent('919-admin:server:ClearJSON', 'admin')
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>CLEARED:</strong> adminchat!")
            end
        end, "clearadminchat")
    elseif info['action'] == 'clearlogs' then
        QBCore.Functions.TriggerCallback("919-admin:server:HasPermission", function(hasPermission)
            if hasPermission then
                TriggerServerEvent('919-admin:server:ClearJSON', 'logs')
                TriggerEvent('919-admin:client:ShowPanelAlert', 'success', "<strong>CLEARED:</strong> logs!")
            end
        end, "clearlogs")
    end
    DebugTrace("NUICallback: Action ["..info['action'].."]")
end)

RegisterNUICallback("FirePlayerFromJob", function(citizenID)
    TriggerServerEvent("919-admin:server:FireJobByCitizenId", citizenID)
    DebugTrace("NUICallback: FirePlayerFromJob ["..citizenID.."]")
end)

RegisterNUICallback("FirePlayerFromGang", function(citizenID)
    TriggerServerEvent("919-admin:server:FireGangByCitizenId", citizenID)
    DebugTrace("NUICallback: FirePlayerFromGang ["..citizenID.."]")
end)

RegisterNUICallback("SetJobGrade", function(data)
    if data['citizenid'] ~= nil and data['grade'] ~= nil then
        TriggerServerEvent("919-admin:server:SetJobGradeByCitizenId", data['citizenid'], data['grade'])
        DebugTrace("NUICallback: SetJobGrade [".. data['citizenid']..", "..data['grade'].."]")
    else
        DebugTrace("NUICallback: SetJobGrade [nil, nil]")
    end
end)

RegisterNUICallback("SetGangGrade", function(data)
    if data['citizenid'] ~= nil and data['grade'] ~= nil then
        TriggerServerEvent("919-admin:server:SetGangGradeByCitizenId", data['citizenid'], data['grade'])
        DebugTrace("NUICallback: SetGangGrade [".. data['citizenid']..", "..data['grade'].."]")
    else
        DebugTrace("NUICallback: SetGangGrade [nil, nil]")
    end
end)

RegisterNUICallback("UnbanPlayer", function(data)
    if data['license'] ~= nil then
        TriggerServerEvent("919-admin:server:UnbanPlayer", data['license'])
    end
end)

RegisterNUICallback("DeleteReport", function(data)
    if data['id'] ~= nil then
        TriggerServerEvent("919-admin:server:DeleteReport", data['id'])
    end
end)

RegisterNUICallback("ClaimReport", function(data)
    if data['id'] ~= nil then
        TriggerServerEvent("919-admin:server:ClaimReport", data['id'])
    end
end)

RegisterNUICallback("DeleteCharacter", function(citizenId)
    if citizenId ~= nil then
        TriggerServerEvent("919-admin:server:DeleteCharacter", citizenId)
    end
end)

RegisterNUICallback("SaveSetting", function(data)
    if data['setting'] ~= nil and data['value'] ~= nil then
        TriggerServerEvent("919-admin:server:SaveAdminMenuSetting", data['setting'], data['value'])
        DebugTrace("NUICallback: SaveSetting [".. data['setting']..", "..data['value'].."]")
    else
        DebugTrace("NUICallback: SaveSetting [nil, nil]")
    end
end)

RegisterNUICallback("Refresh", function()
    TriggerServerEvent("919-admin:server:RefreshMenu")
end)
---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
function NoClip(on)
    if not on then
        local playerPed = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle( playerPed, false )
        ResetEntityAlpha(PlayerPedId())

        if ( inVehicle ) then
            local veh = GetVehiclePedIsUsing( playerPed )
            SetEntityInvincible( veh, false )
        else
            ClearPedTasksImmediately( playerPed )
        end

        SetUserRadioControlEnabled( true )
        SetPlayerInvincible( PlayerId(), false )
        SetEntityInvincible( target, false )
    else
        blockinput = true
        local playerPed = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(playerPed, false)
        SetEntityAlpha(PlayerPedId(), 127, false)
        if ( not inVehicle ) then
            LoadAnimDict("mp_sleep")
            loadedAnims = true
        end
    end
end

Citizen.CreateThread( function()
    local rotationSpeed = 2.5
    local forward = 1.8

    local speeds = { 0.1, 0.2, 0.5, 1.0, 2.0, 7.0, 15.0 }

    local moveUpKey = 44      -- Q
    local moveDownKey = 46    -- E
    local moveForwardKey = 32 -- W
    local moveBackKey = 33    -- S
    local rotateLeftKey = 34  -- A
    local rotateRightKey = 35 -- D
    local changeSpeedKey = 21 -- LSHIFT

    function updateForward()
        forward = speeds[ travelSpeed ]
    end

    function handleMovement(xVect,yVect)
        if IsControlJustPressed(1, changeSpeedKey) or IsDisabledControlJustPressed(1, changeSpeedKey) then
            travelSpeed = travelSpeed + 1
            if travelSpeed > getTableLength(speeds) then
                travelSpeed = 1
            end
            updateForward();
        end

        if IsControlPressed(1, moveUpKey) or IsDisabledControlPressed(1, moveUpKey) then curLocation.z = curLocation.z + forward / 2 ;
        elseif IsControlPressed(1, moveDownKey) or IsDisabledControlPressed(1, moveDownKey) then curLocation.z = curLocation.z - forward / 2 ; end

        if IsControlPressed(1, moveForwardKey) or IsDisabledControlPressed(1, moveForwardKey) then
            curLocation.x = curLocation.x + xVect
            curLocation.y = curLocation.y + yVect
        elseif IsControlPressed(1, moveBackKey) or IsDisabledControlPressed(1, moveBackKey) then
            curLocation.x = curLocation.x - xVect
            curLocation.y = curLocation.y - yVect
        end

        if IsControlPressed(1, rotateLeftKey) or IsDisabledControlPressed(1, rotateLeftKey) then
            curHeading = curHeading + rotationSpeed
        elseif IsControlPressed(1, rotateRightKey) or IsDisabledControlPressed(1, rotateRightKey) then
            curHeading = curHeading - rotationSpeed
        end
    end

     while true do
        Citizen.Wait(3)
        if AdminPanel.NoClip then
            local playerPed = PlayerPedId()
            if IsEntityDead( playerPed ) then
                AdminPanel.NoClip = false
                Citizen.Wait( 100 )
            else
                target = playerPed
                drawTxt("~r~NO CLIP ACTIVE ~s~[SPEED: ~y~"..speeds[travelSpeed].."~s~] - ~r~"..Config.NoClipKey.."~s~ TO STOP", 4, true, 0.50, 0.92, 0.6, 255, 255, 255, 255)
                local inVehicle = IsPedInAnyVehicle(playerPed, true)
                if inVehicle then
                    target = GetVehiclePedIsUsing(playerPed)
                end
                SetEntityVelocity(playerPed, 0.0, 0.0, 0.0)
                SetEntityRotation(playerPed, 0, 0, 0, 0, false)
                SetUserRadioControlEnabled(false)
                SetPlayerInvincible(PlayerId(), true)
                SetEntityInvincible(target, true)
                if not inVehicle then
                    TaskPlayAnim(playerPed, "mp_sleep", "bind_pose_180", 8.0, 0.0, -1, 9, 0, 0, 0, 0 )
                end
                local xVect = forward * math.sin(degToRad(curHeading)) * -1.0
                local yVect = forward * math.cos(degToRad(curHeading))
                handleMovement(xVect, yVect)
                SetEntityCoordsNoOffset(target, curLocation.x, curLocation.y, curLocation.z, true, true, true)
                SetEntityHeading(target, curHeading - rotationSpeed)
            end
        else
            Citizen.Wait(100)
        end
     end
end)

Citizen.CreateThread(function() 
    while true do
        Citizen.Wait(3)
        if AdminPanel.DisplayingRadar then
            DisplayRadar(true)
        end

        if AdminPanel.InfiniteStamina then
            RestorePlayerStamina(PlayerId(), 1.0)
        end

        if AdminPanel.SuperJump then
            SetSuperJumpThisFrame(PlayerId())
        end

        SetPedCanRagdoll(PlayerPedId(), not AdminPanel.NoRagdoll)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        if AdminPanel.Spectating then
            drawTxt("NOW SPECTATING "..AdminPanel.SpectatingPlayer.." [ID: "..AdminPanel.SpectatingID.."] - ~r~BACKSPACE~s~ TO STOP", 4, true, 0.47, 0.88, 0.6, 255, 255, 255, 255)
            drawTxt("[~y~LEFT ARROW~s~] Spectate Previous Player - [~y~RIGHT ARROW~s~] Spectate Next Player", 4, true, 0.47, 0.92, 0.6, 255, 255, 255, 255)
            if IsControlJustReleased(0, 177) then
                AdminPanel.SpectatePlayer(-1, -1, "")
            end
            if IsControlJustReleased(0, 174) then
                TriggerServerEvent('919-admin:server:requestPrevSpectate')
            end
            if IsControlJustReleased(0, 175) then
                TriggerServerEvent('919-admin:server:requestNextSpectate')
            end
        end
    end
end)

AdminPanel.SpectatePlayer = function(targetPed, target, name)
	local playerPed = PlayerPedId() -- yourself
	enable = true
	if (target == PlayerId() or target == -1) then 
		enable = false
	end
	if (enable) then
		if targetPed == playerPed then
			Wait(500)
			targetPed = GetPlayerPed(target)
		end
		local targetx,targety,targetz = table.unpack(GetEntityCoords(targetPed, false))

		RequestCollisionAtCoord(targetx,targety,targetz)
		NetworkSetInSpectatorMode(true, targetPed)
        SetEntityInvincible(playerPed,true)
		SetEntityVisible(playerPed,false)
        SetEntityCollision(playerPed, false, false)
        AdminPanel.Spectating = true
	else
		if AdminPanel.SavedCoords then
			RequestCollisionAtCoord(AdminPanel.SavedCoords.x, AdminPanel.SavedCoords.y, AdminPanel.SavedCoords.z)
			Wait(500)
			SetEntityCoords(playerPed, AdminPanel.SavedCoords.x, AdminPanel.SavedCoords.y, AdminPanel.SavedCoords.z, 0, 0, 0, false)
			AdminPanel.SavedCoords = nil
		end
		NetworkSetInSpectatorMode(false, targetPed)
        SetEntityInvincible(playerPed,false)
		SetEntityVisible(playerPed,true)
        SetEntityCollision(playerPed, true, true)
		QBCore.Functions.Notify('Stopped spectating.', 'success')
        AdminPanel.Spectating = false
	end
end

Citizen.CreateThread(function()
    while true do
        if AdminPanel.DisplayingBlips then
            local Players = {}
            QBCore.Functions.TriggerCallback('919-admin:server:GetPlayerPositions', function(p)
                Players = p
                for k,v in ipairs(AdminPanel.PlayerBlips) do
                    if AdminPanel.PlayerBlipsOnline[k] == nil or AdminPanel.PlayerBlipsOnline[k] == true then
                        AdminPanel.PlayerBlipsOnline[k] = false
                    end
                end
                for k, v in ipairs(Players) do
                    local playerCoords = v.pos
                    if AdminPanel.PlayerBlips[k] == nil then
                        AdminPanel.PlayerBlips[k] = AddBlipForCoord(playerCoords.x, playerCoords.y, playerCoords.z)
                        SetBlipSprite(AdminPanel.PlayerBlips[k], 1)
                        SetBlipColour(AdminPanel.PlayerBlips[k], 0)
                        SetBlipScale(AdminPanel.PlayerBlips[k], 0.75)
                        SetBlipCategory(AdminPanel.PlayerBlips[k], 7)
                        SetBlipDisplay(AdminPanel.PlayerBlips[k], 6)
                        SetBlipShrink(AdminPanel.PlayerBlips[k], true)
                        SetBlipAsShortRange(AdminPanel.PlayerBlips[k], true)
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentString('[ '..v.id..' ] '..v.name)
                        EndTextCommandSetBlipName(AdminPanel.PlayerBlips[k])
                    else
                        SetBlipCoords(AdminPanel.PlayerBlips[k], playerCoords.x, playerCoords.y, playerCoords.z);
                    end
                    AdminPanel.PlayerBlipsOnline[k] = true
                end
                for k,v in ipairs(AdminPanel.PlayerBlips) do
                    if AdminPanel.PlayerBlipsOnline[k] == false then
                        RemoveBlip(AdminPanel.PlayerBlips[k])
                        AdminPanel.PlayerBlips[k] = nil
                        AdminPanel.PlayerBlipsOnline[k] = nil
                    end
                end
            end)
            Citizen.Wait(1000)
        else
            for k,v in ipairs(AdminPanel.PlayerBlips) do
                if DoesBlipExist(AdminPanel.PlayerBlips[k]) then
                    RemoveBlip(AdminPanel.PlayerBlips[k])
                    AdminPanel.PlayerBlips[k] = nil
                    AdminPanel.PlayerBlipsOnline[k] = nil
                end
            end
            Citizen.Wait(10000)
        end
    end
end)

RegisterNetEvent('919-admin:client:Show', function(players)
    if Config.EnableNames then
        for _, player in pairs(players) do
            local playeridx = GetPlayerFromServerId(player.id)
            local ped = GetPlayerPed(playeridx)
            if not Config.NamesOverSelfHead and ped == PlayerPedId() then
            else
                local name = 'ID: '..player.id..' | '..player.name
                local Tag = CreateFakeMpGamerTag(ped, name, false, false, "", false)
                SetMpGamerTagAlpha(Tag, 0, 255) -- Sets "MP_TAG_GAMER_NAME" bar alpha to 100% (not needed just as a fail safe)
                SetMpGamerTagAlpha(Tag, 2, 255) -- Sets "MP_TAG_HEALTH_ARMOUR" bar alpha to 100%
                SetMpGamerTagAlpha(Tag, 4, 255) -- Sets "MP_TAG_AUDIO_ICON" bar alpha to 100%
                SetMpGamerTagAlpha(Tag, 6, 255) -- Sets "MP_TAG_PASSIVE_MODE" bar alpha to 100%
                SetMpGamerTagHealthBarColour(Tag, 25)  --https://wiki.rage.mp/index.php?title=Fonts_and_Colors

                if ShowNames then
                    SetMpGamerTagVisibility(Tag, 0, true) -- Activates the player ID Char name and FiveM name
                    SetMpGamerTagVisibility(Tag, 2, true) -- Activates the health (and armor if they have it on) bar below the player names
                    if NetworkIsPlayerTalking(playeridx) then
                        SetMpGamerTagVisibility(Tag, 4, true) -- If player is talking a voice icon will show up on the left side of the name
                    else
                        SetMpGamerTagVisibility(Tag, 4, false)
                    end
                    if GetPlayerInvincible(playeridx) then
                        SetMpGamerTagVisibility(Tag, 6, true) -- If player is in godmode a circle with a line through it will show up
                    else
                        SetMpGamerTagVisibility(Tag, 6, false)
                    end
                else
                    SetMpGamerTagVisibility(Tag, 0, false)
                    SetMpGamerTagVisibility(Tag, 2, false)
                    SetMpGamerTagVisibility(Tag, 4, false)
                    SetMpGamerTagVisibility(Tag, 6, false)
                    RemoveMpGamerTag(Tag) -- Unloads the tags till you activate it again
                end
            end
        end
        Wait(5000)
        if ShowNames then
            TriggerServerEvent('919-admin:server:GetPlayersForBlips')
        end
    end
end)