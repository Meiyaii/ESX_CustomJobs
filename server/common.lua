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

CJ.GetCurrentJob = function(source)
    local xPlayer = CJ.ESX.GetPlayerFromId(source)
    local currentJob = xPlayer.job or {}
    local currentJobName = currentJob.name or 'unkown'

    for jobName, jobData in pairs(CJ.Jobs) do
        if (string.lower(jobName) == string.lower(currentJobName)) then
            return jobName
        end
    end

    return false
end

CJ.GetCurrentLabel = function(source)
    local xPlayer = CJ.ESX.GetPlayerFromId(source)
    local currentJob = xPlayer.job or {}
    local currentJobName = currentJob.name or 'unkown'

    for jobName, jobData in pairs(CJ.Jobs) do
        if (string.lower(jobName) == string.lower(currentJobName)) then
            return jobData.JobName
        end
    end

    return false
end

CJ.GetCurrentJobWebhooks = function(source)
    local currentJob = CJ.GetCurrentJob(source)

    if (not currentJob) then
        return {}
    end

    if (CJ.Jobs ~= nil and CJ.Jobs[currentJob] ~= nil) then
        return CJ.Jobs[currentJob].Wehbooks or {}
    end

    return {}
end

CJ.LogToDiscord = function(source, title, message, msgType, color)
    color = color or Config.Colors.Grey

    local jobLabel = CJ.GetCurrentLabel(source)
    local webhooks = CJ.GetCurrentJobWebhooks(source)
    local webhook = ''

    if (string.lower(msgType) == 'actions') then
        webhook = webhooks.Actions or ''
    elseif (string.lower(msgType) == 'safe') then
        webhook = webhooks.Safe or ''
    elseif (string.lower(msgType) == 'money') then
        webhook = webhooks.Money or ''
    elseif (string.lower(msgType) == 'employee') then
        webhook = webhooks.Employee or ''
    end

    if (webhook == nil or webhook == '') then
        return
    end

    local discordInfo = {
        ["color"] = color,
        ["type"] = "rich",
        ["title"] = title,
        ["description"] = message,
        ["footer"] = {
            ["text"] = jobLabel .. ' | ' .. CJ.GetSteamIdentifier(source) .. ' | ' .. CJ.GetCurrentTime()
        }
    }

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({ username = jobLabel .. ' | Logs | ' .. CJ.Version, embeds = { discordInfo } }), { ['Content-Type'] = 'application/json' })
end

CJ.GetSteamIdentifier = function(source)
    if (source == nil) then
        return ''
    end

    local playerId = tonumber(source)

    if (playerId <= 0) then
        return ''
    end

    local identifiers, steamIdentifier = GetPlayerIdentifiers(source)

    for _, identifier in pairs(identifiers) do
        if (string.match(string.lower(identifier), 'steam:')) then
            steamIdentifier = identifier
        end
    end

    return steamIdentifier
end

CJ.GetCurrentTime = function()
    local date_table = os.date("*t")
	local hour, minute, second = date_table.hour, date_table.min, date_table.sec
	local year, month, day = date_table.year, date_table.month, date_table.day

    if (string.lower(Config.Locale) == 'nl') then
        return string.format("%d-%d-%d %d:%d:%d", day, month, year, hour, minute, second)
    end

    return string.format("%d-%d-%d %d:%d:%d", year, month, day, hour, minute, second)
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