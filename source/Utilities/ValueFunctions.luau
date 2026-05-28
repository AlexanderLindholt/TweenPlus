--!optimize 2
--!native

local function numberLerp(a, b)
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
	-- Get vectors.
	local rightVector = cframe.RightVector
	local upVector = cframe.UpVector
	local lookVector = cframe.LookVector
	
	-- Get axis values.
	local rightX, rightY, rightZ = rightVector.X, rightVector.Y, rightVector.Z
	local upX, upY, upZ = upVector.X, upVector.Y, upVector.Z
	local leftX, leftY, leftZ = -lookVector.X, -lookVector.Y, -lookVector.Z
	
	-- Check trace.
	local trace = rightX + upY + leftZ
	if trace > 0 then
		local s = math.sqrt(trace + 1)*2
		return normalize((upZ - leftY)/s, (leftX - rightZ)/s, (rightY - upX)/s, 0.25*s)
	end
	
	-- Check diagonals.
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

local function cframeLerp(a, b)
	-- Reference position values.
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
		if alpha == 0 then return a end
		if alpha == 1 then return b end
		
		-- Quaternion lerp.
		local shiftedAlpha = alpha - 0.5
		local weight2 = (A*shiftedAlpha*shiftedAlpha + B)*(alpha*shiftedAlpha*(alpha - 1)) + alpha
		local weight1 = 1 - weight2
		
		local rx = weight1*aqx + weight2*bqx
		local ry = weight1*aqy + weight2*bqy
		local rz = weight1*aqz + weight2*bqz
		local rw = weight1*aqw + weight2*bqw
		
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

local function bezierCFrameLerp(a, b, c, d)
	-- Reference position values.
	local ax, ay, az = a.X, a.Y, a.Z
	local bx, by, bz = b.X, b.Y, b.Z
	local cx, cy, cz = c.X, c.Y, c.Z
	
	-- Get normalized quaternions.
	local aqx, aqy, aqz, aqw = normalizedQuaternionFromCFrame(a)
	local bqx, bqy, bqz, bqw = normalizedQuaternionFromCFrame(b)
	local cqx, cqy, cqz, cqw = normalizedQuaternionFromCFrame(c)
	
	-- Shortest path alignment (Start -> Control1).
	if aqx*cqx + aqy*cqy + aqz*cqz + aqw*cqw < 0 then
		cqx, cqy, cqz, cqw = -cqx, -cqy, -cqz, -cqw
	end
	
	-- Cubic bezier stuff.
	if d then
		-- Reference and calculate data from new point.
		local dx, dy, dz = d.X, d.Y, d.Z
		local dqx, dqy, dqz, dqw = normalizedQuaternionFromCFrame(d)
		
		-- Shortest path alignment (Control1 -> Control2, then Control2 -> Destination).
		if cqx*dqx + cqy*dqy + cqz*dqz + cqw*dqw < 0 then
			dqx, dqy, dqz, dqw = -dqx, -dqy, -dqz, -dqw
		end
		if dqx*bqx + dqy*bqy + dqz*bqz + dqw*bqw < 0 then
			bqx, bqy, bqz, bqw = -bqx, -bqy, -bqz, -bqw
		end
		
		-- Interpolation function.
		return function(alpha)
			if alpha == 0 then return a end
			if alpha == 1 then return b end
			
			-- Polynomial weight precompute.
			local invertedAlpha = 1 - alpha
			local invertedAlphaSquared = invertedAlpha*invertedAlpha
			local alphaSquared = alpha*alpha
			
			local weight1 = invertedAlphaSquared*invertedAlpha
			local weight2 = 3*invertedAlphaSquared*alpha
			local weight3 = 3*invertedAlpha*alphaSquared
			local weight4 = alphaSquared*alpha
			
			-- Quaternion NLERP.
			local rx = weight1*aqx + weight2*cqx + weight3*dqx + weight4*bqx
			local ry = weight1*aqy + weight2*cqy + weight3*dqy + weight4*bqy
			local rz = weight1*aqz + weight2*cqz + weight3*dqz + weight4*bqz
			local rw = weight1*aqw + weight2*cqw + weight3*dqw + weight4*bqw
			
			local m = math.sqrt(rx*rx + ry*ry + rz*rz + rw*rw)
			if m ~= 0 then
				m = 1/m
				rx, ry, rz, rw = rx*m, ry*m, rz*m, rw*m
			end
			
			-- Build CFrame.
			return CFrame.new(
				-- Position.
				weight1*ax + weight2*cx + weight3*dx + weight4*bx,
				weight1*ay + weight2*cy + weight3*dy + weight4*by,
				weight1*az + weight2*cz + weight3*dz + weight4*bz,
				-- Matrix.
				1 - 2*(ry*ry + rz*rz), 2*(rx*ry - rw*rz), 2*(rx*rz + rw*ry),
				2*(rx*ry + rw*rz), 1 - 2*(rx*rx + rz*rz), 2*(ry*rz - rw*rx),
				2*(rx*rz - rw*ry), 2*(ry*rz + rw*rx), 1 - 2*(rx*rx + ry*ry)
			)
		end
	end
	
	-- Quadratic Bézier execution.
	-- Shortest path alignment (CP1 -> Destination).
	if cqx*bqx + cqy*bqy + cqz*bqz + cqw*bqw < 0 then
		bqx, bqy, bqz, bqw = -bqx, -bqy, -bqz, -bqw
	end
	
	-- Interpolation function.
	return function(alpha)
		if alpha == 0 then return a end
		if alpha == 1 then return b end
		
		-- Polynomial weight precompute.
		local invertedAlpha = 1 - alpha
		local invertedAlphaSquared = invertedAlpha*invertedAlpha
		local alphaSquared = alpha*alpha
		
		local weight1 = invertedAlphaSquared
		local weight2 = 2*invertedAlpha*alpha
		local weight3 = alphaSquared
		
		-- Quaternion NLERP.
		local rx = weight1*aqx + weight2*cqx + weight3*bqx
		local ry = weight1*aqy + weight2*cqy + weight3*bqy
		local rz = weight1*aqz + weight2*cqz + weight3*bqz
		local rw = weight1*aqw + weight2*cqw + weight3*bqw
		
		local m = math.sqrt(rx*rx + ry*ry + rz*rz + rw*rw)
		if m ~= 0 then
			m = 1/m
			rx, ry, rz, rw = rx*m, ry*m, rz*m, rw*m
		end
		
		-- Build CFrame.
		return CFrame.new(
			-- Position.
			weight1*ax + weight2*cx + weight3*bx,
			weight1*ay + weight2*cy + weight3*by,
			weight1*az + weight2*cz + weight3*bz,
			-- Matrix.
			1 - 2*(ry*ry + rz*rz), 2*(rx*ry - rw*rz), 2*(rx*rz + rw*ry),
			2*(rx*ry + rw*rz), 1 - 2*(rx*rx + rz*rz), 2*(ry*rz - rw*rx),
			2*(rx*rz - rw*ry), 2*(ry*rz + rw*rx), 1 - 2*(rx*rx + ry*ry)
		)
	end
