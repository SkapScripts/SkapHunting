Config = {}

-- Framework option: 'QBOX' or 'QBCore'
Config.Framework = 'QBCore' -- Change to 'QBCore' if using QBCore

-- Notification system: 'qbx', 'qb', or 'ox'
Config.NotificationSystem = 'qb'

-- Target system: 'ox' for ox_target, 'qb' for qb-target
Config.TargetSystem = 'qb'

Config.Lang = "eng" -- "eng" for english, "swe" for swedish.

Config.CommandsEnabled = true -- Want to be able to start and stop hunting via commands? Turn this to true
Config.StartHuntingCommand = "starthunt"
Config.StopHuntingCommand = "stophunt"

Config.VehicleKeysMethod = "sk-keys" -- Options: "MrNewbVehicleKeys" "sk-keys" "qb-vehiclekeys"

Config.NotificationSystem = "ox" -- Options: "qb", "ox"

Config.Money = "cash" -- Cash or Bank

Config.LicensePrice = 1000 -- Hunting Licens price

Config.JaktNPC = { model = "ig_joeminuteman", coords = vector3(-674.56, 5838.95, 16.40), heading = 133.60, scenario = "WORLD_HUMAN_COP_IDLES" }

Config.SellNPC = { model = "u_m_o_taphillbilly", coords = vector3(-674.19, 5836.13, 16.40), heading = 72.32, scenario = "WORLD_HUMAN_AA_COFFEE" }

Config.LicensNPC = { model = "s_m_m_snowcop_01", coords = vector3(444.96, -999.97, 37.72), heading = 1.28, scenario = "PROP_HUMAN_SEAT_CHAIR_DRINK" }

Config.VehicleNPC = { coords = vector3(-680.14, 5832.19, 16.33), heading = 98.84, model = "s_m_y_ammucity_01", scenario = "WORLD_HUMAN_GUARD_STAND",
    vehicle = "frr", vehicleSpawnCoords = vector3(-690.0, 5825.0, 16.0), vehicleSpawnHeading = 90.0,
}

Config.ParkingSpot = vector3(-681.91, 5831.72, 16.84)
Config.ParkingRadius = 3.0

Config.MaxAnimalSpawns = 600

Config.HuntingZones = {
    {
        coords = vector3(-1303.75, 4848.49, 145.51), radius = 300.0, minZ = 50.0, maxZ = 50.0
    }
}

Config.SellableItems = {
    ["meat"] = {minPrice = 50, maxPrice = 100},
    ["antlers"] = {minPrice = 70, maxPrice = 120},
    ["teeth"] = {minPrice = 30, maxPrice = 60},
}

Config.Animals = {
    ["deer"] = {    model = "a_c_deer",     loot = {"meat", "antlers"}, rare_loot = "antlers",  rare_chance = 5,   spawn_chance = 100, aggression = false, },
    ["pig"] = {     model = "a_c_pig",      loot = {"meat"},            rare_loot = "teeth",    rare_chance = 10,  spawn_chance = 100, aggression = false, },
}

Config.ShopItems = {
    [1] = {name = "WEAPON_MUSKET", price = 1500, amount = 5, info = {}, type = "weapon", slot = 1},
    [2] = {name = "WEAPON_KNIFE", price = 500, amount = 5, info = {}, type = "weapon", slot = 2}, 
    [3] = {name = "shotgun_ammo", price = 500, amount = 30, info = {}, type = "weapon", slot = 3}, 
}

