CJ.RemoveFromTable = function (items, str, ignoreCase)
    items = items or {}
    ignoreCase = ignoreCase or false

    if (string.lower(type(items)) ~= 'table' or #items <= 0) then
        return
    end

    if (ignoreCase) then
        ignoreCase = true
    else
        ignoreCase = false
    end

    for _, item in pairs(items) do
        if (ignoreCase and string.lower(tostring(item)) == string.lower(tostring(str))) then
            table.remove(items, _)
            return
        elseif (tostring(item) == tostring(str)) then
            table.remove(items, _)
            return
        end
    end
end

CJ.TableContains = function (items, str, ignoreCase)
    items = items or {}
    ignoreCase = ignoreCase or false

    if (string.lower(type(items)) ~= 'table' or #items <= 0) then
        return false
    end

    if (ignoreCase) then
        ignoreCase = true
    else
        ignoreCase = false
    end

    for _, item in pairs(items) do
        if (ignoreCase and string.lower(tostring(item)) == string.lower(tostring(str))) then
            return true
        elseif (tostring(item) == tostring(str)) then
            return true
        end
    end

    return false
end

CJ.Round = function(value, decimal)
    if (decimal) then
		return math.floor( (value * 10 ^ decimal) + 0.5) / (10 ^ decimal)
	else
		return math.floor(value + 0.5)
	end
end

-- Given a numeric value formats output with comma to separate thousands and rounded to given decimal places
CJ.NumberToString = function(value, decimal, prefix, negativePrefix)
    local formatted, famount, remain

    decimal = decimal or 2
    negativePrefix = negativePrefix or '-'

    famount = math.abs(CJ.Round(value, decimal))
	famount = math.floor(famount)

	remain = CJ.Round(math.abs(value) - famount, decimal)

	formatted = CJ.CommaValue(famount)

	if (decimal > 0) then
		remain = string.sub(tostring(remain), 3)
		formatted = formatted .. "#" .. remain ..
            string.rep("0", decimal - string.len(remain))
	end

	formatted = (prefix or "") .. formatted

	if (value < 0) then
		if (negativePrefix == "()") then
		    formatted = "("..formatted ..")"
		else
		    formatted = negativePrefix .. formatted
		end
	end

	formatted = string.gsub(formatted, ',', '.')

	return string.gsub(formatted, '#', ',')
	end

    function CJ.Round(num)

	return tonumber(string.format("%.0f", num))
end

-- Formats a number to currancy
CJ.NumberToCurrancy = function(value)
    return CJ.NumberToString(value, 0, Config.Currency .. ' ', '-')
end

-- Formats a number to currancy
CJ.NumberToFormattedString = function(value)
    return CJ.NumberToString(value, 0, '', '-')
end

-- Formats a value to the right comma value
CJ.CommaValue = function(value)
    local formatted = value

    while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')

        if (k == 0) then
		    break
		end
	end

    return formatted
end