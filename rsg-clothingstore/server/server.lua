local RSGCore = exports['rsg-core']:GetCoreObject()

-- ==========================================
-- ROUTING BUCKETS
-- ==========================================
RegisterNetEvent('rsg-clothingstore:server:setPrivateBucket', function(playerId)
    local src = source
    local bucket = 1000 + src
    SetPlayerRoutingBucket(src, bucket)
    print('[RSG-ClothingStore] Player ' .. src .. ' moved to bucket ' .. bucket)
end)

RegisterNetEvent('rsg-clothingstore:server:setNormalBucket', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
    print('[RSG-ClothingStore] Player ' .. src .. ' returned to bucket 0')
end)

-- ==========================================
-- Basic clothing
-- ==========================================
local categoryLabels = {
    ['hats'] = 'hats',
    ['shirts_full'] = 'shirts',
    ['pants'] = 'pants',
    ['boots'] = 'boots',
    ['vests'] = 'vests',
    ['coats'] = 'coats',
    ['coats_closed'] = 'closed coats',
    ['gloves'] = 'gloves',
    ['neckwear'] = 'neckwear items',
    ['masks'] = 'masks',
    ['eyewear'] = 'eyewear',
    ['gunbelts'] = 'gunbelts',
    ['satchels'] = 'satchels',
    ['skirts'] = 'skirts',
    ['chaps'] = 'chaps',
    ['spurs'] = 'spurs',
    ['suspenders'] = 'suspenders',
    ['belts'] = 'belts',
    ['cloaks'] = 'cloaks',
    ['ponchos'] = 'ponchos',
    ['gauntlets'] = 'gauntlets',
    ['neckties'] = 'neckties',
    ['dresses'] = 'dresses',
    ['loadouts'] = 'loadouts',
    ['holsters_left'] = 'left holsters',
    ['holsters_right'] = 'right holsters',
    ['belt_buckles'] = 'belt buckles',
    ['accessories'] = 'accessories',
    ['badges'] = 'badges',
    ['corsets'] = 'corsets',
    ['rings_rh'] = 'rings (right hand)',
    ['rings_lh'] = 'rings (left hand)',
    ['bracelets'] = 'bracelets',
    ['necklaces'] = 'necklaces',
    ['jewelry_rings_right'] = 'jewelry rings (right hand)',
    ['jewelry_rings_left'] = 'jewelry rings (left hand)',
    ['jewelry_bracelets'] = 'jewelry bracelets',
    ['boot_accessories'] = 'boot accessories in any style',
    ['earrings'] = 'earrings',
    ['talisman_belt'] = 'talisman on the belt',
    ['body_shape_mp_waist'] = 'body: waist/hip (MP)',
    ['body_shape_mp_torso'] = 'body: torso (MP)',
    ['body_shape_p0_waist'] = 'body: waist (player_zero)',
    ['body_bodies_lower'] = 'body: lower (BODIES_LOWER)',
    ['body_bodies_upper'] = 'body: upper (BODIES_UPPER)',
}

