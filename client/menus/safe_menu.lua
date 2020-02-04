CJ.OpenSafeMenu = function()
    local elements = {}

    if (CJ.PlayerHasPermission('safe.item.add')) then
        table.insert(elements, { label = _U('add_items'), value = 'item.add' })
    end

    if (CJ.PlayerHasPermission('safe.item.remove')) then
        table.insert(elements, { label = _U('remove_items'), value = 'item.remove' })
    end

    if (CJ.PlayerHasPermission('safe.item.buy')) then
        table.insert(elements, { label = _U('buy_items'), value = 'item.buy' })
    end

    CJ.ESX.UI.Menu.Open(
        'default',
        GetCurrentResourceName(),
        'safe_menu',
        {
            title       = _U('safe_menu'),
            align       = 'top-left',
            css         = CJ.GetCurrentJob(),
            elements    = elements
        },
        function(data, menu)
            if (CJ.PlayerHasPermission('safe.item.add') and string.lower(data.current.value) == 'item.add') then
                CJ.OpenAddItemMenu()
            elseif (CJ.PlayerHasPermission('safe.item.remove') and string.lower(data.current.value) == 'item.remove') then
                CJ.OpenRemoveItemMenu()
            elseif (CJ.PlayerHasPermission('safe.item.buy') and string.lower(data.current.value) == 'item.buy') then
                CJ.OpenBuyItemMenu()
            end
        end,
        function(data, menu)
            menu.close()
        end)
end

CJ.OpenAddItemMenu = function()
    CJ.ESX.TriggerServerCallback('esx_customjobs:getItemInventory', function(data)
        local elements = {}

        if (#data.items > 0) then
            table.insert(elements, { label = _U('products'), value = '', disabled = true })

            for _, item in pairs(data.items) do
                if (item.count > 0) then
                    local productLabel = '<strong>' .. item.label .. '</strong> ' .. item.count

                    table.insert(elements, { label = productLabel, value = item.name })
                end
            end
        end

        if (data.dirtyMoney > 0) then
            table.insert(elements, { label = _U('black_money_label'), value = '', disabled = true })
            table.insert(elements, { label = _U('black_money', CJ.NumberToString(data.dirtyMoney, 0, '€ ')), value = 'black_money' })
        end

        CJ.ESX.UI.Menu.Open(
            'default',
            GetCurrentResourceName(),
            'add_item',
            {
                title       = _U('add_items'),
                align       = 'top-left',
                css         = CJ.GetCurrentJob(),
                elements    = elements
            },
            function(data, menu)
                if (CJ.PlayerHasPermission('safe.item.add')) then
                    CJ.ESX.UI.Menu.Open(
                        'dialog',
                        GetCurrentResourceName(),
                        'add_item_amount',
                        {
                            title       = _U('item_count'),
                            submit      = _U('add'),
                            css         = CJ.GetCurrentJob(),
                        },
                        function(data2, menu2)
                            CJ.ESX.TriggerServerCallback('esx_customjobs:storeItem', function(done, msg)
                                if (done) then
                                    menu2.close()
                                    menu.close()

                                    if (data.current.value == 'black_money') then
                                        ESX.ShowNotification(_U('put_black_money', CJ.NumberToString(data2.value, 0, '€ '), msg, CJ.GetCurrentJobLabel()))
                                    else
                                        ESX.ShowNotification(_U('put_products', CJ.NumberToString(data2.value, 0, ''), msg, CJ.GetCurrentJobLabel()))
                                    end

                                    CJ.OpenAddItemMenu()
                                end
                            end, data.current.value, data2.value)
                        end
                    )
                end
            end,
            function(data, menu)
                menu.close()
            end)
    end)
end

CJ.OpenRemoveItemMenu = function()
end

CJ.OpenBuyItemMenu = function()
end