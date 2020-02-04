CJ                  = {}
CJ.Jobs             = {}
CJ.JobsAllowed      = {}
CJ.JobGradesAllowed = {}
CJ.Version          = '0.0.0'
CJ.ESX              = nil
CJ.ScriptLoaded     = false

TriggerEvent('mlx:getSharedObject', function(obj) CJ.ESX = obj end)

Citizen.CreateThread(function()
    Citizen.Wait(0)

    while CJ.ESX == nil do
        Citizen.Wait(0)
    end

    if (not CJ.ScriptLoaded) then
        CJ.Initialize()
    end
end)

CJ.Initialize = function()
    if (CJ.ScriptLoaded) then
        return
    end

    CJ.LoadCurrentVersion()
    CJ.LoadCustomJobs()
    CJ.LoadAllowedJobPermissions()
    CJ.LoadAllowedJobGradePermissions()

    for jobName, jobData in pairs(CJ.JobGradesAllowed) do
        for jobGrade, jobGradeData in pairs(jobData) do
            for _, permission in pairs(jobGradeData) do
                print(jobName .. ' > ' .. jobGrade .. ' > ' .. permission)
            end
        end
    end
end

CJ.LoadCustomJobs = function()
    local jobsContent = LoadResourceFile(GetCurrentResourceName(), 'data/jobs.json')

    if (not jobsContent) then
        return
    end

    local jobs = json.decode(jobsContent)

    if (not jobs) then
        return
    end

    for _, job in pairs(jobs) do
        local currentJobContent = LoadResourceFile(GetCurrentResourceName(), 'data/jobs/' .. job .. '.json')

        if (not currentJobContent) then
            print(_U('failed_to_load_job'))
        else
            local currentJob = json.decode(currentJobContent)

            if (not currentJob) then
                print(_U('failed_to_load_job'))
            else
                local jobName = currentJob.Job or nil

                if (jobName ~= nil) then
                    CJ.Jobs[jobName] = currentJob
                end
            end
        end
    end
end

CJ.LoadAllowedJobPermissions = function()
    for jobName, jobData in pairs(CJ.Jobs) do
        local allowed = jobData.Allowed or {}
        local jobPermissions = {}

        for _, permission in pairs(allowed) do
            if (permission ~= nil and string.lower(permission) == 'safe.item.*') then
                table.insert(jobPermissions, 'safe.item.add')
                table.insert(jobPermissions, 'safe.item.remove')
                table.insert(jobPermissions, 'safe.item.buy')
            elseif (permission ~= nil and string.lower(permission) == 'safe.weapon.*') then
                table.insert(jobPermissions, 'safe.weapon.add')
                table.insert(jobPermissions, 'safe.weapon.remove')
                table.insert(jobPermissions, 'safe.weapon.buy')
            elseif (permission ~= nil and string.lower(permission) == 'safe.dirtymoney.*') then
                table.insert(jobPermissions, 'safe.dirtymoney.add')
                table.insert(jobPermissions, 'safe.dirtymoney.remove')
            elseif(permission ~= nil) then
                table.insert(jobPermissions, string.lower(permission))
            end
        end

        if (CJ.JobsAllowed == nil) then
            CJ.JobsAllowed = {}
        end

        CJ.JobsAllowed[jobName] = jobPermissions
    end
end

CJ.LoadAllowedJobGradePermissions = function()
    if (CJ.JobGradesAllowed == nil) then
        CJ.JobGradesAllowed = {}
    end

    for jobName, jobData in pairs(CJ.Jobs) do
        if (CJ.JobGradesAllowed[jobName] == nil) then
            CJ.JobGradesAllowed[jobName] = {}
        end

        local grades = jobData.Grades or {}
        local jobPermissions = CJ.JobsAllowed[jobName] or {}

        for _, grade in pairs(grades) do
            local gradeNumber = tostring(grade.Grade or 0)

            CJ.JobGradesAllowed[jobName][gradeNumber] = {}

            for _, jobPermission in pairs(jobPermissions) do
                table.insert(CJ.JobGradesAllowed[jobName][gradeNumber], jobPermission)
            end

            local deniedPermissions = grade.Denied or {}

            for _, deniedPermission in pairs(deniedPermissions) do
                if (deniedPermission ~= nil and string.lower(deniedPermission) == 'safe.item.*') then
                    CJ.RemoveFromTable(CJ.JobGradesAllowed[jobName][gradeNumber], 'safe.item.add', true)
                    CJ.RemoveFromTable(CJ.JobGradesAllowed[jobName][gradeNumber], 'safe.item.remove', true)
                    CJ.RemoveFromTable(CJ.JobGradesAllowed[jobName][gradeNumber], 'safe.item.buy', true)
                elseif (deniedPermission ~= nil and string.lower(deniedPermission) == 'safe.weapon.*') then
                    CJ.RemoveFromTable(CJ.JobGradesAllowed[jobName][gradeNumber], 'safe.weapon.add', true)
                    CJ.RemoveFromTable(CJ.JobGradesAllowed[jobName][gradeNumber], 'safe.weapon.remove', true)
                    CJ.RemoveFromTable(CJ.JobGradesAllowed[jobName][gradeNumber], 'safe.weapon.buy', true)
                elseif (deniedPermission ~= nil and string.lower(deniedPermission) == 'safe.dirtymoney.*') then
                    CJ.RemoveFromTable(CJ.JobGradesAllowed[jobName][gradeNumber], 'safe.dirtymoney.add', true)
                    CJ.RemoveFromTable(CJ.JobGradesAllowed[jobName][gradeNumber], 'safe.dirtymoney.remove', true)
                elseif(deniedPermission ~= nil) then
                    CJ.RemoveFromTable(CJ.JobGradesAllowed[jobName][gradeNumber], deniedPermission, true)
                end
            end
        end
    end
end

CJ.PlayerHasPermission = function(source, permission)
    local xPlayer = CJ.ESX.GetPlayerFromId(source)

    if (xPlayer == nil) then
        return false
    end

    local playerJob = xPlayer.job or {
        name = 'unkown',
        grade = 0
    }

    if (CJ.JobGradesAllowed == nil or CJ.JobGradesAllowed[playerJob.name] == nil or
        CJ.JobGradesAllowed[playerJob.name][tostring(playerJob.grade)]) then
        return false
    end

    return CJ.TableContains(CJ.JobGradesAllowed[playerJob.name][tostring(playerJob.grade)], permission, true)
end

CJ.LoadCurrentVersion = function()
    local currentVersion = LoadResourceFile(GetCurrentResourceName(), 'version')

    if (not currentVersion) then
        CJ.Version = '0.0.0'
    else
        CJ.Version = currentVersion
    end
end