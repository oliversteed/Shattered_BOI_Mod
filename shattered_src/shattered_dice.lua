local shatteredLib = {}

local SHATTERED_PLAYER = Isaac.GetPlayerTypeByName("Shattered", false)
local BSHATTERED_PLAYER = Isaac.GetPlayerTypeByName("BShattered", true)

local SHIFT_INDEX = 35
local items = {}
local game = Game()
local rng = RNG()
local sound = SFXManager()

local shatterNum = 0
local storedIndex = {}
local birthright = false

--Function sets the seed. Called once run starts to prevent 0
function shatteredLib:GetSeed()
    local seed = game:GetSeeds():GetStartSeed()
    rng:SetSeed(seed, SHIFT_INDEX)
end

function shatteredLib:enableBirthright()
    birthright = true
end

--This table stores synergies
function shatteredLib:SetTable()
    items = {
        --Format goes {1st ID num, 2nd ID num, 3rd ID num, number of pickups}, you can add as many as you want in sequence
        --D6
        [105] = {
            5, 300, 49, 3
        },
        --Diplopia
        [347] = {
            5, 300, 33, 2
        },
        --Magic Skin
        [642] = {
            5, 300, 62, 2
        },
        --Blank Card
        [286] = {
            5, 300, 48, 3
        },
        --Red Key
        [580] = {
            5, 300, 78, 6
        },
        --D20
        [166] = {
            5, 300, 49, 3
        },
        --The Clicker
        [482] = {
            5, 300, (rng:RandomInt(17) + 81), 1, 5, 300, (rng:RandomInt(17) + 81), 1
        },
        --Midas' Touch
        [202] = {
            5, 20, 1, rng:RandomInt(20) + 1
        }
    }
end

--Table used for matching IDs to their unlock trinket
local unlockMatch = {
    --Key is "variant".."subtype", stores achievment ID for unlock
    --Gold Heart
    ["107"] = {4},
    --Half Soul Heart
    ["108"] = {33},
    --Scared Heart
    ["109"] = {328},
    --Bone Heart
    ["1011"] = {391},
    --Rotten Heart
    ["1012"] = {441},
    --Lucky Penny
    ["205"] = {242},
    --Sticky Nickel
    ["206"] = {240},
    --Golden Penny
    ["207"] = {613},
    --Golden Bomb
    ["404"] = {226},
    --Charged Key
    ["304"] = {333}
}

--Blacklisted items. Don't want troll bombs spawning, that's lame and what red chests are for
local blackList = {
    --Troll Bomb--
    ["403"] = {},
    --Mega Troll Bomb--
    ["405"] = {},
    --Golden Troll Bomb--
    ["406"] = {}
}

--Table used for managing pickup RNG
local pickupsGen = {
    --Variant, max ID
    --Hearts
    [1] = {
        10, 12
    },
    --Coins
    [2] = {
        20, 7
    },
    --Bombs
    [3] = {
        40, 7
    },
    --Keys
    [4] = {
        30, 4
    },
    --Pills
    [5] = {
        70, 13
    },
    --Cards/Runes
    [6] = {
        300, 97
    }
}

--This function basically tanslates the synergy table for the main function :)
function shatteredLib:CountTable(num)
    local count = 1
    local loop = true
    while loop
    do
        if items[num][count] == nil then
            return count - 1
        else
            count = count + 1
        end
    end
end

