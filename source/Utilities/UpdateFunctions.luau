--!optimize 2
--!native

-- Value functions.
local valueFunctions = require(script.Parent.ValueFunctions)

local normalValueFunctions = valueFunctions.Normal
local advancedValueFunctions = valueFunctions.Advanced

-- Update functions function.
return function(apiMap, instance, values)
	-- Get properties and verify class.
	local classProperties = apiMap[instance.ClassName] :: {
		[string]: {
			Type: string,
			Locked: boolean
		}
	}
	if not classProperties then error("Could not identify the class of instance '"..instance:GetFullName().."'.", 3) end

	-- Verify values and add update functions for each.
	local updateFunctions, resetFunctions = table.create(#values), table.create(#values)
	
	local index = 1
	for name, destination in values do
		if type(name) ~= "string" then error("Invalid value name of type '"..typeof(name).."'. It should be a string.", 3) end
		
		if name:sub(1, 1) == "@" then
			-- Attribute.
			local attributeName = name:sub(2)
			
			local original = instance:GetAttribute(attributeName)
			if original == nil then error("'"..attributeName.."' is not a valid attribute of '"..instance:GetFullName().."'.", 3) end
			
			local value = normalValueFunctions[typeof(destination)]
			if not value then error("'"..typeof(destination).."' data type is not supported.", 3) end
			value = value(original, destination)
			
			updateFunctions[index] = function(alpha)
				instance:SetAttribute(attributeName, value(alpha))
			end
			resetFunctions[index] = function()
				instance:SetAttribute(attributeName, original)
			end
		else
			-- Not attribute.
			local property = classProperties[name]
			if not property then
				local value = advancedValueFunctions[name]
				if value then
					-- Hidden property.
					if not instance:IsA(value.Target) then error("'"..instance:GetFullName().."' doesn't support "..name..".", 3) end
					
					local original = value.Get(instance)
					local setValue = value.Set(instance, original, destination)
					updateFunctions[index] = function(alpha)
						setValue(alpha)
					end
					resetFunctions[index] = function()
						setValue(0)
					end
					
					continue
				else
					error("'"..name.."' is not a valid property of '"..instance:GetFullName().."'.", 3)
				end
			end
			
			-- Property.
			if property.Locked then error("'"..name.."' is a locked property.", 3) end
			
			local value = normalValueFunctions[typeof(destination)]
			if not value then error("'"..typeof(destination).."' data type is not supported.", 3) end
			
			local original = instance[name]
			value = value(original, destination)
			
			updateFunctions[index] = function(alpha)
				instance[name] = value(alpha)
			end
			resetFunctions[index] = function()
				instance[name] = original
			end
		end
		
		index += 1
	end
	
	-- Return update functions.
	return updateFunctions, resetFunctions
end