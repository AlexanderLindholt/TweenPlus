--!optimize 2

-- Value functions.
local valueFunctions = require(script.Parent.ValueFunctions)

local normalValueFunctions = valueFunctions.Normal
local normalBezierValueFunctions = normalValueFunctions.Bezier
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
		if type(name) ~= "string" then error("Invalid value name of type '"..typeof(name).."'. Expected a string.", 3) end
		
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
				local value = instance[name]
				local dataType = if value == nil then "Instance" else typeof(value)
				value = normalValueFunctions[dataType]
				if not value then error("'"..dataType.."' data type is not supported.", 3) end
				
				local original = instance[name]
				
				if type(destination) == "table" then
					value = normalBezierValueFunctions[dataType]
					if not value then error("'"..dataType.."' data type is not supported for bezier curves.", 3) end
					if #destination > 3 then error("A maximum of 2 control points (cubic) are supported for bezier curves.", 3) end
					for _, value in destination do
						if typeof(value) ~= dataType then error("'"..name.."' value contains inconsistent datatypes.", 3) end
					end
					value = value(original, table.unpack(destination))
				else
					value = value(original, destination)
				end
				
				updateFunctions[index] = function(alpha)
					instance[name] = value(alpha)
				end
			else
				local value = advancedValueFunctions[name]
				if value then
					-- Hidden property.
					if not instance:IsA(value.Target) then error("'"..instance:GetFullName().."' doesn’t support "..name..".", 3) end
					
					local original = value.Get(instance)
					
					if type(destination) == "table" then
						local bezierSet = value.BezierSet
						if not bezierSet then error("'"..name.."' is not supported for bezier curves.", 3) end
						if #destination > 3 then error("A maximum of 2 control points (cubic) are supported for bezier curves.", 3) end
						local dataType = typeof(original)
						for _, value in destination do
							if typeof(value) ~= dataType then error("'"..name.."' value contains inconsistent datatypes.", 3) end
						end
						updateFunctions[index] = bezierSet(instance, original, table.unpack(destination))
					else
						updateFunctions[index] = value.Set(instance, original, destination)
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
