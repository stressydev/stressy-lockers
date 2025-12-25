local LockerConfig = require 'config.shared'
local rentedLockers = {}

-- ============================================
-- DATABASE (runtime creation)
-- ============================================
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS stressy_lockers (
            locker_key VARCHAR(50) PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            location INT NOT NULL,
            locker_id INT NOT NULL,
            price INT NOT NULL
        )
    ]])

    Wait(500)

    local rows = MySQL.query.await('SELECT * FROM stressy_lockers')

    for _, row in ipairs(rows) do
        rentedLockers[row.locker_key] = {
            owner = row.citizenid,
            price = row.price
        }

        exports.ox_inventory:RegisterStash(
            row.locker_key,
            'Locker #' .. row.locker_id,
            LockerConfig.MaxSlots,
            LockerConfig.MaxWeight,
            row.citizenid
        )
    end

    print(('[stressy_lockers] Loaded %s lockers'):format(#rows))
end)

-- ============================================
-- CALLBACK: FETCH LOCKERS (FOR MENU)
-- ============================================
lib.callback.register('stressy-lockers:getLockers', function(source)
    return rentedLockers
end)

-- ============================================
-- RENT LOCKER
-- ============================================
lib.callback.register('stressy-lockers:rentLocker', function(src, location, lockerId, price)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return false end

    local key = location .. '_' .. lockerId

    if rentedLockers[key] then
        return false
    end

    if exports.qbx_core:GetMoney(src, 'bank') < price then
        return false
    end

    exports.qbx_core:RemoveMoney(src, 'bank', price, 'locker-rent')

    MySQL.insert.await(
        'INSERT INTO stressy_lockers (locker_key, citizenid, location, locker_id, price) VALUES (?, ?, ?, ?, ?)',
        { key, Player.PlayerData.citizenid, location, lockerId, price }
    )

    rentedLockers[key] = {
        owner = Player.PlayerData.citizenid,
        price = price
    }

    exports.ox_inventory:RegisterStash(
        key,
        'Locker #' .. lockerId,
        LockerConfig.MaxSlots,
        LockerConfig.MaxWeight,
        Player.PlayerData.citizenid
    )

    TriggerClientEvent('stressy-lockers:syncLockers', -1, rentedLockers)
    return true
end)

-- ============================================
-- UNRENT LOCKER
-- ============================================
lib.callback.register('stressy-lockers:unrentLocker', function(src, lockerKey)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return false end

    local data = rentedLockers[lockerKey]
    if not data or data.owner ~= Player.PlayerData.citizenid then
        return false
    end

    -- Optional: refund 100% of price
    local refundAmount = data.price
    exports.qbx_core:AddMoney(src, 'bank', refundAmount, 'locker-unrent')

    -- Remove locker from DB and memory
    rentedLockers[lockerKey] = nil
    MySQL.query.await('DELETE FROM stressy_lockers WHERE locker_key = ?', { lockerKey })

    -- Sync all clients
    TriggerClientEvent('stressy-lockers:syncLockers', -1, rentedLockers)

    return true
end)


-- ============================================
-- OPEN STASH
-- ============================================
RegisterNetEvent('stressy-lockers:openStash', function(lockerName,lockerId,key)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    if rentedLockers[key] and rentedLockers[key].owner == Player.PlayerData.citizenid then
        local stashId = (lockerName..'_stash_%s'):format(lockerId)
        local label = lockerName.. ' #' .. lockerId .. ' Storage'
        if not exports.ox_inventory:GetInventory(stashId) then
            exports.ox_inventory:RegisterStash(stashId, label or 'Warehouse Storage', LockerConfig.MaxSlots, LockerConfig.MaxWeight, false)
        end
        TriggerClientEvent('ox_inventory:openInventory', src, 'stash', { id = stashId })
    end
end)

-- ============================================
-- SYNC ON JOIN (QBX EVENT)
-- ============================================
AddEventHandler('QBX:Server:OnPlayerLoaded', function(player)
    TriggerClientEvent('stressy-lockers:syncLockers', player.source, rentedLockers)
end)

-- ============================================
-- CRON BILLING
-- ============================================
lib.cron.new(LockerConfig.BillingCron, function()
    for key, data in pairs(rentedLockers) do
        local Player = exports.qbx_core:GetPlayerByCitizenId(data.owner)

        if Player then
            if exports.qbx_core:GetMoney(Player.PlayerData.source, 'bank') >= data.price then
                exports.qbx_core:RemoveMoney(
                    Player.PlayerData.source,
                    'bank',
                    data.price,
                    'locker-rent'
                )
            else
                -- revoke locker
                rentedLockers[key] = nil
                MySQL.delete.await(
                    'DELETE FROM stressy_lockers WHERE locker_key = ?',
                    { key }
                )

                TriggerClientEvent(
                    'ox_lib:notify',
                    Player.PlayerData.source,
                    {
                        title = 'Rental Lockers',
                        description = 'Locker revoked due to unpaid rent',
                        type = 'error'
                    }
                )
            end
        end
    end

    TriggerClientEvent('stressy-lockers:syncLockers', -1, rentedLockers)
end)
