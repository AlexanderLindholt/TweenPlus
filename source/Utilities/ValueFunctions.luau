--!optimize 2
--!native

local function numberLerper(a, b)
	local difference = b - a
	
	return function(alpha)
		return a + difference*alpha
	end
end

local function normalize(x, y, z, w)
	local m = math.sqrt(x*x + y*y + z*z + w*w)
	if m == 0 then return 0, 0, 0, 1 end
	m = 1/m
	return x*m, y*m, z*m, w*m
end
local function normalizedQuaternionFromCFrame(cframe)
	local rightVector = cframe.RightVector
	local upVector = cframe.UpVector
	local lookVector = cframe.LookVector
	
	local rightX, rightY, rightZ = rightVector.X, rightVector.Y, rightVector.Z
	local upX, upY, upZ = upVector.X, upVector.Y, upVector.Z
	local leftX, leftY, leftZ = -lookVector.X, -lookVector.Y, -lookVector.Z
	
	local trace = rightX + upY + leftZ
	if trace > 0 then
		local s = math.sqrt(trace + 1)*2
		return normalize((upZ - leftY)/s, (leftX - rightZ)/s, (rightY - upX)/s, 0.25*s)
	end
	
	if rightX > upY and rightX > leftZ then
		local s = math.sqrt(1 + rightX - upY - leftZ)*2
		return normalize(0.25*s, (upX + rightY)/s, (leftX + rightZ)/s, (upZ - leftY)/s)
	elseif upY > leftZ then
		local s = math.sqrt(1 + upY - rightX - leftZ)*2
		return normalize((upX + rightY)/s, 0.25*s, (upZ + leftY)/s, (leftX - rightZ)/s)
	else
		local s = math.sqrt(1 + leftZ - rightX - upY)*2
		return normalize((leftX + rightZ)/s, (upZ + leftY)/s, 0.25*s, (rightY - upX)/s)
	end
end
local function cframeLerper(a, b)
	-- Position stuff.
	local ax, ay, az = a.X, a.Y, a.Z
	local bx, by, bz = b.X, b.Y, b.Z
	local dx, dy, dz = bx - ax, by - ay, bz - az
	
	-- Get normalized quaternions.
	local aqx, aqy, aqz, aqw = normalizedQuaternionFromCFrame(a)
	local bqx, bqy, bqz, bqw = normalizedQuaternionFromCFrame(b)
	
	-- Dot, and shortest path.
	local dot = aqx*bqx + aqy*bqy + aqz*bqz + aqw*bqw
	if dot < 0 then
		dot = -dot
		bqx, bqy, bqz, bqw = -bqx, -bqy, -bqz, -bqw
	end
	
	-- Slerp precompute.
	local dotSquared = dot*dot
	local A = 1.0904 - 3.2452*dot + 3.55645*dotSquared - 1.43519*dotSquared*dot
	local B = 0.848013 - 1.06021*dot + 0.215638*dotSquared
	
	-- Interpolation function.
	return function(alpha)
		if alpha == 1 then return b end
		
		-- Quaternion lerp.
		local shiftedAlpha = alpha - 0.5
		local s1 = (A*shiftedAlpha*shiftedAlpha + B)*(alpha*shiftedAlpha*(alpha - 1)) + alpha
		local s0 = 1 - s1
		
		local rx = s0*aqx + s1*bqx
		local ry = s0*aqy + s1*bqy
		local rz = s0*aqz + s1*bqz
		local rw = s0*aqw + s1*bqw
		
		local m = math.sqrt(rx*rx + ry*ry + rz*rz + rw*rw)
		if m ~= 0 then
			m = 1/m
			rx, ry, rz, rw = rx*m, ry*m, rz*m, rw*m
		end
		
		-- Build CFrame.
		return CFrame.new(
			-- Position.
			ax + dx*alpha,
			ay + dy*alpha,
			az + dz*alpha,
			-- Matrix.
			1 - 2*(ry*ry + rz*rz), 2*(rx*ry - rw*rz), 2*(rx*rz + rw*ry),
			2*(rx*ry + rw*rz), 1 - 2*(rx*rx + rz*rz), 2*(ry*rz - rw*rx),
			2*(rx*rz - rw*ry), 2*(ry*rz + rw*rx), 1 - 2*(rx*rx + ry*ry)
		)
	end
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
	l = l^(1/3)
	m = m^(1/3)
	s = s^(1/3)
	
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
	
	-- Return r, g, b.
	return r, g, b
