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
    CJ.AddOrUpdateJobs()

    CJ.ScriptLoaded = true
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

CJ.AddOrUpdateJobs = function()
    for jobName, jobData in pairs(CJ.Jobs) do
        MySQL.Async.fetchAll('SELECT * FROM `jobs` WHERE `name` = @jobName', {
            ['@jobName'] = jobName
        }, function(jobResult)
            if (jobResult == nil or #jobResult <= 0) then
                MySQL.Async.execute('INSERT INTO `jobs` (`name`, `label`, `whitelisted`) VALUES (@jobName, @jobLabel, @jobWhitelisted)', {
                    ['@jobName'] = jobData.Job,
                    ['@jobLabel'] = jobData.JobName,
                    ['@jobWhitelisted'] = jobData.Whitelisted
                }, function(rowsChanged)
                end)
            end
        end)

        MySQL.Async.fetchAll('SELECT * FROM `datastore` WHERE `name` = @jobName', {
            ['@jobName'] = 'society_' .. jobName
        }, function(datastoreResult)
            if (datastoreResult == nil or #datastoreResult <= 0) then
                MySQL.Async.execute('INSERT INTO `datastore` (`name`, `label`, `shared`) VALUES (@jobName, @jobLabel, @jobShared)', {
                    ['@jobName'] = 'society_' .. jobData.Job,
                    ['@jobLabel'] = jobData.JobName,
                    ['@jobShared'] = jobData.Whitelisted
                }, function(rowsChanged)
                end)
            end
        end)

        MySQL.Async.fetchAll('SELECT * FROM `addon_account` WHERE `name` = @jobName or `name` LIKE @jobLike', {
            ['@jobName'] = 'society_' .. jobName,
            ['@jobLike'] = '%society_' .. jobName .. '%'
        }, function(addonAccountResult)
            local alreadyAddedAddonAccounts = {}

            if (addonAccountResult == nil or #addonAccountResult <= 0) then
                alreadyAddedAddonAccounts = {}
            elseif (addonAccountResult ~= nil or #addonAccountResult < 4) then
                for _, addonAccount in pairs(addonAccountResult) do
                    table.insert(alreadyAddedAddonAccounts, addonAccount.name)
                end
            end

            if (not CJ.TableContains(alreadyAddedAddonAccounts, 'society_' .. jobData.Job, true)) then
                MySQL.Async.execute('INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES (@jobName, @jobLabel, @jobShared)', {
                    ['@jobName'] = 'society_' .. jobData.Job,
                    ['@jobLabel'] = jobData.JobName,
                    ['@jobShared'] = jobData.Whitelisted
                }, function(rowsChanged)
                end)
            end

            if (not CJ.TableContains(alreadyAddedAddonAccounts, 'society_' .. jobData.Job .. '_dirty_money', true)) then
                MySQL.Async.execute('INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES (@jobName, @jobLabel, @jobShared)', {
                    ['@jobName'] = 'society_' .. jobData.Job .. '_dirty_money',
                    ['@jobLabel'] = jobData.JobName .. ' ' .. _U('dirty_money'),
                    ['@jobShared'] = jobData.Whitelisted
                }, function(rowsChanged)
                end)
            end

            if (not CJ.TableContains(alreadyAddedAddonAccounts, 'society_' .. jobData.Job .. '_money_wash', true)) then
                MySQL.Async.execute('INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES (@jobName, @jobLabel, @jobShared)', {
                    ['@jobName'] = 'society_' .. jobData.Job .. '_money_wash',
                    ['@jobLabel'] = jobData.JobName .. ' ' .. _U('money_wash'),
                    ['@jobShared'] = jobData.Whitelisted
                }, function(rowsChanged)
                end)
            end

            if (not CJ.TableContains(alreadyAddedAddonAccounts, 'society_' .. jobData.Job .. '_money_washed', true)) then
                MySQL.Async.execute('INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES (@jobName, @jobLabel, @jobShared)', {
                    ['@jobName'] = 'society_' .. jobData.Job .. '_money_washed',
                    ['@jobLabel'] = jobData.JobName .. ' ' .. _U('money_washed'),
                    ['@jobShared'] = jobData.Whitelisted
                }, function(rowsChanged)
                end)
            end
        end)

        MySQL.Async.fetchAll('SELECT * FROM `addon_account_data` WHERE `account_name` = @jobName or `account_name` LIKE @jobLike', {
            ['@jobName'] = 'society_' .. jobName,
            ['@jobLike'] = '%society_' .. jobName .. '%'
        }, function(addonAccountDataResult)
            local alreadyAddedAddonAccounts = {}

            if (addonAccountDataResult == nil or #addonAccountDataResult <= 0) then
                alreadyAddedAddonAccounts = {}
            elseif (addonAccountDataResult ~= nil or #addonAccountDataResult < 4) then
                for _, addonAccount in pairs(addonAccountDataResult) do
                    table.insert(alreadyAddedAddonAccounts, addonAccount.account_name)
                end
            end

            if (not CJ.TableContains(alreadyAddedAddonAccounts, 'society_' .. jobData.Job, true)) then
                MySQL.Async.execute('INSERT INTO `addon_account_data` (`account_name`, `money`, `owner`) VALUES (@jobName, 0, NULL)', {
                    ['@jobName'] = 'society_' .. jobData.Job,
                }, function(rowsChanged)
                end)
            end

            if (not CJ.TableContains(alreadyAddedAddonAccounts, 'society_' .. jobData.Job .. '_dirty_money', true)) then
                MySQL.Async.execute('INSERT INTO `addon_account_data` (`account_name`, `money`, `owner`) VALUES (@jobName, 0, NULL)', {
                    ['@jobName'] = 'society_' .. jobData.Job .. '_dirty_money',
                }, function(rowsChanged)
                end)
            end

            if (not CJ.TableContains(alreadyAddedAddonAccounts, 'society_' .. jobData.Job .. '_money_wash', true)) then
                MySQL.Async.execute('INSERT INTO `addon_account_data` (`account_name`, `money`, `owner`) VALUES (@jobName, 0, NULL)', {
                    ['@jobName'] = 'society_' .. jobData.Job .. '_money_wash',
                }, function(rowsChanged)
                end)
            end

            if (not CJ.TableContains(alreadyAddedAddonAccounts, 'society_' .. jobData.Job .. '_money_washed', true)) then
                MySQL.Async.execute('INSERT INTO `addon_account_data` (`account_name`, `money`, `owner`) VALUES (@jobName, 0, NULL)', {
                    ['@jobName'] = 'society_' .. jobData.Job .. '_money_washed',
                }, function(rowsChanged)
                end)
            end
        end)

        MySQL.Async.fetchAll('SELECT * FROM `addon_inventory` WHERE `name` = @jobName', {
            ['@jobName'] = 'society_' .. jobName
        }, function(addonInventoryResult)
            if (addonInventoryResult == nil or #addonInventoryResult <= 0) then
                MySQL.Async.execute('INSERT INTO `addon_inventory` (`name`, `label`, `shared`) VALUES (@jobName, @jobLabel, @jobShared)', {
                    ['@jobName'] = 'society_' .. jobData.Job,
                    ['@jobLabel'] = jobData.JobName,
                    ['@jobShared'] = jobData.Whitelisted
                }, function(rowsChanged)
                end)
            end
        end)

        MySQL.Async.execute('DELETE FROM `job_grades` WHERE `job_name` = @jobName', {
            ['@jobName'] = jobName
        }, function(rowsChanged)
            for _, jobGrade in pairs(CJ.Jobs[jobName].Grades or {}) do
                local grade = jobGrade.Grade or 0
                local name = jobGrade.Name or 'unkown'
                local label = jobGrade.Label or 'Unkown'
                local salary = jobGrade.Salary or 500

                MySQL.Async.execute('INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES (@jobName, @jobGrade, @gradeName, @gradeLabel, @gradeSalary, \'{}\', \'{}\')', {
                    ['@jobName'] = jobData.Job,
                    ['@jobGrade'] = grade,
                    ['@gradeName'] = name,
                    ['@gradeLabel'] = label,
                    ['@gradeSalary'] = salary
                }, function(rowsChanged)
                    if (CJ.ESX ~= nil and CJ.ESX.Jobs[jobName] == nil) then
                        CJ.ESX.Jobs[jobName] = {
                            name = jobData.Job,
                            label = jobData.JobName,
                            whitelisted = jobData.Whitelisted
                        }
            
                        CJ.ESX.Jobs[jobName].grades = {}
                    end

                    CJ.ESX.Jobs[jobName].grades[tostring(grade)] = {
                        job_name = jobName,
                        grade = grade,
                        name = name,
                        label = label,
                        salary = salary,
                        skin_male = '{}',
                        skin_female = '{}'
                    }
                end)
            end
        end)
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

CJ.ESX.RegisterServerCallback('esx_customjobs:getJobs', function(source, cb)
    local jobs = CJ.Jobs or {}
    local jobNames = {}

    for jobName, jobData in pairs(jobs) do
        table.insert(jobNames, jobName)
    end

    cb(jobNames)
end)

CJ.ESX.RegisterServerCallback('esx_customjobs:getJobData', function(source, cb)
    local xPlayer = CJ.ESX.GetPlayerFromId(source)

    if (xPlayer == nil) then
        cb({})
        return
    end

    local playerJob = xPlayer.job or {
        name = 'unkown',
        grade = 0
    }

    local result = {}

    if (CJ.Jobs ~= nil and CJ.Jobs[playerJob.name] ~= nil) then
        result.name = CJ.Jobs[playerJob.name].JobName or 'Unkown'
        result.job = CJ.Jobs[playerJob.name].Job or 'unkown'
        result.positions = CJ.Jobs[playerJob.name].Positions or {}
    end

    if (CJ.JobGradesAllowed ~= nil and CJ.JobGradesAllowed[playerJob.name] ~= nil and
        CJ.JobGradesAllowed[playerJob.name][tostring(playerJob.grade)] ~= nil) then
        result.allowed = CJ.JobGradesAllowed[playerJob.name][tostring(playerJob.grade)] or {}
    end

    cb(result)
end)