local LockerConfig = require 'config.shared'
local Framework = {}
Framework.Type =  LockerConfig.Framework or 'qbx'

if Framework.Type == 'qbx' then
    Framework.GetPlayer = function(src)
        return exports.qbx_core:GetPlayer(src)
    end
    Framework.GetMoney = function(src, acc) return exports.qbx_core:GetMoney(src, acc) end
    Framework.RemoveMoney = function(src, acc, amt, reason) exports.qbx_core:RemoveMoney(src, acc, amt, reason) end
    Framework.AddMoney = function(src, acc, amt, reason) exports.qbx_core:AddMoney(src, acc, amt, reason) end
    Framework.GetPlayerByCitizenId = function(cid) return exports.qbx_core:GetPlayerByCitizenId(cid) end
elseif Framework.Type == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
    Framework.GetPlayer = function(src) return QBCore.Functions.GetPlayer(src) end
    Framework.GetMoney = function(src, acc)
        local Player = QBCore.Functions.GetPlayer(src)
        if acc == 'bank' then return Player.PlayerData.money['bank'] end
        if acc == 'cash' then return Player.PlayerData.money['cash'] end
        return 0
    end
    Framework.RemoveMoney = function(src, acc, amt, reason)
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.RemoveMoney(acc, amt, reason)
    end
    Framework.AddMoney = function(src, acc, amt, reason)
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.AddMoney(acc, amt, reason)
    end
    Framework.GetPlayerByCitizenId = function(cid)
        for _, src in pairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(src)
            if Player.PlayerData.citizenid == cid then return Player end
        end
        return nil
    end
end

return Framework