end
local function colorLerper(a, b)
	local l1, a1, b1 = rgbToOklab(a.R, a.G, a.B)
	local l2, a2, b2 = rgbToOklab(b.R, b.G, b.B)
	return function(alpha)
		if alpha == 1 then return b end
		
		return Color3.new(
			oklabToRGB(
				l1 + (l2 - l1)*alpha,
				a1 + (a2 - a1)*alpha,
				b1 + (b2 - b1)*alpha
			)
		)
	end
end

local function findKeypoints(keypoints, targetTime)
	-- Binary search for a specific time.
	local low = 1
	local high = #keypoints
	while low <= high do
		local mid = math.floor((low + high)*0.5)
		local midTime = keypoints[mid].Time
		if midTime < targetTime then
			low = mid + 1
		elseif midTime > targetTime then
			high = mid - 1
		else
			mid = keypoints[mid]
			return mid, mid
		end
	end
	return keypoints[high], keypoints[low]
end
local function getNumberKeypoint(sequence, time)
	local keypoints = sequence.Keypoints
	local a, b = findKeypoints(keypoints, time)
	
	local aTime = a.Time
	
	if aTime == b.Time then return a.Value, a.Envelope end
	
	local aValue = a.Value
	local aEnvelope = a.Envelope
	
	local alpha = (time - aTime)/(b.Time - aTime)
	return
		aValue + (b.Value - aValue)*alpha,
		aEnvelope + (b.Envelope - aEnvelope)*alpha
end
local function getColorKeypoint(sequence, time)
	local keypoints = sequence.Keypoints
	local a, b = findKeypoints(keypoints, time)
	
	local aTime = a.Time
	
	if aTime == b.Time then return a.Value end
	
	local alpha = (time - aTime)/(b.Time - aTime)
	return a.Value:Lerp(b.Value, alpha)
end

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

