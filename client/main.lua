local QBCore = exports['qb-core']:GetCoreObject()
local Player = QBCore.Functions.GetPlayerData()
local isHunting = false
local animalBlips = {}
local huntingZoneBlips = {}
local spawnedAnimals = {}

Citizen.CreateThread(function()
    spawnHuntingNPCs()
    spawnLicensNPCs()
    spawnVehicleNPC()
end)

local function GeneratePlate()
    local plate = QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(0)
    return plate:upper()
end

local function Notify(message, type)
    if Config.NotificationSystem == "qb" then
        QBCore.Functions.Notify(message, type)
    elseif Config.NotificationSystem == "ox" then
        exports['ox_lib']:notify({description = message, type = type})
    end
end

function removeHuntingZoneBlips()
    for _, blip in ipairs(huntingZoneBlips) do
        RemoveBlip(blip)
    end
    huntingZoneBlips = {}
end

function spawnVehicleNPC()
    local npcConfig = Config.VehicleNPC
    RequestModel(GetHashKey(npcConfig.model))
    while not HasModelLoaded(GetHashKey(npcConfig.model)) do
        Wait(1)
    end

    local vehiclePed = CreatePed(4, GetHashKey(npcConfig.model), npcConfig.coords.x, npcConfig.coords.y, npcConfig.coords.z, npcConfig.heading, false, true)
    FreezeEntityPosition(vehiclePed, true)
    SetEntityInvincible(vehiclePed, true)
    SetBlockingOfNonTemporaryEvents(vehiclePed, true)

    if npcConfig.scenario then
        TaskStartScenarioInPlace(vehiclePed, npcConfig.scenario, 0, true)
    end

    exports['qb-target']:AddTargetEntity(vehiclePed, {
        options = {
            {
                label = Config.takeOutVehicle,
                action = function() TriggerServerEvent('SkapHunting:spawnVehicle') end,
                icon = "fas fa-car",
                job = "all",
            },
            {
                label = Config.returnVehicles,
                action = function() 
                    TriggerServerEvent('SkapHunting:returnVehicle')
                end,
                icon = "fas fa-car-crash",
                job = "all",
            },
        },
        distance = 2.5
    })

    local vehicleBlip = AddBlipForCoord(npcConfig.coords.x, npcConfig.coords.y, npcConfig.coords.z)
    SetBlipSprite(vehicleBlip, 225)
    SetBlipDisplay(vehicleBlip, 4)
    SetBlipScale(vehicleBlip, 0.8)
    SetBlipColour(vehicleBlip, 2)
    SetBlipAsShortRange(vehicleBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Vehicle)
    EndTextCommandSetBlipName(vehicleBlip)
end

RegisterNetEvent('SkapHunting:spawnVehicleClient')
AddEventHandler('SkapHunting:spawnVehicleClient', function(vehicleModel, spawnCoords, spawnHeading)
    local model = GetHashKey(vehicleModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end

    local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, false)
    local plate = GeneratePlate() 
    SetVehicleNumberPlateText(vehicle, plate) 
    SetEntityAsMissionEntity(vehicle, true, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

    if Config.VehicleKeysMethod == "sk-keys" then
        exports['sk-keys']:givetemporary(plate)
    elseif Config.VehicleKeysMethod == "qb-vehiclekeys" then
        TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(vehicle))
    elseif Config.VehicleKeysMethod == "MrNewbVehicleKeys" then
        local boolean = true
        exports.MrNewbVehicleKeys:ToggleTempKey(boolean)
    end
end)

RegisterNetEvent('SkapHunting:returnVehicleClient')
AddEventHandler('SkapHunting:returnVehicleClient', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle and vehicle ~= 0 then
        DeleteVehicle(vehicle)
        Notify(Config.Returned, "success")
    else
        Notify(Config.NotinVehicle, "error")
    end
end)

