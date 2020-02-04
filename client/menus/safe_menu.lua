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
end

CJ.OpenRemoveItemMenu = function()
end

CJ.OpenBuyItemMenu = function()
end