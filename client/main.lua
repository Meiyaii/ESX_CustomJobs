CJ.CurrentAction    = nil
CJ.LastAction       = nil

Citizen.CreateThread(function()
    while true do
        local currentJobInfo = CJ.CurrentJobData or {}

        if (currentJobInfo.loaded or false) then
            local playerPed = GetPlayerPed(-1)
            local coords = GetEntityCoords(playerPed)
            local circlePositions = currentJobInfo.positions or {}

            -- Markers
            local marker = Config.Marker
            local defaultMarker = marker.Default
            local garageMarker = marker.Garage
            local clothingMarker = marker.Clothing
            local safeMarker = marker.Safe
            local bossMarker = marker.Boss
            local warehouse = marker.Warehouse

            -- Locations
            local itemSafeCircle = circlePositions.ItemSafe or nil
            local weaponSafeCircle = circlePositions.WeaponSafe or nil

            if (itemSafeCircle ~= nil and CJ.PlayerHasAnyPermission({ 'safe.item.add', 'safe.item.remove', 'safe.item.buy' })) then
                if (GetDistanceBetweenCoords(coords, itemSafeCircle.x, itemSafeCircle.y, itemSafeCircle.z, true) < Config.DrawDistance) then
                    DrawMarker(marker.Type, itemSafeCircle.x, itemSafeCircle.y, itemSafeCircle.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, safeMarker.x, safeMarker.y, safeMarker.z, safeMarker.r, safeMarker.g, safeMarker.b, 100, false, true, 2, false, false, false, false)
                end
            end

            if (weaponSafeCircle ~= nil and CJ.PlayerHasAnyPermission({ 'safe.weapon.add', 'safe.weapon.remove', 'safe.weapon.buy' })) then
                if (GetDistanceBetweenCoords(coords, weaponSafeCircle.x, weaponSafeCircle.y, weaponSafeCircle.z, true) < Config.DrawDistance) then
                    DrawMarker(marker.Type, weaponSafeCircle.x, weaponSafeCircle.y, weaponSafeCircle.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, safeMarker.x, safeMarker.y, safeMarker.z, safeMarker.r, safeMarker.g, safeMarker.b, 100, false, true, 2, false, false, false, false)
                end
            end
        end

        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    while true do
        local isInMarker = false
        local currentJobInfo = CJ.CurrentJobData or {}

        if (currentJobInfo.loaded or false) then
            local playerPed = GetPlayerPed(-1)
            local coords = GetEntityCoords(playerPed)
            local circlePositions = currentJobInfo.positions or {}

            -- Markers
            local marker = Config.Marker
            local defaultMarker = marker.Default
            local garageMarker = marker.Garage
            local clothingMarker = marker.Clothing
            local safeMarker = marker.Safe
            local bossMarker = marker.Boss
            local warehouse = marker.Warehouse

            -- Locations
            local itemSafeCircle = circlePositions.ItemSafe or nil
            local weaponSafeCircle = circlePositions.WeaponSafe or nil

            if (itemSafeCircle ~= nil and CJ.PlayerHasAnyPermission({ 'safe.item.add', 'safe.item.remove', 'safe.item.buy' })) then
                if (GetDistanceBetweenCoords(coords, itemSafeCircle.x, itemSafeCircle.y, itemSafeCircle.z, true) < safeMarker.x) then
                    isInMarker = true
                    CJ.CurrentAction = 'esx_customjobs:itemSafe'
                end
            end

            if (weaponSafeCircle ~= nil and CJ.PlayerHasAnyPermission({ 'safe.weapon.add', 'safe.weapon.remove', 'safe.weapon.buy' })) then
                if (GetDistanceBetweenCoords(coords, weaponSafeCircle.x, weaponSafeCircle.y, weaponSafeCircle.z, true) < safeMarker.x) then
                    isInMarker = true
                    CJ.CurrentAction = 'esx_customjobs:weaponSafe'
                end
            end

            if (isInMarker and CJ.LastAction == nil) then
                CJ.HasEnteredMarker()
            end

            if (not isInMarker and CJ.LastAction ~= nil) then
                CJ.HasExitedMarker()
            end
        end

        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local currentJobInfo = CJ.CurrentJobData or {}

        if (currentJobInfo.loaded or false) then
            if (IsControlJustReleased(0, CJ.Keys['E']) and CJ.UserIsMarker()) then
                CJ.LastAction = CJ.CurrentAction
                CJ.CurrentAction = nil

                if (CJ.IsCurrentAction('esx_customjobs:itemSafe') or CJ.IsLastAction('esx_customjobs:itemSafe')) then
                end

                if (CJ.IsCurrentAction('esx_customjobs:weaponSafe') or CJ.IsLastAction('esx_customjobs:weaponSafe')) then
                end

                CJ.CurrentAction = nil
            end
        else
            Citizen.Wait(250)
        end
    end
end)