return {
	Normal = {
		number = numberLerper,
		
		Vector3 = function(a, b)
			local aX = a.X
			local aY = a.Y
			local aZ = a.Z
			local xDifference = b.X - aX
			local yDifference = b.Y - aY
			local zDifference = b.Z - aZ
			
			return function(alpha)
				return vector.create(
					aX + xDifference*alpha,
					aY + yDifference*alpha,
					aZ + zDifference*alpha
				)
			end
		end,
		
		UDim2 = function(a, b)
			local aX = a.X
			local bX = b.X
			local aXScale = aX.Scale
			local aXOffset = aX.Offset
			local xScaleDifference = bX.Scale - aXScale
			local xOffsetDifference = bX.Offset - aXOffset
			
			local aY = a.Y
			local bY = b.Y
			local aYScale = aY.Scale
			local aYOffset = aY.Offset
			local yScaleDifference = bY.Scale - aYScale
			local yOffsetDifference = bY.Offset - aYOffset
			
			return function(alpha)
				return UDim2.new(
					aXScale + xScaleDifference*alpha,
					aXOffset + xOffsetDifference*alpha,
					
					aYScale + yScaleDifference*alpha,
					aYOffset + yOffsetDifference*alpha
				)
			end
		end,
		
		Vector2 = function(a, b)
			local aX = a.X
			local aY = a.Y
			local xDifference = b.X - aX
			local yDifference = b.Y - aY
			
			return function(alpha)
				return Vector2.new(
					aX + xDifference*alpha,
					aY + yDifference*alpha
				)
			end
		end,
		
		CFrame = cframeLerper,
		
		UDim = function(a, b)
			local aScale = a.Scale
			local aOffset = a.Offset
			local scaleDifference = b.Scale - aScale
			local offsetDifference = b.Offset - aOffset
			
			return function(alpha)
				return UDim.new(
					aScale + scaleDifference*alpha,
					aOffset + offsetDifference*alpha
				)
			end
		end,
		
		boolean = function(a, b)
			return function(alpha)
				return if alpha < 0.5 then a else b
			end
		end,
		
		string = function(a, b)
			local prefixLength = commonPrefix(a, b)
			local suffixLength = commonSuffix(a, b, prefixLength)
			
			local aMiddleStart = prefixLength + 1
			local aMiddleEnd = #a - suffixLength
			local bMiddleStart = prefixLength + 1
			local bMiddleEnd = #b - suffixLength
			
			local aMiddle = if aMiddleStart <= aMiddleEnd then a:sub(aMiddleStart, aMiddleEnd) else ""
			local bMiddle = if bMiddleStart <= bMiddleEnd then b:sub(bMiddleStart, bMiddleEnd) else ""
			
			local prefix = a:sub(1, prefixLength)
			local suffix = if suffixLength > 0 then a:sub(-suffixLength) else ""
			
			return function(alpha)
				if alpha == 1 then return b end
				
				local aVisible = math.floor(#aMiddle*(1 - alpha) + 0.5)
				local bVisible = math.floor(#bMiddle*alpha + 0.5)
				
				aVisible = math.min(#aMiddle, aVisible)
				bVisible = math.min(#bMiddle, bVisible)
				
				local result = prefix
				if aVisible > 0 then
					result ..= aMiddle:sub(1, aVisible)
				end
				if bVisible > 0 then
					result ..= bMiddle:sub(1, bVisible)
				end
				if suffixLength > 0 then
					result ..= suffix
				end
				return result
			end
		end,
		
		Color3 = colorLerper,
		
		NumberRange = function(a, b)
			local aMin = a.Min
			local aMax = a.Max
			local minimumDifference = b.Min - aMin
			local maximumDifference = b.Max - aMax
			
			return function(alpha)
				return NumberRange.new(
					aMin + minimumDifference*alpha,
					aMax + maximumDifference*alpha
				)
			end
		end,
		
		NumberSequence = function(a, b)
			-- Gather unique times.
			local uniqueTimes = {}
			for index, keypoint in a.Keypoints do
				uniqueTimes[index] = keypoint.Time
			end
			local previousAmount = #uniqueTimes
			for index, keypoint in b.Keypoints do
				uniqueTimes[index + previousAmount] = keypoint.Time
			end
			table.sort(uniqueTimes)
			
			-- Create and store lerpers.
			local valueLerpers = {}
			local envelopeLerpers = {}
			for index, time in uniqueTimes do
				local aValue, aEnvelope = getNumberKeypoint(a, time)
				local bValue, bEnvelope = getNumberKeypoint(b, time)
				valueLerpers[index] = numberLerper(aValue, bValue)
				envelopeLerpers[index] = numberLerper(aEnvelope, bEnvelope)
			end
			
			-- Final interpolator.
			return function(alpha)
				if alpha == 1 then return b end
				
				local keypoints = {}
				for index, time in uniqueTimes do
					keypoints[index] = NumberSequenceKeypoint.new(
						time,
						valueLerpers[index](alpha),
						envelopeLerpers[index](alpha)
					)
				end
				return NumberSequence.new(keypoints)
			end
		end,
		
		ColorSequence = function(a, b)
			-- Gather unique times.
			local uniqueTimes = {}
			for index, keypoint in a.Keypoints do
				uniqueTimes[index] = keypoint.Time
			end
			local previousAmount = #uniqueTimes
			for index, keypoint in b.Keypoints do
				uniqueTimes[index + previousAmount] = keypoint.Time
			end
			table.sort(uniqueTimes)
			
			-- Create and store lerpers.
			local lerpers = {}
			for index, time in uniqueTimes do
				lerpers[index] = colorLerper(getColorKeypoint(a, time), getColorKeypoint(b, time))
			end
			
			-- Final interpolator.
			return function(alpha)
				if alpha == 1 then return b end
				
				local keypoints = {}
				for index, time in uniqueTimes do
					keypoints[index] = ColorSequenceKeypoint.new(
						time,
						lerpers[index](alpha)
					)
				end
				return ColorSequence.new(keypoints)
			end
		end
	} :: {
		(a: any, b: any) -> ((alpha: number) -> any)
	},
	
	Advanced = {
		Pivot = {
			Target = "PVInstance",
			Set = function(instance, a, b)
				local lerp = cframeLerper(a, b)
				
				return function(alpha)
					instance:PivotTo(lerp(alpha))
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
			Set: (instance: Instance, a: any, b: any) -> ((alpha: number) -> any),
			Get: (instance: Instance) -> any
		}
	}
}