--!optimize 2
--!native

local function commonPrefix(a, b)
	local aLength = utf8.len(a)
	local bLength = utf8.len(b)
	local minLength = if aLength < bLength then aLength else bLength
	
	for index = 1, minLength, 1 do
		local aPosition = utf8.offset(a, index)
		local bPosition = utf8.offset(b, index)
		
		if utf8.codepoint(a, aPosition) ~= utf8.codepoint(b, bPosition) then
			return index - 1
		end
	end
	return minLength
end

local function commonSuffix(a, b, prefixLen)
	local aLength = utf8.len(a)
	local bLength = utf8.len(b)
	local maxLength = if aLength < bLength then aLength - prefixLen else bLength - prefixLen
	
	for index = 1, maxLength, 1 do
		local aPosition = utf8.offset(a, -index)
		local bPosition = utf8.offset(b, -index)
		
		if utf8.codepoint(a, aPosition) ~= utf8.codepoint(b, bPosition) then
			return index - 1
		end
	end
	return maxLength
end

local function rgbToOklab(r, g, b)
	-- Gamma expansion.
	r = if r > 0.04045 then ((r + 0.055)/1.055)^2.4 else r/12.92
	g = if g > 0.04045 then ((g + 0.055)/1.055)^2.4 else g/12.92
	b = if b > 0.04045 then ((b + 0.055)/1.055)^2.4 else b/12.92
	
	-- LMS conversion.
	local l = 0.4122214708*r + 0.5363325363*g + 0.0514459929*b
	local m = 0.2119034982*r + 0.6806995451*g + 0.1073969566*b
	local s = 0.0883024619*r + 0.2817188376*g + 0.6299787005*b
	
	-- Cube roots.
	l = l^0.3333333333333333
	m = m^0.3333333333333333
	s = s^0.3333333333333333
	
	-- Return l, a, b.
	return 
		0.2104542553*l + 0.7936177850*m - 0.0040720468*s,
		1.9779984951*l - 2.4285922050*m + 0.4505937099*s,
		0.0259040371*l + 0.7827717662*m - 0.8086757660*s
end

local function oklabToRGB(l, a, b)
	-- Matrix transformation.
	local m = l - 0.1055613458*a - 0.0638541728*b
	local s = l - 0.0894841775*a - 1.2914855480*b
	local l = l + 0.3963377774*a + 0.2158037573*b
	
	-- Cube values.
	l = l*l*l
	m = m*m*m
	s = s*s*s
	
	-- RGB conversion.
	local r = 4.0767416621*l - 3.3077115913*m + 0.2309699292*s
	local g = -1.2684380046*l + 2.6097574011*m - 0.3413193965*s
	b = -0.0041960863*l - 0.7034186147*m + 1.7076147010*s
	
	-- Gamma compression.
	if r > 0.0031308 then
		r = 1.055*(r^0.4166666667) - 0.055
	else
		r = r*12.92
	end
	if r < 0 then r = 0 elseif r > 1 then r = 1 end
	
	if g > 0.0031308 then
		g = 1.055*(g^0.4166666667) - 0.055
	else
		g = g*12.92
	end
	if g < 0 then g = 0 elseif g > 1 then g = 1 end
	
	if b > 0.0031308 then
		b = 1.055*(b^0.4166666667) - 0.055
	else
		b = b*12.92
	end
	if b < 0 then b = 0 elseif b > 1 then b = 1 end
	
	-- Return result as Color3.
	return Color3.new(r, g, b)
end

local function findKeypoints(source, targetTime)
	local low = 1
	local high = #source
	while low <= high do
		local mid = math.floor((low + high)/2)
		local midTime = source[mid].Time
		if midTime < targetTime then
			low = mid + 1
		elseif midTime > targetTime then
			high = mid - 1
		else
			return mid, mid
		end
	end
	return high, low
end