end

local function rgbToOklab(r, g, b)
	-- Gamma expansion.
	r = if r > 0.04045 then ((r + 0.055)*0.9478672985781991)^2.4 else r/12.92
	g = if g > 0.04045 then ((g + 0.055)*0.9478672985781991)^2.4 else g/12.92
	b = if b > 0.04045 then ((b + 0.055)*0.9478672985781991)^2.4 else b/12.92
	
	-- LMS conversion.
	local l = 0.4122214708*r + 0.5363325363*g + 0.0514459929*b
	local m = 0.2119034982*r + 0.6806995451*g + 0.1073969566*b
	local s = 0.0883024619*r + 0.2817188376*g + 0.6299787005*b
	
	-- Cube roots.
	l = l^(1/3)
	m = m^(1/3)
	s = s^(1/3)
	
	-- Return converted values.
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
		r *= 12.92
	end
	if r < 0 then r = 0 elseif r > 1 then r = 1 end
	
	if g > 0.0031308 then
		g = 1.055*(g^0.4166666667) - 0.055
	else
		g *= 12.92
	end
	if g < 0 then g = 0 elseif g > 1 then g = 1 end
	
	if b > 0.0031308 then
		b = 1.055*(b^0.4166666667) - 0.055
	else
		b *= 12.92
	end
	if b < 0 then b = 0 elseif b > 1 then b = 1 end
	
	-- Return converted values.
	return r, g, b