--Function Generates a random pickup from the defined tables
function shatteredLib:SpawnRandomPickup(entity)
    local genIndex
    local variant
    local subType
    local reroll = true

    --Keeps going until it generates a pickup that has been unlocked
    while reroll == true
    do
        genIndex = (rng:RandomInt(6) + 1)
        variant = pickupsGen[genIndex][1]
        subType = rng:RandomInt((pickupsGen[genIndex][2])) + 1
        local concatID = tostring(variant)..tostring(subType)

        --Manage what can/can't spawn. Check unlocks, make rarer items less likely, etc.
        if variant == 300 then
            reroll = not Isaac.GetItemConfig():GetCard(subType):IsAvailable()
        elseif unlockMatch[concatID] then
            reroll = not Isaac.GetPersistentGameData():Unlocked(unlockMatch[concatID][1])
            Isaac.ConsoleOutput(tostring(reroll).." for "..concatID.." ")
        else
            reroll = false
        end

        --Check if item is blacklisted
        if blackList[concatID] then
            reroll = true
        end
    end
    Isaac.Spawn(5, variant, subType, entity.Position, Vector(math.random(-6, 6), math.random(-6, 6)), entity)
end

--Function for shattering
function shatteredLib:Shatter(entity, success, char)
    local optionIndex = entity:ToPickup().OptionsPickupIndex
    local id = entity.SubType
    local indexed = false
    local valA = 1
    local valB = 2
    local valC = 3
    local valD = 4

    --If birthright is enabled, disable the optionIndex check. This is the birthright effect
    if (birthright) and (char == SHATTERED_PLAYER) then
        optionIndex = 0
    end

    --Check to see if optionindex has been picked
    if optionIndex ~= 0 then
        for _, num in pairs(storedIndex) do
            if num == optionIndex then
                indexed = true
            end
        end
    end

    --If it's an option item, and one of the options has already been picked, or if it is an empty pedestal, just delete and don't do anything else
    if indexed or (entity.SubType == 0) then
        entity:Remove()
    else
        --Check if the subtype is in the table, not a shop item, and is a pedestal
        if items[entity.SubType] and (entity:ToPickup():IsShopItem() == false) and (entity.Variant == 100) then
            local spawnPos = entity.Position

            --Check how many items are defined in the table, and repeat for each of them
            for k = 1, (shatteredLib:CountTable(id)/4), 1 do
                for i = 1, items[id][valD], 1
                do
                    --Check the clicker spawns are unlocked. Bail to randompickup if not
                    if (entity.SubType == 482) and (not Isaac.GetItemConfig():GetCard(items[482][valC]):IsAvailable()) then
                        shatteredLib:SpawnRandomPickup(entity)
                    else
                        Isaac.Spawn(items[id][valA], items[id][valB], items[id][valC], spawnPos, Vector(math.random(-6, 6), math.random(-6, 6)), entity)
                    end
                end
                valA = valA + 4
                valB = valB + 4
                valC = valC + 4
                valD = valD + 4
            end

            if optionIndex ~= 0 then
                table.insert(storedIndex, optionIndex)
            end

            success = true
            shatterNum = shatterNum + 1
            entity:Remove()
        elseif (entity:ToPickup():IsShopItem() == false) and not (Isaac.GetItemConfig():GetCollectible(entity.SubType):HasTags(ItemConfig.TAG_QUEST)) then
            local quality = Isaac.GetItemConfig():GetCollectible(id).Quality
            local totalPickups

            totalPickups = 2 + quality
                
            for i = 1, totalPickups, 1
            do
                shatteredLib:SpawnRandomPickup(entity)
            end

            success = true
            shatterNum = shatterNum + 1
            entity:Remove() 

            if optionIndex ~= 0 then
                table.insert(storedIndex, optionIndex)
            end
        end
    end
    return success
end

--Function for when the active item is used
function shatteredLib:ShatteredDiceUse(item, rngObj, player, useFlags)
    local char = player:GetPlayerType()
    local roomItems = Isaac.FindByType(5, 100)
    local success = false
    storedIndex = {}

    --Says nuh-uh if functions is being used by carbattery or a non-owned source (looking at you, found soul)
    if (useFlags & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY) or not (useFlags & UseFlag.USE_OWNED == UseFlag.USE_OWNED) then
        return
    end

    --Repeats code for each item found in room
    for _, entity in ipairs(roomItems)
    do  
        success = shatteredLib:Shatter(entity, success, char)
    end

    if success then
        sound:Play(610)
    end

    return success
end

return shatteredLib