return {
	Normal = {
		number = function(a, b)
			local difference = b - a
			return function(alpha)
				return a + difference*alpha
			end
		end,
		
		Vector3 = function(a, b)
			return function(alpha)
				return a:Lerp(b, alpha)
			end
		end,
		
		UDim2 = function(a, b)
			return function(alpha)
				return a:Lerp(b, alpha)
			end
		end,
		
		Vector2 = function(a, b)
			return function(alpha)
				return a:Lerp(b, alpha)
			end
		end,
		
		CFrame = function(a, b)
			return function(alpha)
				return a:Lerp(b, alpha)
			end
		end,
		
		UDim = function(a, b)
			local scaleDiff = b.Scale - a.Scale
			local offsetDiff = b.Offset - a.Offset
			return function(alpha)
				return UDim.new(a.Scale + scaleDiff*alpha, a.Offset + offsetDiff*alpha)
			end
		end,
		
		boolean = function(a, b)
			return function(alpha)
				return if alpha < 0.5 then a else b
			end
		end,
		
		string = function(a, b)
			local prefixLen = commonPrefix(a, b)
			local suffixLen = commonSuffix(a, b, prefixLen)
			
			local aMiddleStart = prefixLen + 1
			local aMiddleEnd = #a - suffixLen
			local bMiddleStart = prefixLen + 1
			local bMiddleEnd = #b - suffixLen
			
			local aMiddle = if aMiddleStart <= aMiddleEnd then a:sub(aMiddleStart, aMiddleEnd) else ""
			local bMiddle = if bMiddleStart <= bMiddleEnd then b:sub(bMiddleStart, bMiddleEnd) else ""
			
			local prefix = a:sub(1, prefixLen)
			local suffix = if suffixLen > 0 then a:sub(-suffixLen) else ""
			
			return function(alpha)
				if alpha == 0 then return a end
				if alpha == 1 then return b end
				
				local aVisible = math.floor(#aMiddle*(1 - alpha) + 0.5)
				local bVisible = math.floor(#bMiddle*alpha + 0.5)
				
				aVisible = math.max(0, math.min(#aMiddle, aVisible))
				bVisible = math.max(0, math.min(#bMiddle, bVisible))
				
				local buffer = {prefix}
				if aVisible > 0 then
					table.insert(buffer, aMiddle:sub(1, aVisible))
				end
				if bVisible > 0 then
					table.insert(buffer, bMiddle:sub(1, bVisible))
				end
				if suffixLen > 0 then
					table.insert(buffer, suffix)
				end
				return table.concat(buffer)
			end
		end,
		
		Color3 = function(a, b)
			local l0, a0, b0 = rgbToOklab(a.R, a.G, a.B)
			local l1, a1, b1 = rgbToOklab(b.R, b.G, b.B)
			return function(alpha)
				if alpha == 0 then return a end
				if alpha == 1 then return b end
				
				local l = l0 + (l1 - l0)*alpha
				local a_lab = a0 + (a1 - a0)*alpha
				local b_lab = b0 + (b1 - b0)*alpha
				return oklabToRGB(l, a_lab, b_lab)
			end
		end,
		
		NumberRange = function(a, b)
			local minDiff = b.Min - a.Min
			local maxDiff = b.Max - a.Max
			return function(alpha)
				return NumberRange.new(a.Min + minDiff*alpha, a.Max + maxDiff*alpha)
			end
		end,
		
		NumberSequence = function(a, b)
			local uniqueTimes = {}
			local aValues = {}
			local bValues = {}
			local aEnvelopes = {}
			local bEnvelopes = {}
			
			local function getAtTime(seq, time)
				local i0, i1 = findKeypoints(seq, time)
				local kp0 = seq.Keypoints[i0]
				local kp1 = seq.Keypoints[i1]
				if kp0.Time == kp1.Time then
					return kp0.Value, kp0.Envelope
				else
					local p = (time - kp0.Time)/(kp1.Time - kp0.Time)
					local value = kp0.Value + (kp1.Value - kp0.Value)*p
					local envelope = kp0.Envelope + (kp1.Envelope - kp0.Envelope)*p
					return value, envelope
				end
			end
			
			local timeSet = {}
			for _, kp in ipairs(a.Keypoints) do
				timeSet[kp.Time] = true
			end
			for _, kp in ipairs(b.Keypoints) do
				timeSet[kp.Time] = true
			end
			for time in pairs(timeSet) do
				table.insert(uniqueTimes, time)
			end
			table.sort(uniqueTimes)
			
			for _, time in ipairs(uniqueTimes) do
				local aValue, aEnvelope = getAtTime(a, time)
				local bValue, bEnvelope = getAtTime(b, time)
				table.insert(aValues, aValue)
				table.insert(bValues, bValue)
				table.insert(aEnvelopes, aEnvelope)
				table.insert(bEnvelopes, bEnvelope)
			end
			
			return function(alpha)
				local keypoints = {}
				for index, time in ipairs(uniqueTimes) do
					local value = aValues[index] + (bValues[index] - aValues[index])*alpha
					local envelope = aEnvelopes[index] + (bEnvelopes[index] - aEnvelopes[index])*alpha
					table.insert(keypoints, NumberSequenceKeypoint.new(time, value, envelope))
				end
				return NumberSequence.new(keypoints)
			end
		end,
		
		ColorSequence = function(a, b)
			local uniqueTimes = {}
			local aValues = {}
			local bValues = {}
			local aEnvelopes = {}
			local bEnvelopes = {}
			
			local function getAtTime(seq, time)
				local i0, i1 = findKeypoints(seq, time)
				local kp0 = seq.Keypoints[i0]
				local kp1 = seq.Keypoints[i1]
				if kp0.Time == kp1.Time then
					return kp0.Value, kp0.Envelope
				else
					local p = (time - kp0.Time)/(kp1.Time - kp0.Time)
					local value = kp0.Value:Lerp(kp1.Value, p)
					local envelope = kp0.Envelope + (kp1.Envelope - kp0.Envelope)*p
					return value, envelope
				end
			end
			
			local timeSet = {}
			for _, kp in ipairs(a.Keypoints) do
				timeSet[kp.Time] = true
			end
			for _, kp in ipairs(b.Keypoints) do
				timeSet[kp.Time] = true
			end
			for time in pairs(timeSet) do
				table.insert(uniqueTimes, time)
			end
			table.sort(uniqueTimes)
			
			for _, time in ipairs(uniqueTimes) do
				local aValue, aEnvelope = getAtTime(a, time)
				local bValue, bEnvelope = getAtTime(b, time)
				table.insert(aValues, aValue)
				table.insert(bValues, bValue)
				table.insert(aEnvelopes, aEnvelope)
				table.insert(bEnvelopes, bEnvelope)
			end
			
			return function(alpha)
				local keypoints = {}
				for index, time in ipairs(uniqueTimes) do
					local value = aValues[index]:Lerp(bValues[index], alpha)
					local envelope = aEnvelopes[index] + (bEnvelopes[index] - aEnvelopes[index])*alpha
					table.insert(keypoints, ColorSequenceKeypoint.new(time, value, envelope))
				end
				return ColorSequence.new(keypoints)
			end
		end
	} :: {(a: any, b: any) -> (alpha: number) -> any},
	
	Advanced = {
		Pivot = {
			Target = "PVInstance",
			Set = function(instance, a, b)
				return function(alpha)
					instance:PivotTo(a:Lerp(b, alpha))
				end
			end,
			Get = function(instance)
				return instance:GetPivot()
			end
		},
		Scale = {
			Target = "Model",
			Set = function(instance, a, b)
				local difference = b - a
				return function(alpha)
					instance:ScaleTo(a + difference*alpha)
				end
			end,
			Get = function(instance)
				return instance:GetScale()
			end
		}
	} :: {
		{
			Set: (instance: Instance, a: any, b: any) -> (alpha: number) -> any,
			Get: (instance: Instance) -> any
		}
	}
}