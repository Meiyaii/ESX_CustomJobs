CJ.ESX.RegisterServerCallback('esx_customjobs:getItemInventory', function(source, cb)
    local xPlayer = CJ.ESX.GetPlayerFromId(source)

    if (xPlayer == nil) then
        cb({
            dirtyMoney = 0,
            items = {},
        })
        return
    end

    local dirtyMoney = 0
    local dirtyMoneyAccount = (xPlayer.getAccount('black_money') or 0)

    if (dirtyMoneyAccount ~= 0) then
        dirtyMoney = dirtyMoneyAccount.money
    end

    cb({
        dirtyMoney = dirtyMoney,
        items = xPlayer.inventory
    })
end)

CJ.ESX.RegisterServerCallback('esx_customjobs:storeItem', function(source, cb, itemName, count)
    count = tonumber(count) or 0

    local xPlayer = CJ.ESX.GetPlayerFromId(source)
    local currentJob = CJ.GetCurrentJob(source)
    local currentLabel = CJ.GetCurrentLabel(source)

    if (xPlayer == nil and cb ~= nil) then
        cb(false, 'none')
        return
    end

    if (not currentJob) then
        cb(false, 'none')
        return
    end

    if (itemName == 'black_money') then
        TriggerEvent('mlx_addonaccount:getSharedAccount', 'society_' .. currentJob .. '_black_money', function(account)
            local blackMoneyAccount = nil

            for _, _account in pairs(xPlayer.accounts) do
                if (_account.name == 'black_money') then
                    blackMoneyAccount = _account
                end
            end

            if (blackMoneyAccount == nil) then
                cb(false, 'none')
                return
            end

            if (blackMoneyAccount.money < count or count <= 0) then
                cb(false, 'no_black_money')
                return
            end

            xPlayer.removeAccountMoney('black_money', count)
            blackMoneyAccount.addMoney(count)

            CJ.LogToDiscord(source,
                _U('discord_add_item', currentLabel),
                _U('discord_add_item_desc', CJ.NumberToString(count, 0, '€ '), _U('dirty_money')),
                'safe',
                Config.Colors.Green)

            cb(true, _U('blackmoney'))
            return
        end)
    end

    TriggerEvent('mlx_addoninventory:getSharedInventory', 'society_' .. currentJob, function(inventory)
        local item = inventory.getItem(itemName)
        local playerItem = xPlayer.getInventoryItem(itemName)

        if (item == nil or playerItem == nil or playerItem.count < count) then
            cb(false, 'no_item')
            return
        end

        if (not playerItem.canRemove) then
            cb(false, 'cant_remove_item')
            return
        end

        xPlayer.removeInventoryItem(playerItem.name, count)
        inventory.addItem(item.name, count)

        CJ.LogToDiscord(source,
            _U('discord_add_item', currentLabel),
            _U('discord_add_item_desc', count, playerItem.label),
            'safe',
            Config.Colors.Green)

        cb(true, playerItem.label)
        return
    end)
end)