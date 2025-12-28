local LockerConfig = require 'config.shared'
local activeLockers = {}

local Framework = {}
Framework.Type = LockerConfig.Framework or 'qbx'

if Framework.Type == 'qbx' then
    Framework.PlayerData = function()
        return QBX.PlayerData
    end
elseif Framework.Type == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
    Framework.PlayerData = function()
        local Player = QBCore.Functions.GetPlayerData()
        return Player
    end
elseif Framework.Type == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
    Framework.PlayerData = function()
        return ESX.GetPlayerData()
    end
end

return Framework