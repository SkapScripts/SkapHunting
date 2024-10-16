local Framework = Config.Framework
local QBCore, QBX
local spawnedAnimals = {}

if Framework == 'QBCore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Framework == 'QBOX' then
    QBX = exports.qbx_core
end

local function ServerNotify(source, message, type)
    if Config.NotificationSystem == "qbx" and Framework == "QBOX" then
        exports.qbx_core:Notify(message, type, 5000)
    elseif Config.NotificationSystem == "qb" and Framework == "QBCore" then
        TriggerClientEvent('QBCore:Notify', source, message, type)
    elseif Config.NotificationSystem == "ox" then
        TriggerClientEvent('ox_lib:notify', source, {description = message, type = type})
    end
end

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

if Framework == 'QBCore' then
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
                    ServerNotify(source, "Din jaktlicens har gått ut!", "error")
                    cb(false)
                end
            else
                cb(true)
            end
        else
            cb(false)
        end
    end)
elseif Framework == 'QBOX' then
    QBX.Functions.CreateCallback('SkapHunting:hasLicense', function(source, cb)
        local Player = QBX.GetPlayer(source)
        local licenseItem = Player.Functions.GetItemByName('hunting_license')

        if licenseItem then
            if licenseItem.info and licenseItem.info.expiryDate then
                local currentDate = os.time()
                local expiryDate = licenseItem.info.expiryDate

                if currentDate < expiryDate then
                    cb(true)
                else
                    ServerNotify(source, "Din jaktlicens har gått ut!", "error")
                    cb(false)
                end
            else
                cb(true)
            end
        else
            cb(false)
        end
    end)
end

RegisterNetEvent('SkapHunting:spawnAnimals')
AddEventHandler('SkapHunting:spawnAnimals', function()
    local src = source
    local Player = (Framework == 'QBCore' and QBCore.Functions.GetPlayer(src)) or QBX.GetPlayer(src)

    if #spawnedAnimals >= Config.MaxAnimalSpawns then
        ServerNotify(src, Config.EnoughAnimals, "error")
        return
    end

    local animalTypes = {}
    for animal, data in pairs(Config.Animals) do
        if math.random(100) <= data.spawn_chance then
            table.insert(animalTypes, animal)
        end
    end

    if #animalTypes == 0 then
        ServerNotify(src, Config.NoAnimals, "error")
        return
    end

    local animalType = animalTypes[math.random(#animalTypes)]
    TriggerClientEvent('SkapHunting:spawnAnimals', src, animalType)
    table.insert(spawnedAnimals, animalType)
end)

RegisterNetEvent('SkapHunting:startHunting')
AddEventHandler('SkapHunting:startHunting', function()
    local src = source
    local Player = (Framework == 'QBCore' and QBCore.Functions.GetPlayer(src)) or QBX.GetPlayer(src)

    if Player.Functions.GetItemByName('hunting_license') then
        ServerNotify(src, Config.HuntStart, "success")
        TriggerClientEvent('SkapHunting:startHunting', src)
    else
        ServerNotify(src, Config.NeedLicens, "error")
    end
end)

RegisterNetEvent('SkapHunting:stopHunting')
AddEventHandler('SkapHunting:stopHunting', function()
    local src = source
    local Player = (Framework == 'QBCore' and QBCore.Functions.GetPlayer(src)) or QBX.GetPlayer(src)
    ServerNotify(src, Config.HuntStopped, "error")
    TriggerClientEvent('SkapHunting:stopHunting', src)
    sendToDiscord(Config.LogHuntStopped, Player.PlayerData.name .. " has ended a hunting session", 15158332)
end)

RegisterNetEvent('SkapHunting:addLoot')
AddEventHandler('SkapHunting:addLoot', function(item)
    local src = source
    local Player = (Framework == 'QBCore' and QBCore.Functions.GetPlayer(src)) or QBX.GetPlayer(src)

    if Player.Functions.AddItem(item, 1) then
        ServerNotify(src, Config.Yougot .. item .. " " .. Config.FromAnimal, "success")
    else
        ServerNotify(src, Config.Notspace .. item .. ".", "error")
    end
end)

RegisterNetEvent('SkapHunting:sellAllItems')
AddEventHandler('SkapHunting:sellAllItems', function()
    local src = source
    local Player = (Framework == 'QBCore' and QBCore.Functions.GetPlayer(src)) or QBX.GetPlayer(src)

    local totalSale = 0
    local soldItems = {}

    for item, data in pairs(Config.SellableItems) do
        local playerItem = Player.Functions.GetItemByName(item)
        if playerItem and playerItem.amount > 0 then
            local amountToSell = playerItem.amount
            local price = math.random(data.minPrice, data.maxPrice)

            Player.Functions.RemoveItem(item, amountToSell)
            totalSale = totalSale + (amountToSell * price)
            table.insert(soldItems, item .. ": " .. amountToSell .. " for $" .. price)
        end
    end

    if totalSale > 0 then
        Player.Functions.AddMoney(Config.Money, totalSale)
        ServerNotify(src, Config.Sold .. " " .. totalSale .. " " .. Config.Type, "success")
    else
        ServerNotify(src, Config.Donthave, "error")
    end
end)
