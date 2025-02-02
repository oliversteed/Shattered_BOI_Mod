local taintedLib = {}

local sd6 = require("shattered_src.shattered_dice")
local sound = SFXManager()
local game = Game()
local sprite = Sprite()

local shatterSwitch = false



local healthCost = {
    --Heart container, soul heart--
    [-1] = {1},
    [-2] = {2},
    [-3] = {3},
    [-4] = {3}
}

--!!!Below isn't working!!!--
sprite:Load("gfx/tainted_ui.anm2", true)

function taintedLib:RenderUI()
    if shatterSwitch == false then
        sprite:Play("ShatterTrue")
        sprite:Render(Vector(122, 13))
        sprite:Update()
    else
        sprite:Play("ShatterFalse")
        sprite:Render(Vector(122, 13))
        sprite:Update()
    end

end

--Below function currently doesn't properly work with active items. Needs a check to prevent it from running immediately after picking an item up--

function taintedLib:TaintedShatter(entity, collider)
    local success = nil

    if (entity.Variant == 100) and (collider.Type == 1) then
        local player = collider:ToPlayer()

        if entity.SubType == 0 then
            return nil
        end

        if not player:IsExtraAnimationFinished() then
            return nil
        end

        if shatterSwitch == true then

            if entity:IsShopItem() then
                local cost = entity.Price
                if cost > 0 then
                    local coins = player:GetNumCoins()
                    if coins >= cost then
                        player:AddCoins(-cost)
                        entity.Price = 0
                    else
                        return nil
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
                    entity.Price = 0
                    game:AddDevilRoomDeal()
                end
            end

            local indexNum = 0

            --Set option index if it isn't 0 before the item is shattered and removed from the room--
            if entity.OptionsPickupIndex ~= 0 then
                indexNum = entity.OptionsPickupIndex
            end

            sd6:Shatter(entity, success, player)
            sound:Play(610)
            shatterSwitch = false

            --Cleanup any items that had an options index--
            if indexNum ~= 0 then
                local roomItems = Isaac.FindByType(5, 100)
                for _, item in ipairs(roomItems) do
                    local thisIndex = item:ToPickup().OptionsPickupIndex
                    if thisIndex == indexNum then
                        item:Remove()
                    end
                end
            end

            return false
        else
            if entity:IsShopItem() then
                local coins = player:GetNumCoins()
                local cost = entity.Price
                if coins < cost then
                    return nil
                end
            end
            shatterSwitch = true
            return nil
        end
    else
        return nil
    end
end

return taintedLib