end
local function colorLerper(a, b)
	local l1, a1, b1 = rgbToOklab(a.R, a.G, a.B)
	local l2, a2, b2 = rgbToOklab(b.R, b.G, b.B)
	
	local differenceL = l2 - l1
	local differenceA = a2 - a1
	local differenceB = b2 - b1
	
	return function(alpha)
		if alpha == 0 then return a end
		if alpha == 1 then return b end
		
		return Color3.new(
			oklabToRGB(
				l1 + differenceL*alpha,
				a1 + differenceA*alpha,
				b1 + differenceB*alpha
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
	-- Locate bounding keypoints.
	local keypoints = sequence.Keypoints
	local a, b = findKeypoints(keypoints, time)
	
	-- Return early on exact match.
	local aTime = a.Time
	if aTime == b.Time then return a.Value, a.Envelope end
	
	-- Interpolate values.
	local alpha = (time - aTime)/(b.Time - aTime)
	local aValue = a.Value
	local aEnvelope = a.Envelope
	return
		aValue + (b.Value - aValue)*alpha,
		aEnvelope + (b.Envelope - aEnvelope)*alpha
end
local function getColorKeypoint(sequence, time)
	-- Locate bounding keypoints.
	local keypoints = sequence.Keypoints
	local a, b = findKeypoints(keypoints, time)
	
	-- Return early on exact match.
	local aTime = a.Time
	if aTime == b.Time then return a.Value end
	
	-- Interpolate values.
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
		Bezier = {
			Vector3 = function(a, b, c, d)
				if d then
					return function(alpha)
						local invertedAlpha = 1 - alpha
						local invertedAlphaSquared = invertedAlpha*invertedAlpha
						local alphaSquared = alpha*alpha
						
						return (invertedAlphaSquared*invertedAlpha)*a 
							+ (3*invertedAlphaSquared*alpha)*c 
							+ (3*invertedAlpha*alphaSquared)*d 
							+ (alphaSquared*alpha)*b
					end
				end
				
				return function(alpha)
					local invertedAlpha = 1 - alpha
					return (invertedAlpha*invertedAlpha)*a 
						+ (2*invertedAlpha*alpha)*c 
						+ (alpha*alpha)*b
				end
			end,
			
			Vector2 = function(a, b, c, d)
				local aX, aY = a.X, a.Y
				local bX, bY = b.X, b.Y
				local cX, cY = c.X, c.Y
				
				if d then
					local dX, dY = d.X, d.Y
					return function(alpha)
						local invertedAlpha = 1 - alpha
						local invertedAlphaSquared = invertedAlpha*invertedAlpha
						local alphaSquared = alpha*alpha
						
						local weight1 = invertedAlphaSquared*invertedAlpha
						local weight2 = 3*invertedAlphaSquared*alpha
						local weight3 = 3*invertedAlpha*alphaSquared
						local weight4 = alphaSquared*alpha
						
						return Vector2.new(
							weight1*aX + weight2*cX + weight3*dX + weight4*bX,
							weight1*aY + weight2*cY + weight3*dY + weight4*bY
						)
					end
				end
				
				return function(alpha)
					local invertedAlpha = 1 - alpha
					local weight1 = invertedAlpha*invertedAlpha
					local weight2 = 2*invertedAlpha*alpha
					local weight3 = alpha*alpha
					
					return Vector2.new(
						weight1*aX + weight2*cX + weight3*bX,
						weight1*aY + weight2*cY + weight3*bY
					)
				end
			end,
			
			UDim2 = function(a, b, c, d)
				local aX, aY = a.X, a.Y
				local bX, bY = b.X, b.Y
				local cX, cY = c.X, c.Y
				
				local aXScale, aXOffset = aX.Scale, aX.Offset
				local aYScale, aYOffset = aY.Scale, aY.Offset
				
				local bXScale, bXOffset = bX.Scale, bX.Offset
				local bYScale, bYOffset = bY.Scale, bY.Offset
				
				local cXScale, cXOffset = cX.Scale, cX.Offset
				local cYScale, cYOffset = cY.Scale, cY.Offset
				
				if d then
					local dX, dY = d.X, d.Y
					local dXScale, dXOffset = dX.Scale, dX.Offset
					local dYScale, dYOffset = dY.Scale, dY.Offset
					
					return function(alpha)
						local invertedAlpha = 1 - alpha
						local invertedAlphaSquared = invertedAlpha*invertedAlpha
						local alphaSquared = alpha*alpha
						
						local weight1 = invertedAlphaSquared*invertedAlpha
						local weight2 = 3*invertedAlphaSquared*alpha
						local weight3 = 3*invertedAlpha*alphaSquared
						local weight4 = alphaSquared*alpha
						
						return UDim2.new(
							weight1*aXScale + weight2*cXScale + weight3*dXScale + weight4*bXScale,
							weight1*aXOffset + weight2*cXOffset + weight3*dXOffset + weight4*bXOffset,
							weight1*aYScale + weight2*cYScale + weight3*dYScale + weight4*bYScale,
							weight1*aYOffset + weight2*cYOffset + weight3*dYOffset + weight4*bYOffset
						)
					end
				end
				
				return function(alpha)
					local invertedAlpha = 1 - alpha
					local weight1 = invertedAlpha*invertedAlpha
					local weight2 = 2*invertedAlpha*alpha
					local weight3 = alpha*alpha
					
					return UDim2.new(
						weight1*aXScale + weight2*cXScale + weight3*bXScale,
						weight1*aXOffset + weight2*cXOffset + weight3*bXOffset,
						weight1*aYScale + weight2*cYScale + weight3*bYScale,
						weight1*aYOffset + weight2*cYOffset + weight3*bYOffset
					)
				end
			end,
			
			UDim = function(a, b, c, d)
				local aScale, aOffset = a.Scale, a.Offset
				local bScale, bOffset = b.Scale, b.Offset
				local cScale, cOffset = c.Scale, c.Offset
				
				if d then
					local dScale, dOffset = d.Scale, d.Offset
					return function(alpha)
						local invertedAlpha = 1 - alpha
						local invertedAlphaSquared = invertedAlpha * invertedAlpha
						local alphaSquared = alpha * alpha
						
						local weight1 = invertedAlphaSquared * invertedAlpha
						local weight2 = 3 * invertedAlphaSquared * alpha
						local weight3 = 3 * invertedAlpha * alphaSquared
						local weight4 = alphaSquared * alpha
						
						return UDim.new(
							weight1 * aScale + weight2 * cScale + weight3 * dScale + weight4 * bScale,
							weight1 * aOffset + weight2 * cOffset + weight3 * dOffset + weight4 * bOffset
						)
					end
				end
				
				return function(alpha)
					local invertedAlpha = 1 - alpha
					local weight1 = invertedAlpha * invertedAlpha
					local weight2 = 2 * invertedAlpha * alpha
					local weight3 = alpha * alpha
					
					return UDim.new(
						weight1 * aScale + weight2 * cScale + weight3 * bScale,
						weight1 * aOffset + weight2 * cOffset + weight3 * bOffset
					)
				end
			end,
			
			CFrame = bezierCFrameLerp
		},
		
		number = numberLerp,
		
		Vector3 = function(a, b)
			local difference = b - a
			return function(alpha)
				return a + difference*alpha
			end
		end,
		
		Vector2 = function(a, b)
			local startX, startY = a.X, a.Y
			local xDifference = b.X - startX
			local yDifference = b.Y - startY
			
			return function(alpha)
				return Vector2.new(
					startX + xDifference*alpha,
					startY + yDifference*alpha
				)
			end
		end,
		
		UDim = function(a, b)
			local startScale, startOffset = a.Scale, a.Offset
			local scaleDifference = b.Scale - startScale
			local offsetDifference = b.Offset - startOffset
			
			return function(alpha)
				return UDim.new(
					startScale + scaleDifference*alpha,
					startOffset + offsetDifference*alpha
				)
			end
		end,
		
		UDim2 = function(a, b)
			local startX = a.X
			local startY = a.Y
			local endX = b.X
			local endY = b.Y
			
			local startXScale, startXOffset = startX.Scale, startX.Offset
			local startYScale, startYOffset = startY.Scale, startY.Offset
			
			local xScaleDifference = endX.Scale - startXScale
			local xOffsetDifference = endX.Offset - startXOffset
			local yScaleDifference = endY.Scale - startYScale
			local yOffsetDifference = endY.Offset - startYOffset
			
			return function(alpha)
				return UDim2.new(
					startXScale + xScaleDifference*alpha,
					startXOffset + xOffsetDifference*alpha,
					startYScale + yScaleDifference*alpha,
					startYOffset + yOffsetDifference*alpha
				)
			end
		end,
		
		CFrame = cframeLerp,
		
		boolean = function(a, b)
			return function(alpha)
				return if alpha < 0.5 then a else b
			end
		end,
		
		string = function(a, b)
			-- Reference character mappings.
			local aOffsets, aCodepoints, aLength = {}, {}, 0
			for position, codepoint in utf8.codes(a) do
				aLength = aLength + 1
				aOffsets[aLength], aCodepoints[aLength] = position, codepoint
			end
			aOffsets[aLength + 1] = #a + 1
			
			local bOffsets, bCodepoints, bLength = {}, {}, 0
			for position, codepoint in utf8.codes(b) do
				bLength = bLength + 1
				bOffsets[bLength], bCodepoints[bLength] = position, codepoint
			end
			bOffsets[bLength + 1] = #b + 1
			
			-- Prefix and suffix lengths.
			local minimumLength = if aLength < bLength then aLength else bLength
			local prefixLength = 0
			for index = 1, minimumLength do
				if aCodepoints[index] ~= bCodepoints[index] then break end
				prefixLength = prefixLength + 1
			end
			
			local suffixLength = 0
			for index = 1, minimumLength - prefixLength do
				if aCodepoints[aLength - index + 1] ~= bCodepoints[bLength - index + 1] then break end
				suffixLength = suffixLength + 1
			end
			
			-- Extract static segments.
			local prefix = a:sub(1, aOffsets[prefixLength + 1] - 1)
			local suffix = a:sub(aOffsets[aLength - suffixLength + 1])
			
			-- Precompute mid-section parameters.
			local aStartByte = aOffsets[prefixLength + 1]
			local bStartByte = bOffsets[prefixLength + 1]
			local aMidLen = aLength - prefixLength - suffixLength
			local bMidLen = bLength - prefixLength - suffixLength
			
			-- Interpolation function.
			return function(alpha)
				if alpha == 0 then return a end
				if alpha == 1 then return b end
				
				-- Calculate character visibility.
				local aVisible = math.floor(aMidLen*(1 - alpha) + 0.5)
				local bVisible = math.floor(bMidLen*alpha + 0.5)
				
				-- Combine segments.
				return prefix 
					.. a:sub(aStartByte, aOffsets[prefixLength + aVisible + 1] - 1) 
					.. b:sub(bStartByte, bOffsets[prefixLength + bVisible + 1] - 1) 
					.. suffix
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
			local occupied = {}
			for _, keypoint in a.Keypoints do
				local thisTime = keypoint.Time
				if not occupied[thisTime] then
					occupied[thisTime] = true
					table.insert(uniqueTimes, thisTime)
				end
			end
			for _, keypoint in b.Keypoints do
				local thisTime = keypoint.Time
				if not occupied[thisTime] then
					occupied[thisTime] = true
					table.insert(uniqueTimes, thisTime)
				end
			end
			table.sort(uniqueTimes)
			
			-- Create and store lerpers.
			local valueLerpers = {}
			local envelopeLerpers = {}
			for index, time in uniqueTimes do
				local aValue, aEnvelope = getNumberKeypoint(a, time)
				local bValue, bEnvelope = getNumberKeypoint(b, time)
				valueLerpers[index] = numberLerp(aValue, bValue)
				envelopeLerpers[index] = numberLerp(aEnvelope, bEnvelope)
			end
			
			-- Final interpolator.
			return function(alpha)
				if alpha == 0 then return a end
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
			local occupied = {}
			for _, keypoint in a.Keypoints do
				local thisTime = keypoint.Time
				if not occupied[thisTime] then
					occupied[thisTime] = true
					table.insert(uniqueTimes, thisTime)
				end
			end
			for _, keypoint in b.Keypoints do
				local thisTime = keypoint.Time
				if not occupied[thisTime] then
					occupied[thisTime] = true
					table.insert(uniqueTimes, thisTime)
				end
			end
			table.sort(uniqueTimes)
			
			-- Create and store lerpers.
			local lerpers = {}
			for index, time in uniqueTimes do
				lerpers[index] = colorLerper(getColorKeypoint(a, time), getColorKeypoint(b, time))
			end
			
			-- Final interpolator.
			return function(alpha)
				if alpha == 0 then return a end
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
	},
	
	Advanced = {
		Pivot = {
			Target = "PVInstance",
			
			Set = function(instance, a, b)
				local lerp = cframeLerp(a, b)
				
				return function(alpha)
					instance:PivotTo(lerp(alpha))
				end
			end,
			BezierSet = function(instance, a, b, c, d)
				local lerp = bezierCFrameLerp(a, b, c, d)
				
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
	}
}
