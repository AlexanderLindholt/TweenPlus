-- Value functions.
local valueFunctions = require(script.Parent.ValueFunctions)

local normalValueFunctions = valueFunctions.Normal
local advancedValueFunctions = valueFunctions.Advanced

-- Update functions function.
return function(apiMap, instance, values)
	-- Get properties and verify class.
	local classProperties = apiMap[instance.ClassName]
	if not classProperties then error("Could not identify the class of instance '"..instance:GetFullName().."'.", 3) end

	-- Verify values and add update functions for each.
	local updateFunctions, resetFunctions = {}, {}
	
	for valueName, valueDestination in values do
		if type(valueName) ~= "string" then error("Invalid value name of type '"..typeof(valueName).."'. It should be a string.", 3) end
		
		if valueName:sub(1, 1) == "@" then
			-- Attribute.
			local attributeName = valueName:sub(2)
			
			local original = instance:GetAttribute(attributeName)
			if original == nil then error("'"..attributeName.."' is not a valid attribute of '"..instance:GetFullName().."'.", 3) end
			
			local value = normalValueFunctions[typeof(valueDestination)]
			if not value then error("'"..typeof(valueDestination).."'' data type is not supported.", 3) end
			value = value(original, valueDestination)
			
			table.insert(updateFunctions, function(alpha)
				instance:SetAttribute(attributeName, value(alpha))
			end)
			table.insert(resetFunctions, function()
				instance:SetAttribute(attributeName, original)
			end)
		else
			-- Not attribute.
			local value = advancedValueFunctions[valueName]
			if value then
				-- Advanced type.
				if not instance:IsA(value.Target) then error("'"..instance:GetFullName().."'' doesn't support '"..valueName.."'.", 3) end
				
				local original = value.Get(instance)
				local setValue = value.Set(instance, original, valueDestination)
				table.insert(updateFunctions, function(alpha)
					setValue(alpha)
				end)
				table.insert(resetFunctions, function()
					setValue(0)
				end)
			else
				-- Property.
				local property = classProperties[valueName]
				if not property then error("'"..valueName.."' is not a valid property of '"..instance:GetFullName().."'.", 3) end
				
				local valueType = typeof(valueDestination)
				if valueType ~= property.Type then error("'"..valueName.."' is not of correct type '"..property.."'.", 3) end
				
				value = normalValueFunctions[valueType]
				if not value then error("'"..typeof(valueDestination).."' data type is not supported.", 3) end
				
				local original = instance[valueName]
				value = value(original, valueDestination)
				
				table.insert(updateFunctions, function(alpha)
					instance[valueName] = value(alpha)
				end)
				table.insert(resetFunctions, function()
					instance[valueName] = original
				end)
			end
		end
	end
	
	-- Return update functions.
	return updateFunctions, resetFunctions
end