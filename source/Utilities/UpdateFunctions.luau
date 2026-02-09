--!optimize 2

-- Value functions.
local valueFunctions = require(script.Parent.ValueFunctions)

local normalValueFunctions = valueFunctions.Normal
local advancedValueFunctions = valueFunctions.Advanced

-- Property validation function.
local function checkProperty(instance, property)
	instance[property] = instance[property]
end

-- Update functions function.
return function(instance, values)
	-- Verify values and add update functions for each.
	local updateFunctions = table.create(#values)
	
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
		else
			-- Not attribute.
			if pcall(checkProperty, instance, name) then
				-- Validate.
				local value = instance[name]
				local dataType = if value == nil then "Instance" else typeof(value)
				value = normalValueFunctions[dataType]
				if not value then error("'"..dataType.."' data type is not supported.", 3) end
				
				-- Set up.
				local original = instance[name]
				value = value(original, destination)
				
				updateFunctions[index] = function(alpha)
					instance[name] = value(alpha)
				end
			else
				local value = advancedValueFunctions[name]
				if value then
					-- Hidden property.
					if not instance:IsA(value.Target) then error("'"..instance:GetFullName().."' doesn't support "..name..".", 3) end
					
					local original = value.Get(instance)
					local setValue = value.Set(instance, original, destination)
					updateFunctions[index] = function(alpha)
						setValue(alpha)
					end
				else
					error("'"..name.."' is not a valid property of '"..instance:GetFullName().."'.", 3)
				end
			end
		end
		
		index += 1
	end
	
	-- Return update functions.
	return updateFunctions
end
