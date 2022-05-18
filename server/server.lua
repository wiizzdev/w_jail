ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local JailTime = {}
local PlayerDead = {}

RegisterNetEvent('jail:combiendetemps')
AddEventHandler('jail:combiendetemps', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * FROM `w_jail` WHERE `identifier` = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] then
            if not JailTime[xPlayer.source] then
                JailTime[xPlayer.source] = {}
                JailTime[xPlayer.source].time = result[1].time
                JailTime[xPlayer.source].reason = result[1].raison
                JailTime[xPlayer.source].staffname = result[1].staffname
                TriggerClientEvent('jail:requestRequetteJailTime', xPlayer.source, JailTime[xPlayer.source].time)
                for k,v in pairs(Config.Position["entrée"]) do
                    SetEntityCoords(GetPlayerPed(xPlayer.source), v.x, v.y, v.z)
                end
                TriggerClientEvent('esx:showNotification', xPlayer.source, "~r~Vous vous êtes déconnecté en étant en jail")
                TriggerClientEvent('jail:openmenu', xPlayer.source, JailTime[xPlayer.source].time, JailTime[xPlayer.source].reason, JailTime[xPlayer.source].staffname)
            end
        else
            JailTime[xPlayer.source] = {}
            JailTime[xPlayer.source].time = 0
        end
    end)
end)

RegisterNetEvent('jail:mettretempsajour')
AddEventHandler('jail:mettretempsajour', function(NewJailTime)
    local xPlayer = ESX.GetPlayerFromId(source)
    JailTime[xPlayer.source].time = NewJailTime
    if tonumber(JailTime[xPlayer.source].time) == 0 then
        JailTime[xPlayer.source].time = 0
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
        local TargetPlayer = ESX.GetPlayerFromId(args[1])
        if TargetPlayer then
            Wait(100)
            if tonumber(JailTime[TargetPlayer.source].time) >= 1 then
                TriggerClientEvent('esx:showNotification', source, "Le joueur est déjà en jail pendant: ~b~"..JailTime[TargetPlayer.source].time.." ~s~minutes")
            else
                local reason = table.concat(args, ' ', 3)
                JailTime[TargetPlayer.source].time = args[2]
                JailTime[TargetPlayer.source].reason = reason
                JailTime[TargetPlayer.source].staffname = xPlayer.getName()
                TriggerClientEvent('jail:requestRequetteJailTime', TargetPlayer.source, JailTime[TargetPlayer.source].time)
                for k,v in pairs(Config.Position["entrée"]) do
                    SetEntityCoords(GetPlayerPed(TargetPlayer.source), v.x, v.y, v.z)
                end
                if args[2] == tostring("1") then 
                    TriggerClientEvent('esx:showNotification', source, "Vous avez jail ~b~"..GetPlayerName(TargetPlayer.source).." ~s~pendant ~b~"..args[2].." ~s~minute")
                    TriggerClientEvent('esx:showNotification', TargetPlayer.source, "Vous avez été mit en jail pendant ~b~"..args[2].." ~s~minute")
                else
                    TriggerClientEvent('esx:showNotification', source, "Vous avez jail ~b~"..GetPlayerName(TargetPlayer.source).." ~s~pendant ~b~"..args[2].." ~s~minutes")
                    TriggerClientEvent('esx:showNotification', TargetPlayer.source, "Vous avez été mit en jail pendant ~b~"..args[2].." ~s~minutes")
                end
                TriggerClientEvent('jail:openmenu', TargetPlayer.source, nil,  JailTime[TargetPlayer.source].reason, JailTime[TargetPlayer.source].staffname)
            end
        else
            TriggerClientEvent('esx:showNotification', source, "Aucun joueur trouvé avec l'ID que vous avez entré")
        end
    end
end)

RegisterCommand('unjail', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= 'user' then
        local TargetPlayer = ESX.GetPlayerFromId(args[1])
        if TargetPlayer then
            Wait(100)
            if tonumber(JailTime[TargetPlayer.source].time) >= 0 then
                JailTime[TargetPlayer.source].time = 0
                TriggerClientEvent('esx:showNotification', source, "Le joueur ~b~"..GetPlayerName(xPlayer.source).." ~s~à été unjail")
                TriggerClientEvent('jail:requestRequetteJailTime', TargetPlayer.source, 0)
                for k,v in pairs(Config.Position["sortie"]) do
                    SetEntityCoords(GetPlayerPed(TargetPlayer.source), v.x, v.y, v.z)
                end
                MySQL.Async.execute('DELETE FROM w_jail WHERE `identifier` = @identifier', {
                    ['@identifier'] = TargetPlayer.identifier
                })
            else
                TriggerClientEvent('esx:showNotification', source, "Le joueur ~b~"..GetPlayerName(TargetPlayer.source).." ~s~n'est pas en jail")
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
    if tonumber(JailTime[xPlayer.source].time) > 0 then 
        reasontobdd = JailTime[xPlayer.source].reason
        staffnametobb = JailTime[xPlayer.source].staffname    
    end
    if (xPlayer) then
        if JailTime[xPlayer.source] then
            local TimeJail = tonumber(JailTime[xPlayer.source].time)
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
                            ["@raison"] = reasontobdd,
                            ["@staffname"] = staffnametobb
                        }, function()
                        end)
                    end
                end)
                JailTime[xPlayer.source] = nil
            end
        end
        if PlayerDead[source] then 
            MySQL.Async.execute('INSERT INTO w_jail (identifier, time, raison, staffname) VALUES (@identifier, @time, @raison, @staffname)', {
                ['@identifier'] = xPlayer.identifier,
                ['@time'] = 10,
                ["@raison"] = "Déco mort",
                ["@staffname"] = "Anti Déco Mort"
            })
        end
    end
end)