CJ.HasEnteredMarker = function()
    local currentJobInfo = CJ.CurrentJobData or {}

    if (currentJobInfo.loaded or false) then
        local circlePositions = currentJobInfo.positions or {}

        -- Locations
        local itemSafeCircle = circlePositions.ItemSafe or nil
        local weaponSafeCircle = circlePositions.WeaponSafe or nil

        if (CJ.LastAction == nil) then
            if (itemSafeCircle ~= nil and CJ.PlayerHasAnyPermission({ 'safe.item.add', 'safe.item.remove', 'safe.item.buy' })) then
                if (CJ.IsCurrentAction('esx_customjobs:itemSafe')) then
                    CJ.ESX.ShowHelpNotification(_U('open_itemSafe'))
                end
            end

            if (weaponSafeCircle ~= nil and CJ.PlayerHasAnyPermission({ 'safe.weapon.add', 'safe.weapon.remove', 'safe.weapon.buy' })) then
                if (CJ.IsCurrentAction('esx_customjobs:weaponSafe')) then
                    CJ.ESX.ShowHelpNotification(_U('open_weaponSafe'))
                end
            end
        end
    end
end

CJ.HasExitedMarker = function()
    CJ.ESX.UI.Menu.CloseAll()
    CJ.CurrentAction = nil
    CJ.LastAction = nil
end

CJ.UserIsMarker = function()
    local currentJobInfo = CJ.CurrentJobData or {}

    if (currentJobInfo.loaded or false) then
        local playerPed = GetPlayerPed(-1)
        local coords = GetEntityCoords(playerPed)
        local circlePositions = currentJobInfo.positions or {}

        -- Markers
        local marker = Config.Marker
        local defaultMarker = marker.Default
        local garageMarker = marker.Garage
        local clothingMarker = marker.Clothing
        local safeMarker = marker.Safe
        local bossMarker = marker.Boss
        local warehouse = marker.Warehouse

        -- Locations
        local itemSafeCircle = circlePositions.ItemSafe or nil
        local weaponSafeCircle = circlePositions.WeaponSafe or nil

        if (itemSafeCircle ~= nil and CJ.PlayerHasAnyPermission({ 'safe.item.add', 'safe.item.remove', 'safe.item.buy' })) then
            if (GetDistanceBetweenCoords(coords, itemSafeCircle.x, itemSafeCircle.y, itemSafeCircle.z, true) < safeMarker.x) then
                return true
            end
        end

        if (weaponSafeCircle ~= nil and CJ.PlayerHasAnyPermission({ 'safe.weapon.add', 'safe.weapon.remove', 'safe.weapon.buy' })) then
            if (GetDistanceBetweenCoords(coords, weaponSafeCircle.x, weaponSafeCircle.y, weaponSafeCircle.z, true) < safeMarker.x) then
                return true
            end
        end
    end

    return false
end

CJ.IsCurrentAction = function(action)
    return CJ.CurrentAction ~= nil and string.lower(CJ.CurrentAction) == string.lower(action)
end

CJ.IsLastAction = function(action)
    return CJ.LastAction ~= nil and string.lower(CJ.LastAction) == string.lower(action)
end