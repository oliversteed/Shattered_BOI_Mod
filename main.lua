local SHATTEREDMOD = RegisterMod("Shattered", 1)
local SHATTERED_DICE = Isaac.GetItemIdByName("Shattered D6")
local SHATTERED_PLAYER = Isaac.GetPlayerTypeByName("Shattered", false)
local BSHATTERED_PLAYER = Isaac.GetPlayerTypeByName("BShattered", true)

local shatteredDice = require("shattered_src.shattered_dice")
local shatteredChar = require("shattered_src.shattered_character")
local BShatteredChar = require("shattered_src.BShattered")

local preventPickup = nil
local isBShattered = false

local icons = Sprite()
icons:Load("gfx/EIDIcon.anm2", true)

--EID Descriptions--
if EID then
    EID:addCollectible(SHATTERED_DICE, "Rerolls item pedestals into a random number of pickups proportional to the item's quality. Will reroll into unique, set drops if a synergy exists.")
    EID:addBirthright(SHATTERED_PLAYER, "Using the Shattered D6 will shatter all choice pedestals in the room instead of just 1.")
    EID:addIcon("Player"..SHATTERED_PLAYER, "Shattered", 0, 4, 4, 0, 0, icons)
    EID:addIcon("Player"..BSHATTERED_PLAYER, "BShattered", 0, 4, 4, 0, 0, icons)
end

--Main callback for Shattered D6--
function SHATTEREDMOD:ShatteredDiceUse(item, rngObj, player, useFlags)
    local success = shatteredDice:ShatteredDiceUse(item, rngObj, player, useFlags)
    return{
        Discharge = success,
        Remove = false,
        ShowAnim = true,
    }
end

--Sets the seed. Called on player init--
function SHATTEREDMOD:RunStartSetup(player)

    --Sets RNG seed and synergy table
    shatteredDice:GetSeed()
    shatteredDice:SetTable()

    --Checks character. If the shattered, gives starting item--
    shatteredChar:AddStartItem(player)

    if player:GetPlayerType() == BSHATTERED_PLAYER then
        isBShattered = true
    else
        isBShattered = false
    end
end

--Prevents The Shattered from picking up any active items--
function SHATTEREDMOD:StickyFingers(pickup, collider)

    if (collider.Type == 1) and (collider:ToPlayer():GetPlayerType() == SHATTERED_PLAYER) then
        preventPickup = shatteredChar:PreventPickup(pickup, collider)
        return preventPickup
    elseif (collider.Type == 1) and (collider:ToPlayer():GetPlayerType() == BSHATTERED_PLAYER) then
        local shatter = BShatteredChar:TaintedShatter(pickup, collider)
        return shatter
    end
    return nil
end

function SHATTEREDMOD:UpdateRender()
    if isBShattered then
        BShatteredChar:RenderUI()
    end
end

SHATTEREDMOD:AddCallback(ModCallbacks.MC_USE_ITEM, SHATTEREDMOD.ShatteredDiceUse, SHATTERED_DICE)
SHATTEREDMOD:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SHATTEREDMOD.RunStartSetup)
SHATTEREDMOD:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, SHATTEREDMOD.StickyFingers)
SHATTEREDMOD:AddCallback(ModCallbacks.MC_POST_RENDER, SHATTEREDMOD.UpdateRender)