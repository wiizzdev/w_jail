Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(100)
	end
end)

local mainMenu = RageUI.CreateMenu("", "Vous êtes en Jail")
local JailTime = 0
local open = false

mainMenu.Closable = false
mainMenu.Closed = function() open = false end

RegisterNetEvent('jail:openmenu')
AddEventHandler('jail:openmenu', function(time, raison, staffname)
    if not open then open = true RageUI.Visible(mainMenu, true) 
        Citizen.CreateThread(function()
            TriggerEvent('skinchanger:getSkin', function(skin)
				if skin.sex == 0 then
					TriggerEvent('skinchanger:loadClothes', skin, Config.Tenue.male)
				else
					TriggerEvent('skinchanger:loadClothes', skin, Config.Tenue.female)
				end
			end)
            while open do
                RageUI.IsVisible(mainMenu, function()
                    if JailTime == tostring("1") then
                        RageUI.Button("Temps restant: ~y~"..ESX.Math.Round(JailTime).." minute", nil, {}, true, {})
                    else
                        RageUI.Button("Temps restant: ~y~"..ESX.Math.Round(JailTime).." minutes", nil, {}, true, {})
                    end
                    if raison ~= nil then 
                        RageUI.Button("Raison: ~o~"..raison.."", nil, {}, true, {})
                    else
                        RageUI.Button("Raison: ~o~Indéfinie", nil, {}, true, {})
                    end
                    if staffname ~= nil then 
                        RageUI.Button("Nom du staff: ~g~"..staffname, nil, {}, true, {})
                    else
                        RageUI.Button("→ CONSOLE", nil, {}, true, {})
                    end
                end)
            Wait(0)
            end
        end)
    end
end)

Citizen.CreateThread(function()
    Wait(2500)
    TriggerServerEvent('jail:combiendetemps')
    while true do
        if tonumber(JailTime) >= 1 then
            Wait(60000)
            JailTime = JailTime - 1
            TriggerServerEvent('jail:mettretempsajour', JailTime)
        end
        if tonumber(JailTime) == 0 then
            ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
				TriggerEvent('skinchanger:loadSkin', skin)
			end)
            RageUI.CloseAll()
            open = false
        end
        Wait(2500)
    end
end)

Citizen.CreateThread(function()
    while true do
        if tonumber(JailTime) >= 1 then
            for k,v in pairs(Config.Position["entrée"]) do
                if #(GetEntityCoords(GetPlayerPed(-1)) - vector3(v.x, v.y, v.z)) > 50 then
                    SetEntityCoords(GetPlayerPed(-1), v.x, v.y, v.z)
                    ESX.ShowNotification("~r~Vous ne pouvez pas vous échapper !")
                end
            end
            Wait(0)
        else
            Wait(2500)
        end
    end
end)

Citizen.CreateThread(function()
	for k,v in pairs(Config.Position["sortie"]) do
        if Config.Blip.Activer then
            local blip = AddBlipForCoord(v.x, v.y, v.z) 
            SetBlipSprite(blip, Config.Blip.Sprite)
            SetBlipDisplay(blip, 4) 
            SetBlipScale(blip, Config.Blip.Scale)
            SetBlipColour(blip, Config.Blip.Colour)
            SetBlipAsShortRange(blip, true) 
            BeginTextCommandSetBlipName('STRING') 
            AddTextComponentSubstringPlayerName(Config.Blip.Name)
            EndTextCommandSetBlipName(blip) 
        end
	end
end)

Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/jail', 'id, temps, raison')
    TriggerEvent('chat:addSuggestion', '/jailoffline', 'license, temps, raison')
    TriggerEvent('chat:addSuggestion', '/unjail', 'id')
end)

RegisterNetEvent('jail:requestRequetteJailTime')
AddEventHandler('jail:requestRequetteJailTime', function(result)
    JailTime = result
    if JailTime == 0 then
        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('skinchanger:loadSkin', skin)
        end)
        RageUI.CloseAll()
        open = false
    end 
end)