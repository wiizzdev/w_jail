ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local TempsJail = {}
local PlayerDead = {}

RegisterNetEvent('jail:combiendetemps')
AddEventHandler('jail:combiendetemps', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * FROM `w_jail` WHERE `identifier` = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] then
            if not TempsJail[xPlayer.source] then
                TempsJail[xPlayer.source] = {}
                TempsJail[xPlayer.source].time = result[1].time
                TempsJail[xPlayer.source].reason = result[1].raison
                TempsJail[xPlayer.source].staffname = result[1].staffname
                TriggerClientEvent('jail:encoredutemps', xPlayer.source, TempsJail[xPlayer.source].time)
                for k,v in pairs(Config.Position["entrée"]) do
                    SetEntityCoords(GetPlayerPed(xPlayer.source), v.x, v.y, v.z)
                end
                TriggerClientEvent('esx:showNotification', xPlayer.source, "~r~Vous vous êtes déconnecté en étant en jail")
                TriggerClientEvent('jail:openmenu', xPlayer.source, TempsJail[xPlayer.source].time, TempsJail[xPlayer.source].reason, TempsJail[xPlayer.source].staffname)
            end
        else
            TempsJail[xPlayer.source] = {}
            TempsJail[xPlayer.source].time = 0
        end
    end)
end)

RegisterNetEvent('jail:mettretempsajour')
AddEventHandler('jail:mettretempsajour', function(NewTempsJail)
    local xPlayer = ESX.GetPlayerFromId(source)
    TempsJail[xPlayer.source].time = NewTempsJail
    if tonumber(TempsJail[xPlayer.source].time) == 0 then
        TempsJail[xPlayer.source].time = 0
        TriggerClientEvent("esx:showNotification", source, "Votre sanction est maintenant terminé")
        MySQL.Async.execute('DELETE FROM w_jail WHERE `identifier` = @identifier', {
            ['@identifier'] = xPlayer.identifier
        })
		for k,v in pairs(Config.Position["sortie"]) do
        	SetEntityCoords(GetPlayerPed(xPlayer.source), v.x, v.y, v.z)
		end
    end
end)

RegisterCommand('jail', function(source,args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= 'user' then
        local JoueurTarget = ESX.GetPlayerFromId(args[1])
        if JoueurTarget then
            Wait(100)
            if tonumber(TempsJail[JoueurTarget.source].time) >= 1 then
                TriggerClientEvent('esx:showNotification', source, "Le joueur est déjà en jail pendant: ~b~"..TempsJail[JoueurTarget.source].time.." ~s~minutes")
            else
                local reason = table.concat(args, ' ', 3)
                TempsJail[JoueurTarget.source].time = args[2]
                TempsJail[JoueurTarget.source].reason = reason
                TempsJail[JoueurTarget.source].staffname = xPlayer.getName()
                TriggerClientEvent('jail:encoredutemps', JoueurTarget.source, TempsJail[JoueurTarget.source].time)
                for k,v in pairs(Config.Position["entrée"]) do
                    SetEntityCoords(GetPlayerPed(JoueurTarget.source), v.x, v.y, v.z)
                end
                if args[2] == tostring("1") then 
                    TriggerClientEvent('esx:showNotification', source, "Vous avez jail ~b~"..GetPlayerName(JoueurTarget.source).." ~s~pendant ~b~"..args[2].." ~s~minute")
                    TriggerClientEvent('esx:showNotification', JoueurTarget.source, "Vous avez été mit en jail pendant ~b~"..args[2].." ~s~minute")
                else
                    TriggerClientEvent('esx:showNotification', source, "Vous avez jail ~b~"..GetPlayerName(JoueurTarget.source).." ~s~pendant ~b~"..args[2].." ~s~minutes")
                    TriggerClientEvent('esx:showNotification', JoueurTarget.source, "Vous avez été mit en jail pendant ~b~"..args[2].." ~s~minutes")
                end
                TriggerClientEvent('jail:openmenu', JoueurTarget.source, nil,  TempsJail[JoueurTarget.source].reason, TempsJail[JoueurTarget.source].staffname)
            end
        else
            TriggerClientEvent('esx:showNotification', source, "Aucun joueur trouvé avec l'ID que vous avez entré")
        end
    end
end)

RegisterCommand('unjail', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= 'user' then
        local JoueurTarget = ESX.GetPlayerFromId(args[1])
        if JoueurTarget then
            Wait(100)
            if tonumber(TempsJail[JoueurTarget.source].time) >= 0 then
                TempsJail[JoueurTarget.source].time = 0
                TriggerClientEvent('esx:showNotification', source, "Le joueur ~b~"..GetPlayerName(xPlayer.source).." ~s~a été unjail")
                TriggerClientEvent('jail:encoredutemps', JoueurTarget.source, 0)
                for k,v in pairs(Config.Position["sortie"]) do
                    SetEntityCoords(GetPlayerPed(JoueurTarget.source), v.x, v.y, v.z)
                end
                MySQL.Async.execute('DELETE FROM w_jail WHERE `identifier` = @identifier', {
                    ['@identifier'] = JoueurTarget.identifier
                })
            else
                TriggerClientEvent('esx:showNotification', source, "Le joueur ~b~"..GetPlayerName(JoueurTarget.source).." ~s~n'est pas en jail")
            end
        else
            TriggerClientEvent('esx:showNotification', source, "Aucun joueur trouvé avec l'ID que vous avez entré")
        end
    end
end)

RegisterCommand('jailoffline', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local reason = table.concat(args, " ", 3)
    if xPlayer.getGroup() ~= 'user' then
        MySQL.Async.execute("INSERT INTO w_jail (identifier, time, raison, staffname) VALUES (@identifier, @time, @raison, @staffname)", {
            ["@identifier"] = args[1], 
            ["@time"] = args[2],
            ["@raison"] = reason, 
            ["@staffname"] = xPlayer.getName()
        })
    end
end)

AddEventHandler('playerDropped', function(reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if tonumber(TempsJail[xPlayer.source].time) > 0 then 
        raisondujail = TempsJail[xPlayer.source].reason
        nomdustaff = TempsJail[xPlayer.source].staffname    
    end
    if (xPlayer) then
        if TempsJail[xPlayer.source] then
            local TimeJail = tonumber(TempsJail[xPlayer.source].time)
            if tonumber(TimeJail) >= 1 then
                MySQL.Async.fetchAll('SELECT * FROM `w_jail` WHERE `identifier` = @identifier', {
                    ['@identifier'] = xPlayer.identifier
                }, function(result)
                    if result[1] then
                        MySQL.Async.execute('UPDATE w_jail SET time = @time WHERE identifier = @identifier',{
                            ['@identifier'] = xPlayer.identifier,
                            ['@time'] = TimeJail,
                        })
                    else
                        MySQL.Async.execute('INSERT INTO w_jail (identifier, time, raison, staffname) VALUES (@identifier, @time, @raison, @staffname)', {
                            ['@identifier'] = xPlayer.identifier,
                            ['@time'] = TimeJail,
                            ["@raison"] = raisondujail,
                            ["@staffname"] = nomdustaff
                        }, function()
                        end)
                    end
                end)
                TempsJail[xPlayer.source] = nil
            end
        end
        if PlayerDead[source] then 
            MySQL.Async.execute('INSERT INTO w_jail (identifier, time, raison, staffname) VALUES (@identifier, @time, @raison, @staffname)', {
                ['@identifier'] = xPlayer.identifier,
                ['@time'] = 10,
                ["@raison"] = "Déco Mort",
                ["@staffname"] = "Anti Déco Mort"
            })
        end
    end
end)