if Config.Lang == "eng" then
    Config.Vehicle = "Vehicle takeout"
    Config.HuntZone = "Hunting Zone"
    Config.Animalblip = "Animals"
    Config.NotExists = "Trying to create a blip for an animal that does not exist."
    Config.Expired = "Your hunting license has expired"
    Config.HuntStart = "The hunt has begun!"
    Config.Stopped = "The hunt has been stopped!"
    Config.NilValue = "Config.Animals is nil or empty."
    Config.NoAnimals = "No animals available to spawn."
    Config.Cutting = "Cutting the animal..."
    Config.Founded = "You found "
    Config.Caneled = "You canceled the animal setup."
    Config.NeedKnife = "You need a knife to cut the animal!"
    Config.startHunt = "Start Hunt"
    Config.HuntStopped = "The hunt has stopped."
    Config.StopHunt = "Stop Hunt"
    Config.OpenShop = "Open Shop"
    Config.NeedLicens = "You are missing a license for this"
    Config.BoughtLicens = "You bought a licens"
    Config.HuntNPC = "Hunting"
    Config.Gear = "Hunting Gear"
    Config.NotActive = "No hunt is active."
    Config.Donthave = "You don't have anything to sell"
    Config.Sold = "Thanks for the items, Here you got "
    Config.Type = "$"
    Config.LogHuntStopped = "Hunt stopped"
    Config.NotEnoughMoney = "You don't have enough money"
    Config.Notspace = "You don't have space for "
    Config.Yougot = "You got "
    Config.FromAnimal = "from the animal"
    Config.Returned = "Vehicle returned successfully!"
    Config.NotinVehicle = "You are not in a vehicle."
    -- Target
    Config.cutAnimal = "Cut the animal"
    Config.startHunting = "Start hunt"
    Config.stopHunting = "Stop hunt"
    Config.huntStore = "Open hunt store"
    Config.huntSell = "Sell"
    Config.buyLicenze = "Buy License"
    Config.takeOutVehicle = "Take a vehicle out"
    Config.returnVehicles = "Return the vehicle"

elseif Config.Lang == "swe" then
    Config.Vehicle = "Fordonshämtning"
    Config.HuntZone = "Jaktzon"
    Config.Animalblip = "Djur"
    Config.NotExists = "Försöker skapa blip för ett djur som inte existerar."
    Config.EnoughAnimals = "Det finns redan tillräckligt med djur i området."
    Config.Expired = "Din jaktlicens har gått ut"
    Config.HuntStart = "Jakten har börjat!"
    Config.Stopped = "Jakten har stoppats!"
    Config.NilValue = "Config.Animals är nil eller tom."
    Config.NoAnimals = "Inga djur tillgängliga för att spawna."
    Config.Cutting = "Skär upp djuret..."
    Config.Founded = "Du hittade "
    Config.Caneled = "Du avbröt uppsättningen av djuret."
    Config.NeedKnife = "Du behöver en kniv för att skära upp djuret!"
    Config.startHunt = "Starta jakt"
    Config.HuntStopped = "Jakten har stoppats."
    Config.StopHunt = "Stoppa jakt"
    Config.OpenShop = "Öppna Butik"
    Config.NeedLicens = "Du saknar en licens för detta"
    Config.BoughtLicens = "Du köpte en licens"
    Config.HuntNPC = "Jakt"
    Config.Gear = "Jakt Utrustning"
    Config.NotActive = "Ingen jakt är aktiv."
    Config.Donthave = "Du har inget att sälja"
    Config.Sold = "Tack för varorna, Här har du "
    Config.Type = "Kr"
    Config.LogHuntStopped = "Jakten avslutad"
    Config.NotEnoughMoney = "Du har inte tillräckligt med pengar"
    Config.Notspace = "Du har inte plats för "
    Config.Yougot = "Du fick "
    Config.FromAnimal = "från djuret"
    Config.Returned = "Fordonet tillbaka lämnat!"
    Config.NotinVehicle = "Du är inte i ett fordon."
    -- Target
    Config.cutAnimal = "Skär upp djuret"
    Config.startHunting = "Starta jakten"
    Config.stopHunting = "Stoppa jakten"
    Config.huntStore = "Öppna jaktaffär"
    Config.huntSell = "Sälj"
    Config.buyLicenze = "Köp Licens"
    Config.takeOutVehicle = "Ta ut ett fordon"
    Config.returnVehicles = "Lämna tillbaka fordonet"
end