-- ==========================================
-- Custom options (for each character type)
-- ==========================================
local function CreateClothingItemInfo(category, item, isMale, durability)
    durability = durability or 100
    local label = categoryLabels[category] or category
    
    -- ? Classic - hash value
    -- ? Ped - specific character settings (Draw, alb, norm, mat)
    local hash = 0
    local isClassic = item.Kaf == "Classic"
    local isBodyComponent = item.Kaf == "BodyComponent"
    
    if isClassic or isBodyComponent then
        if type(item.Hash) == "string" then
            hash = tonumber(item.Hash, 16) or 0
        else
            hash = item.Hash or 0
        end
    else
        -- ? Ped specific hash for Draw
        if item.Draw and item.Draw ~= "" and item.Draw ~= "_" then
            hash = GetHashKey(item.Draw)
        end
    end
    
    -- Palette and tints
    local palette = item.pal or 'tint_generic_clean'
    if palette == " " or palette == "" then
        palette = 'tint_generic_clean'
    end
    
    local tints = {
        tonumber(item.palette1) or 0,
        tonumber(item.palette2) or 0,
        tonumber(item.palette3) or 0
    }
    
    -- Switch: manage how shaders work with interactions between players
    return {
        -- Basic Model
        _c = category,
        _h = hash,
        _m = 0,
        _t = 1,
        _g = isMale,
        _e = true,
        _d = durability,
        _q = math.floor(durability),
        _p = palette,
        _tints = tints,
        
        -- Precise Model
        category = category,
        hash = hash,
        model = 0,
        texture = 1,
        isMale = isMale,
        equipped = true,
        durability = durability,
        quality = math.floor(durability),
        palette = palette,
        tints = tints,
        
        -- Adjusted Appearance
        label = item.name,
        description = item.name,
        
        -- In specific cases, handle elements (combined with rsg-appearance)
        _kaf = isBodyComponent and "BodyComponent" or (isClassic and "Classic" or "Ped"),
        _draw = item.Draw or "",
        _alb = item.alb or "",
        _norm = item.norm or "",
        _mat = item.mat or 0,
        
        -- Etc on character-specific
        kaf = isBodyComponent and "BodyComponent" or (isClassic and "Classic" or "Ped"),
        draw = item.Draw or "",
        albedo = item.alb or "",
        normal = item.norm or "",
        material = item.mat or 0,
    }
end

-- ==========================================
-- Indicator changes based on context and player characters (shiw-government)
-- ==========================================
local StoreToCityMapping = {
    ['blackwater'] = 'blackwater',
    ['rhodes'] = 'saintdenis',
    ['sd'] = 'saintdenis',
}

-- ==========================================
-- Custom options
-- ==========================================
RegisterNetEvent('rsg-clothingstore:server:buyItem', function(item, storeId, isMale)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    if not item then return end
    
    local price = item.price or 0
    local playerMoney = Player.PlayerData.money.cash or 0
    
    if playerMoney < price then
        TriggerClientEvent('rsg-clothingstore:client:purchaseFailed', src, 'purchase failed message')
        return
    end

    local category = item.category or 'accessories'
    local itemName = Config.CategoryToItem[category] or 'clothing_accessories'
    -- In message CanAddItem - set true or false for checking item; make sure to AddItem
    local success = Player.Functions.RemoveMoney('cash', price, 'clothing-purchase')
    
    if not success then
        TriggerClientEvent('rsg-clothingstore:client:purchaseFailed', src, 'not enough money')
        return
    end
    
    -- Additional info about possible purchases
    local info = CreateClothingItemInfo(category, item, isMale, 100)
    
    print('[RSG-ClothingStore] Creating item with:')
    print('  category: ' .. tostring(category))
    print('  kaf: ' .. tostring(info._kaf))
    print('  hash: ' .. tostring(info._h))
    print('  draw: ' .. tostring(info._draw))
    print('  alb: ' .. tostring(info._alb))
    
    -- Standard options
    local added = Player.Functions.AddItem(itemName, 1, nil, info)
    
    if not added then
        Player.Functions.AddMoney('cash', price, 'clothing-refund')
        TriggerClientEvent('rsg-clothingstore:client:purchaseFailed', src, 'item is already in inventory')
        return
    end
    
    -- Interface to manage options
    TriggerClientEvent('rsg-core:client:inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'add', 1)
    
    local newMoney = Player.PlayerData.money.cash
    TriggerClientEvent('rsg-clothingstore:client:purchaseSuccess', src, item, newMoney)
    
    -- For each character type (shiw-government)
    local cityId = StoreToCityMapping[storeId]
    if cityId then
        local pName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        TriggerEvent('shiw-government:server:shopPurchase', 'clothing-' .. storeId, price, Player.PlayerData.citizenid, pName, cityId)
    end
    
    print(string.format('[RSG-ClothingStore] %s bought %s (%s) for $%.2f', 
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        item.name,
        itemName,
        price
    ))
end)

-- ==========================================
-- CALLBACK
-- ==========================================
RSGCore.Functions.CreateCallback('rsg-clothingstore:server:getPlayerMoney', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player then
        cb(Player.PlayerData.money.cash or 0)
    else
        cb(0)
    end
end)