function createHuntingZoneBlips()
    removeHuntingZoneBlips() 

    for _, zone in pairs(Config.HuntingZones) do
        local blip = AddBlipForRadius(zone.coords, zone.radius)
        SetBlipColour(blip, 3) 
        SetBlipAlpha(blip, 128)
        table.insert(huntingZoneBlips, blip)

        local zoneBlip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(zoneBlip, 141) 
        SetBlipDisplay(zoneBlip, 4)
        SetBlipScale(zoneBlip, 0.8)
        SetBlipColour(zoneBlip, 3)
        SetBlipAsShortRange(zoneBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.HuntZone)
        EndTextCommandSetBlipName(zoneBlip)
        table.insert(huntingZoneBlips, zoneBlip)
    end
end

function createAnimalBlip(animal)
    if not DoesEntityExist(animal) then
        print('Error:', Config.NotExists)
        return
    end
    local animalBlip = AddBlipForEntity(animal)
    SetBlipSprite(animalBlip, 141)
    SetBlipDisplay(animalBlip, 4)
    SetBlipScale(animalBlip, 0.6)
    SetBlipColour(animalBlip, 3)
    SetBlipAsShortRange(animalBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Animalblip)
    EndTextCommandSetBlipName(animalBlip)
    table.insert(animalBlips, animalBlip)
end

function IsPlayerInHuntingZone()
    local playerCoords = GetEntityCoords(PlayerPedId())
    for _, zone in pairs(Config.HuntingZones) do
        local distance = #(playerCoords - zone.coords)
        if distance <= zone.radius then
            return true, zone
        end
    end
    return false, nil
end

Citizen.CreateThread(function()
    while true do
        Wait(1000) 
        if isHunting then
            local isInZone, zone = IsPlayerInHuntingZone()
            if isInZone and #spawnedAnimals == 0 then
                spawnAnimalsInZone(zone)
            end
        end
    end
end)

RegisterNetEvent('SkapHunting:startHuntingClient')
AddEventHandler('SkapHunting:startHuntingClient', function()
    isHunting = true
    Notify(Config.HuntStart, "success")
    createHuntingZoneBlips() 
end)

function stopHunting()
    isHunting = false
    Notify(Config.HuntStopped, "error")
    removeAllAnimalBlips()
    removeHuntingZoneBlips()
end

function removeAllAnimalBlips()
    for _, blip in ipairs(animalBlips) do
        RemoveBlip(blip)
    end
    animalBlips = {}
end

function startHunting()
    isHunting = true
    Notify(Config.HuntStart, "success")
    createHuntingZoneBlips() 

    for _, zone in pairs(Config.HuntingZones) do
        spawnAnimalsInZone(zone)
    end

    Citizen.CreateThread(function()
        while isHunting do
            Wait(10000) 
        end
    end)
end

RegisterNetEvent('SkapHunting:startHuntingClient')
AddEventHandler('SkapHunting:startHuntingClient', function()
    startHunting()
end)


