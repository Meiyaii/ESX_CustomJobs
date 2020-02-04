CJ                  = {}
CJ.ESX              = nil
CJ.Jobs             = {}
CJ.JobsLoaded       = false
CJ.CurrentJobData   = {}

Citizen.CreateThread(function()
    while CJ.ESX == nil do
        TriggerEvent('mlx:getSharedObject', function(obj) CJ.ESX = obj end)
        Citizen.Wait(0)
    end

    while CJ.ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
    end

    CJ.ESX.PlayerData = CJ.ESX.GetPlayerData()

    local currentJobName = CJ.ESX.PlayerData.job.name or 'unkown'

    while not CJ.JobsLoaded do
        CJ.JobsLoaded = true

        CJ.ESX.TriggerServerCallback('esx_customjobs:getJobs', function(jobs)
            CJ.Jobs = jobs

            if (CJ.TableContains(CJ.Jobs, currentJobName, true)) then
                CJ.ESX.TriggerServerCallback('esx_customjobs:getJobData', function(currentJobData)
                    CJ.CurrentJobData = currentJobData
                    CJ.CurrentJobData.loaded = true
                end)
            else
                CJ.CurrentJobData = {}
                CJ.CurrentJobData.loaded = false
            end
        end)

        Citizen.Wait(500)
    end

    Citizen.Wait(0)
end)

CJ.PlayerHasPermission = function(permission)
    local currentJobData = CJ.CurrentJobData or {}
    local currentAllowed = currentJobData.allowed or {}

    return CJ.TableContains(currentAllowed, permission, true)
end

CJ.PlayerHasAnyPermission = function(permissions)
    permissions = permissions or {}

    if (string.lower(type(permissions)) ~= 'table' or #permissions <= 0) then
        return false
    end

    local allowed = false

    for _, permission in pairs(permissions) do
        if (CJ.PlayerHasPermission(permission)) then
            allowed = true
        end
    end

    return allowed
end

RegisterNetEvent('mlx:playerLoaded')
AddEventHandler('mlx:playerLoaded', function(xPlayer)
    CJ.ESX.PlayerData = xPlayer

    CJ.ESX.TriggerServerCallback('esx_customjobs:getJobs', function(jobs)
        CJ.Jobs = jobs
    end)

    local currentPlayerJob = CJ.ESX.PlayerData.job or {}
    local currentJobName = currentPlayerJob.name or 'unkown'

    if (CJ.TableContains(CJ.Jobs, currentJobName, true)) then
        CJ.ESX.TriggerServerCallback('esx_customjobs:getJobData', function(currentJobData)
            CJ.CurrentJobData = currentJobData
            CJ.CurrentJobData.loaded = true
        end)
    else
        CJ.CurrentJobData = {}
        CJ.CurrentJobData.loaded = false
    end
end)

RegisterNetEvent('mlx:setJob')
AddEventHandler('mlx:setJob', function(job)
    CJ.ESX.PlayerData.job = job

    local currentPlayerJob = CJ.ESX.PlayerData.job or {}
    local currentJobName = currentPlayerJob.name or 'unkown'

    if (CJ.TableContains(CJ.Jobs, currentJobName, true)) then
        CJ.ESX.TriggerServerCallback('esx_customjobs:getJobData', function(currentJobData)
            CJ.CurrentJobData = currentJobData
            CJ.CurrentJobData.loaded = true
        end)
    else
        CJ.CurrentJobData = {}
        CJ.CurrentJobData.loaded = false
    end
end)

CJ.Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}