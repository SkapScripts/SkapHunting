local QBCore = exports['qb-core']:GetCoreObject()
local spawnedAnimals = {} 

local function sendToDiscord(name, message, color)
    local embed = {
        {
            ["color"] = color,
            ["title"] = name,
            ["description"] = message,
            ["footer"] = {
            ["text"] = os.date('%Y-%m-%d %H:%M:%S', os.time())
            }
        }
    }
    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({username = 'Hunting Logs', embeds = embed}), { ['Content-Type'] = 'application/json' })
end

QBCore.Functions.CreateCallback('SkapHunting:hasLicense', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local licenseItem = Player.Functions.GetItemByName('hunting_license')

    if licenseItem then
        if licenseItem.info and licenseItem.info.expiryDate then
            local currentDate = os.time()
            local expiryDate = licenseItem.info.expiryDate

            if currentDate < expiryDate then
                cb(true) 
            else
                TriggerClientEvent('QBCore:Notify', source, "Din jaktlicens har gått ut!", "error")
                cb(false) 
            end
        else
            cb(true) 
        end
    else
        cb(false) 
    end
end)

RegisterNetEvent('SkapHunting:spawnAnimals')
AddEventHandler('SkapHunting:spawnAnimals', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if #spawnedAnimals >= Config.MaxAnimalSpawns then
        TriggerClientEvent('QBCore:Notify', src, Config.EnoughAnimals, "error")
        return
    end

    local animalTypes = {}
    for animal, data in pairs(Config.Animals) do
        if math.random(100) <= data.spawn_chance then
            table.insert(animalTypes, animal)
        end
    end

    if #animalTypes == 0 then
        TriggerClientEvent('QBCore:Notify', src, Config.NoAnimals, "error")
        return
    end

    local animalType = animalTypes[math.random(#animalTypes)]
    TriggerClientEvent('SkapHunting:spawnAnimals', src, animalType)
    table.insert(spawnedAnimals, animalType) 
end)

RegisterNetEvent('SkapHunting:startHunting')
AddEventHandler('SkapHunting:startHunting', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.GetItemByName('hunting_license') then
        TriggerClientEvent('QBCore:Notify', src, Config.HuntStart, "success")
        TriggerClientEvent('SkapHunting:startHunting', src) 
    else
        TriggerClientEvent('QBCore:Notify', src, Config.NeedLicens, "error")
    end
end)

RegisterNetEvent('SkapHunting:stopHunting')
AddEventHandler('SkapHunting:stopHunting', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    TriggerClientEvent('QBCore:Notify', src, "Jakten har avslutats.", "error")
    TriggerClientEvent('SkapHunting:stopHunting', src)
    sendToDiscord(Config.LogHuntStopped, Player.PlayerData.name .. " Has ended a hunting session", 15158332) 
end)

RegisterNetEvent('SkapHunting:buyLicense')
AddEventHandler('SkapHunting:buyLicense', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.PlayerData.money.cash >= Config.LicensePrice then
        Player.Functions.RemoveMoney(Config.Money, Config.LicensePrice)
        Player.Functions.AddItem('hunting_license', 1)
        TriggerClientEvent('QBCore:Notify', src, Config.BoughtLicens, "success")
        sendToDiscord("Licens Köpt", Player.PlayerData.name .. " köpte en jaktlicens för $" .. Config.LicensePrice, 3447003) 
    else
        TriggerClientEvent('QBCore:Notify', src, Config.NotEnoughMoney, "error")
    end
end)

RegisterNetEvent('SkapHunting:addLoot')
AddEventHandler('SkapHunting:addLoot', function(item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.AddItem(item, 1) then
        TriggerClientEvent('QBCore:Notify', src, Config.Yougot .. item .. " " .. Config.FromAnimal, "success")
    else
        TriggerClientEvent('QBCore:Notify', src, Config.Notspace .. item .. ".", "error")
    end
end)


RegisterNetEvent('SkapHunting:removeAnimal')
AddEventHandler('SkapHunting:removeAnimal', function(animalType)
    for i, animal in ipairs(spawnedAnimals) do
        if animal.type == animalType then
            table.remove(spawnedAnimals, i)
            break
        end
    end
end)

RegisterNetEvent('SkapHunting:spawnAnimals')
AddEventHandler('SkapHunting:spawnAnimals', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if #spawnedAnimals >= Config.MaxAnimalSpawns then
        TriggerClientEvent('QBCore:Notify', src, Config.EnoughAnimals, "error")
        return
    end
    
    local animalTypes = {}
    for animal, _ in pairs(Config.Animals) do
        table.insert(animalTypes, animal)
    end
    local animalType = animalTypes[math.random(#animalTypes)]
    
    TriggerClientEvent('SkapHunting:spawnAnimals', src, animalType)
    table.insert(spawnedAnimals, animalType) 
end)


RegisterNetEvent('SkapHunting:spawnVehicle')
AddEventHandler('SkapHunting:spawnVehicle', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local npcConfig = Config.VehicleNPC

    TriggerClientEvent('SkapHunting:spawnVehicleClient', src, npcConfig.vehicle, npcConfig.vehicleSpawnCoords, npcConfig.vehicleSpawnHeading)
end)


RegisterNetEvent('SkapHunting:sellAllItems')
AddEventHandler('SkapHunting:sellAllItems', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    local totalSale = 0
    local soldItems = {}

    for item, data in pairs(Config.SellableItems) do
        local playerItem = Player.Functions.GetItemByName(item)
        if playerItem and playerItem.amount > 0 then
            local amountToSell = playerItem.amount
            local price = math.random(data.minPrice, data.maxPrice)

            Player.Functions.RemoveItem(item, amountToSell)
            totalSale = totalSale + (amountToSell * price)
            table.insert(soldItems, item .. ": " .. amountToSell .. " för $" .. price)
        end
    end

    if totalSale > 0 then
        Player.Functions.AddMoney(Config.Money, totalSale)  
        TriggerClientEvent('QBCore:Notify', src, Config.Sold .. " " .. totalSale .. " " .. Config.Type, "success")
    else
        TriggerClientEvent('QBCore:Notify', src, Config.Donthave, "error")
    end
end)

RegisterNetEvent('SkapHunting:returnVehicle')
AddEventHandler('SkapHunting:returnVehicle', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Hantera logik för att returnera fordonet
    TriggerClientEvent('SkapHunting:returnVehicleClient', src)
end)
