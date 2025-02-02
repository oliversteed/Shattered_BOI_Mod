local characterLib = {}

local shatteredDice = require("shattered_src.shattered_dice")

local SHATTERED_PLAYER = Isaac.GetPlayerTypeByName("Shattered", false)
local SHATTERED_DICE = Isaac.GetItemIdByName("Shattered D6")
local sound = SFXManager()
local game = Game()

local healthCost = {
    --Heart container, soul heart--
    [-1] = {1},
    [-2] = {2},
    [-3] = {3},
    [-4] = {3}
}

--Gives The Shattered the Shattered D6 as run initialises--
function characterLib:AddStartItem(player)
    local type = player:GetPlayerType()

    if type == SHATTERED_PLAYER then
        player:AddCollectible(SHATTERED_DICE, 6, true, ActiveSlot.SLOT_PRIMARY)
        return
    end
end

--Prevent The Shattered from picking up other active items--
function characterLib:PreventPickup(pickup, collider)
    local pickupSubtype = pickup.SubType
    local pickupVar = pickup.Variant
    local entityType = collider.Type
    local pickupType
    local player
    local playerType

    --Bail out if there is an empty item pedestal--
    if pickupSubtype == 0 then
        return nil
    end

    --Set player--
    if (entityType == 1) and (pickupVar == 100) then
        pickupType = Isaac.GetItemConfig():GetCollectible(pickupSubtype).Type
        player = collider:ToPlayer()
        playerType = player:GetPlayerType()
        --Birthright--

        if (playerType == SHATTERED_PLAYER) and (pickupSubtype == 619) then
            shatteredDice:enableBirthright()
        end
    end

    --Allow purchase but not pickup of active items that cost money--
    if pickup:IsShopItem() and (pickupType == 3) and (entityType == 1) and (pickupVar == 100) then
        local cost = pickup.Price
        if cost > 0 then
            local coins = player:GetNumCoins()
            if coins >= cost then
                player:AddCoins(-cost)
                sound:Play(274)
                pickup.Price = 0
            end
        elseif cost < 0 then
            --Pay in Broken Hearts instead of normal health. If at max health, it will take normal heart containers and then bone hearts before eating into soul/black hearts--
            local healthTotal = player:GetBlackHearts() + (player:GetBoneHearts() * 2) + player:GetSoulHearts() + player:GetMaxHearts()
            if (healthTotal == (24 - 2*player:GetBrokenHearts())) and (player:GetMaxHearts() > 0) then
                if ((player:GetMaxHearts()/2) < healthCost[cost][1]) and (player:GetBoneHearts() > 0) then
                    local health = player:GetMaxHearts()/2
                    player:AddMaxHearts(-2*healthCost[cost][1])
                    player:AddBoneHearts(-(healthCost[cost][1] - health))
                else
                    player:AddMaxHearts(-2*healthCost[cost][1])
                end
            elseif (healthTotal == (24 - 2*player:GetBrokenHearts())) and (player:GetBoneHearts() > 0) then
                player:AddBoneHearts(-healthCost[cost][1])
            end
            player:AddBrokenHearts(healthCost[cost][1])
            sound:Play(316)
            pickup.Price = 0
            game:AddDevilRoomDeal()
        end
    end

    local returnVal = nil

    if (pickupVar == 100) and (pickupType == 3) and (entityType == 1) and (playerType == SHATTERED_PLAYER) then
        returnVal = false
    end

    return returnVal
end

return characterLib