function spawnAnimalsInZone(zone)
    if not Config.Animals then
        print('Error: ', Config.NilValue)
        return
    end

    local playerCoords = GetEntityCoords(PlayerPedId())

    for i = 1, Config.MaxAnimalSpawns do
        local randomX, randomY, spawnCoords

        -- Ensure animals don't spawn too close to the player
        repeat
            randomX = math.random(-zone.radius, zone.radius)
            randomY = math.random(-zone.radius, zone.radius)
            spawnCoords = vector3(zone.coords.x + randomX, zone.coords.y + randomY, zone.minZ)
        until #(playerCoords - spawnCoords) > 50.0 and (randomX^2 + randomY^2) <= zone.radius^2

        -- Ground check to prevent animals spawning in the air
        local foundGround, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, zone.maxZ)
        if foundGround then
            spawnCoords = vector3(spawnCoords.x, spawnCoords.y, groundZ)
        else
            spawnCoords = vector3(spawnCoords.x, spawnCoords.y, zone.minZ)
        end

        if not isPlayerNearPlayerCoords(spawnCoords.x, spawnCoords.y) then
            local animalTypes = {}
            for animal, data in pairs(Config.Animals) do
                if math.random(100) <= data.spawn_chance then
                    table.insert(animalTypes, animal)
                end
            end

            if #animalTypes > 0 then
                local animalType = animalTypes[math.random(#animalTypes)]
                local animalData = Config.Animals[animalType]
                local animalModel = GetHashKey(animalData.model)

                RequestModel(animalModel)
                while not HasModelLoaded(animalModel) do
                    Wait(1)
                end

                local animal = CreatePed(5, animalModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, true)

                -- Create blip for the animal
                local animalBlip = AddBlipForEntity(animal)
                SetBlipSprite(animalBlip, 141)
                SetBlipDisplay(animalBlip, 4)
                SetBlipScale(animalBlip, 0.6)
                SetBlipColour(animalBlip, 3)
                SetBlipAsShortRange(animalBlip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(Config.Animalblip)
                EndTextCommandSetBlipName(animalBlip)

                table.insert(animalBlips, animalBlip)

                TaskWanderStandard(animal, 10.0, 10)

                if animalData.aggression then
                    TaskCombatPed(animal, PlayerPedId(), 0, 16)
                end

                exports['qb-target']:AddTargetEntity(animal, {
                    options = {
                        {
                            label = Config.cutAnimal,
                            action = function()
                                skinAnimal(animalType, animal)
                            end,
                            icon = "fas fa-knife",
                            job = "all",
                        },
                    },
                    distance = 2.5
                })

                table.insert(spawnedAnimals, {entity = animal, type = animalType})
                print('Spawned animal:', animalType, 'at:', spawnCoords)
            else
                print('Error:', Config.NoAnimals)
            end
        else
            print('Animal spawn location too close to player.')
        end
    end
end



function isPlayerNearPlayerCoords(x, y)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - vector3(x, y, playerCoords.z))
    return distance < 10.0
end

function skinAnimal(animalType, animal)
    local playerPed = PlayerPedId()
    local hasKnife = GetSelectedPedWeapon(playerPed) == GetHashKey("WEAPON_KNIFE")

    if hasKnife then
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_GARDENER_PLANT", 0, true)

        QBCore.Functions.Progressbar("skin_animal", Config.Cutting, 5000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            ClearPedTasks(playerPed)
            DeleteEntity(animal)

            local animalData = Config.Animals[animalType]
            for _, item in pairs(animalData.loot) do
                TriggerServerEvent('SkapHunting:addLoot', item)
            end

            if math.random(100) <= animalData.rare_chance then
                local rareItem = animalData.rare_loot[math.random(#animalData.rare_loot)]
                TriggerServerEvent('SkapHunting:addLoot', rareItem)
                Notify(Config.Founded .. rareItem .. "!", "success")
            end
        end, function()
            ClearPedTasks(playerPed)
            Notify(Config.Canceled, "error")
        end)
    else
        Notify(Config.NeedKnife, "error")
    end
end

Citizen.CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local inHuntingZone = false

        for _, zone in pairs(Config.HuntingZones) do
            if #(playerCoords - zone.coords) < zone.radius then
                inHuntingZone = true
                if not isHunting then
                    TriggerServerEvent('SkapHunting:spawnAnimals')
                end
            end
        end

        if not inHuntingZone and isHunting then
            isHunting = false
        end

        Wait(10000) 
    end
end)

RegisterNetEvent('SkapHunting:spawnAnimals')
AddEventHandler('SkapHunting:spawnAnimals', function(animalType)
    local animalData = Config.Animals[animalType]
    local spawnCoords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), math.random(-50, 50), math.random(-50, 50), 0)
    local animal = CreatePed(5, GetHashKey(animalData.model), spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, true)

    TaskWanderStandard(animal, 10.0, 10)
    if animalData.aggression then
        TaskCombatPed(animal, PlayerPedId(), 0, 16)
    end
end)

RegisterNetEvent('SkapHunting:startHunting')
AddEventHandler('SkapHunting:startHunting', function()
    isHunting = true
    createHuntingZoneBlips()

    for _, zone in pairs(Config.HuntingZones) do
        spawnAnimalsInZone(zone)
    end
end)

RegisterNetEvent('SkapHunting:stopHunting')
AddEventHandler('SkapHunting:stopHunting', function()
    isHunting = false
    removeAllAnimalBlips()
    removeHuntingZoneBlips()
    Notify(Config.Stopped, "error")
end)

function spawnHuntingNPCs()
    local jaktNPC = Config.JaktNPC
    RequestModel(GetHashKey(jaktNPC.model)) 
    while not HasModelLoaded(GetHashKey(jaktNPC.model)) do
        Wait(1)
    end
    local jaktPed = CreatePed(4, GetHashKey(jaktNPC.model), jaktNPC.coords.x, jaktNPC.coords.y, jaktNPC.coords.z, jaktNPC.heading, false, true)
    FreezeEntityPosition(jaktPed, true)
    SetEntityInvincible(jaktPed, true)
    SetBlockingOfNonTemporaryEvents(jaktPed, true)

    if jaktNPC.scenario then
        TaskStartScenarioInPlace(jaktPed, jaktNPC.scenario, 0, true)
    end

    exports['qb-target']:AddTargetEntity(jaktPed, {
        options = {
            {
                label = Config.startHunting,
                action = function()
                    QBCore.Functions.TriggerCallback('SkapHunting:hasLicense', function(hasLicense)
                        if hasLicense then
                            TriggerServerEvent('SkapHunting:startHunting')
                        else
                            Notify(Config.NeedLicens, "error")
                        end
                    end)
                end,
                icon = "fas fa-play",
                job = "all",
            },
            {
                label = Config.stopHunting,
                action = function() stopHunting() end,
                icon = "fas fa-stop",
                job = "all",
                canInteract = function() return isHunting end
            },
            {
                label = Config.huntStore,
                action = function()
                    QBCore.Functions.TriggerCallback('SkapHunting:hasLicense', function(hasLicense)
                        if hasLicense then
                            openShopMenu()
                        else
                            Notify(Config.NeedLicens, "error")
                        end
                    end)
                end,
                icon = "fas fa-shopping-cart",
                job = "all",
            },
            {
                label = Config.huntSell,
                action = function()
                   TriggerServerEvent('SkapHunting:sellAllItems')
                end,
                icon = "fas fa-money-bill-wave",
                job = "all",
            },
        },
        distance = 2.5
    })
    
    local jaktBlip = AddBlipForCoord(jaktNPC.coords.x, jaktNPC.coords.y, jaktNPC.coords.z)
    SetBlipSprite(jaktBlip, 141)
    SetBlipDisplay(jaktBlip, 4)
    SetBlipScale(jaktBlip, 0.8)
    SetBlipColour(jaktBlip, 1)
    SetBlipAsShortRange(jaktBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.HuntNPC)
    EndTextCommandSetBlipName(jaktBlip)
end

function spawnLicensNPCs()
    local LicensNPC = Config.LicensNPC
    RequestModel(GetHashKey(LicensNPC.model)) 
    while not HasModelLoaded(GetHashKey(LicensNPC.model)) do
        Wait(1)
    end
    local licensPed = CreatePed(4, GetHashKey(LicensNPC.model), LicensNPC.coords.x, LicensNPC.coords.y, LicensNPC.coords.z, LicensNPC.heading, false, true)
    FreezeEntityPosition(licensPed, true)
    SetEntityInvincible(licensPed, true)
    SetBlockingOfNonTemporaryEvents(licensPed, true)

    if LicensNPC.scenario then
        TaskStartScenarioInPlace(licensPed, LicensNPC.scenario, 0, true)
    end

    exports['qb-target']:AddTargetEntity(licensPed, {
        options = {
            {
                label = Config.buyLicenze,
                action = function() TriggerServerEvent('SkapHunting:buyLicense') end,
                icon = "fas fa-id-badge",
                job = "all",
            },
        },
        distance = 2.5
    })
end

function openShopMenu()
    local shopItems = {
        label = Config.Gear,
        slots = #Config.ShopItems,
        items = Config.ShopItems
    }
    TriggerServerEvent("inventory:server:OpenInventory", "shop", Config.Gear, shopItems)
end

if Config.CommandsEnabled then
    RegisterCommand(Config.StartHuntingCommand, function() TriggerEvent('SkapHunting:startHunting') end, false)
    RegisterCommand(Config.StopHuntingCommand, function() 
        if isHunting then 
            stopHunting() 
        else 
            Notify(Config.NotActive, "error") 
        end 
    end, false)
end
