local insideZone = {}
local insideRedZone = false

Citizen.CreateThread(function()
    for i, zone in ipairs(Config.RedZones) do
        local blip = AddBlipForRadius(zone.coords, zone.radius)
        SetBlipHighDetail(blip, true)
        SetBlipColour(blip, 1)
        SetBlipAlpha(blip, 150)
        SetBlipAsShortRange(blip, true)
        SetBlipDisplay(blip, 4)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(zone.name)
        EndTextCommandSetBlipName(blip)

        insideZone[i] = false
    end
end)

local function isPlayerInZone()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    for i, zone in ipairs(Config.RedZones) do
        local dist = #(coords - zone.coords)
        if dist < zone.radius then
            return true, i
        end
    end
    return false, nil
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local inZone, zoneIndex = isPlayerInZone()

        for i = 1, #Config.RedZones do
            insideZone[i] = (i == zoneIndex)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        for _, zone in ipairs(Config.RedZones) do
            local dist = #(coords - zone.coords)
            if dist < zone.radius + 100.0 then
                DrawMarker(1, zone.coords.x, zone.coords.y, zone.coords.z - 1.0, 0, 0, 0, 0, 0, 0, zone.radius * 2, zone.radius * 2, 2.0, 150, 0, 0, 150, false, true, 2, false, nil, nil, false)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        insideRedZone = false
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        for _, zone in ipairs(Config.RedZones) do
            if #(coords - zone.coords) < zone.radius then
                insideRedZone = true
                break
            end
        end
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victimEntity = args[2]
        local killerEntity = args[1]

        local playerPed = PlayerPedId()

        if killerEntity == playerPed and insideRedZone then
            local killerPlayer = NetworkGetPlayerIndexFromPed(killerEntity)
            if killerPlayer ~= -1 then
                local killerServerId = GetPlayerServerId(killerPlayer)
                TriggerServerEvent('redzone:playerKilledInZone', killerServerId)
            end
        end
    end
end)
