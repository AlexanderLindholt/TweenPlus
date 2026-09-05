--!optimize 2
--!native

--[[
	S8		Minimum: -128			Maximum: 127
	S16		Minimum: -32768			Maximum: 32767
	S24		Minimum: -8388608		Maximum: 8388607
	S32		Minimum: -2147483648	Maximum: 2147483647

	U8		Minimum: 0				Maximum: 255
	U16		Minimum: 0				Maximum: 65535
	U24		Minimum: 0				Maximum: 16777215
	U32		Minimum: 0				Maximum: 4294967295

	F16		±2048					[65520]
	F24		±262144					[4294959104]
	F32		±16777216				[170141183460469231731687303715884105728]
	F64		±9007199254740992		[huge]
]]


-- Types.
export type Cursor = {
	Buffer:					buffer,
	BufferLength:			number,
	BufferOffset:			number,
	Instances:				{Instance},
	InstancesOffset:		number,
}

-- Signal types from Signal+.
export type Connection = {
	Signal: Signal,
	Connected: boolean,
	Disconnect: typeof(
		-- Removes the connection from the signal.
		-- <strong>The connection’s data remains.</strong>
		function(connection: Connection) end
	)
}
export type Signal<Parameters...> = {
	Connect: typeof(
		-- Connects a function.
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	Once: typeof(
		-- Connects a function, then auto-disconnects after the first call.
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	Wait: typeof(
		-- Yields the calling thread until the next fire.
		function(signal: Signal<Parameters...>): Parameters... end
	),
	
	Fire: typeof(
		-- Runs all connected functions and resumes all waiting threads.
		function(signal: Signal<Parameters...>, ...: Parameters...) end
	),
	
	DisconnectAll: typeof(
		-- Erases all connections.
		-- <strong>Much faster than calling <code>Disconnect</code> on each.</strong>
		function(signal: Signal<Parameters...>) end
	),
	Destroy: typeof(
		-- Erases all connections and methods.
		-- <strong>To fully erase, also remove all references to the signal.</strong>
		function(signal: Signal<Parameters...>) end
	)
}


-- Varables
local activeCursor: Cursor
local activeBuffer: buffer
local bufferLength: number
local bufferOffset: number
local instances: {Instance}
local instancesOffset: number
local dataTypes = {}
local reads = {}
local writes = {}
local anyreads = {}	:: {[any]: () -> any}
local anywrites = {} :: {[any]: (any) -> ()}


-- Functions.
local function allocate(bytes: number)
	local targetLength = bufferOffset + bytes
	if bufferLength < targetLength then
		while true do bufferLength *= 2 if bufferLength >= targetLength then break end end
		local newBuffer = buffer.create(bufferLength)
		buffer.copy(newBuffer, 0, activeBuffer, 0, bufferOffset)
		activeCursor.Buffer = newBuffer
		activeBuffer = newBuffer
	end
end

local function readS8(): number local value = buffer.readi8(activeBuffer, bufferOffset) bufferOffset += 1 return value end
local function writeS8(value: number) buffer.writei8(activeBuffer, bufferOffset, value) bufferOffset += 1 end
local function readS16(): number local value = buffer.readi16(activeBuffer, bufferOffset) bufferOffset += 2 return value end
local function writeS16(value: number) buffer.writei16(activeBuffer, bufferOffset, value) bufferOffset += 2 end
local function readS24(): number local value = buffer.readbits(activeBuffer, bufferOffset*8, 24) - 8388608 bufferOffset += 3 return value end
local function writeS24(value: number) buffer.writebits(activeBuffer, bufferOffset*8, 24, value + 8388608) bufferOffset += 3 end
local function readS32(): number local value = buffer.readi32(activeBuffer, bufferOffset) bufferOffset += 4 return value end
local function writeS32(value: number) buffer.writei32(activeBuffer, bufferOffset, value) bufferOffset += 4 end
local function readU8(): number local value = buffer.readu8(activeBuffer, bufferOffset) bufferOffset += 1 return value end
local function writeU8(value: number) buffer.writeu8(activeBuffer, bufferOffset, value) bufferOffset += 1 end
local function readU16(): number local value = buffer.readu16(activeBuffer, bufferOffset) bufferOffset += 2 return value end
local function writeU16(value: number) buffer.writeu16(activeBuffer, bufferOffset, value) bufferOffset += 2 end
local function readU24(): number local value = buffer.readbits(activeBuffer, bufferOffset*8, 24) bufferOffset += 3 return value end
local function writeU24(value: number) buffer.writebits(activeBuffer, bufferOffset*8, 24, value) bufferOffset += 3 end
local function readU32(): number local value = buffer.readu32(activeBuffer, bufferOffset) bufferOffset += 4 return value end
local function writeU32(value: number) buffer.writeu32(activeBuffer, bufferOffset, value) bufferOffset += 4 end
local function readF32(): number local value = buffer.readf32(activeBuffer, bufferOffset) bufferOffset += 4 return value end
local function writeF32(value: number) buffer.writef32(activeBuffer, bufferOffset, value) bufferOffset += 4 end
local function readF64(): number local value = buffer.readf64(activeBuffer, bufferOffset) bufferOffset += 8 return value end
local function writeF64(value: number) buffer.writef64(activeBuffer, bufferOffset, value) bufferOffset += 8 end
local function readString(length: number) local value = buffer.readstring(activeBuffer, bufferOffset, length) bufferOffset += length return value end
local function writeString(value: string) buffer.writestring(activeBuffer, bufferOffset, value) bufferOffset += #value end
local function readBuffer(length: number) local value = buffer.create(length) buffer.copy(value, 0, activeBuffer, bufferOffset, length) bufferOffset += length return value end
local function writeBuffer(value: buffer) buffer.copy(activeBuffer, bufferOffset, value) bufferOffset += buffer.len(value) end
local function readInstance() instancesOffset += 1 return instances[instancesOffset] end
local function writeInstance(value) instancesOffset += 1 instances[instancesOffset] = value end

local function readF16(): number
	local bitOffset = bufferOffset*8
	bufferOffset += 2
	local mantissa = buffer.readbits(activeBuffer, bitOffset + 0, 10)
	local exponent = buffer.readbits(activeBuffer, bitOffset + 10, 5)
	local sign = buffer.readbits(activeBuffer, bitOffset + 15, 1)
	if mantissa == 0b0000000000 then
		if exponent == 0b00000 then return 0 end
		if exponent == 0b11111 then return if sign == 0 then math.huge else -math.huge end
	elseif exponent == 0b11111 then return 0/0 end
	if sign == 0 then
		return (mantissa/1024 + 1)*2^(exponent - 15)
	else
		return -(mantissa/1024 + 1)*2^(exponent - 15)
	end
end
local function writeF16(value: number)
	local bitOffset = bufferOffset*8
	bufferOffset += 2
	if value == 0 then
		buffer.writebits(activeBuffer, bitOffset, 16, 0b0_00000_0000000000)
	elseif value >= 65520 then
		buffer.writebits(activeBuffer, bitOffset, 16, 0b0_11111_0000000000)
	elseif value <= -65520 then
		buffer.writebits(activeBuffer, bitOffset, 16, 0b1_11111_0000000000)
	elseif value ~= value then
		buffer.writebits(activeBuffer, bitOffset, 16, 0b0_11111_0000000001)
	else
		local sign = 0
		if value < 0 then sign = 1 value = -value end
		local mantissa, exponent = math.frexp(value)
		buffer.writebits(activeBuffer, bitOffset + 0, 10, mantissa*2048 - 1023.5)
		buffer.writebits(activeBuffer, bitOffset + 10, 5, exponent + 14)
		buffer.writebits(activeBuffer, bitOffset + 15, 1, sign)
	end
end

local function readF24(): number
	local bitOffset = bufferOffset*8
	bufferOffset += 3
	local mantissa = buffer.readbits(activeBuffer, bitOffset + 0, 17)
	local exponent = buffer.readbits(activeBuffer, bitOffset + 17, 6)
	local sign = buffer.readbits(activeBuffer, bitOffset + 23, 1)
	if mantissa == 0b00000000000000000 then
		if exponent == 0b000000 then return 0 end
		if exponent == 0b111111 then return if sign == 0 then math.huge else -math.huge end
	elseif exponent == 0b111111 then return 0/0 end
	if sign == 0 then
		return (mantissa/131072 + 1)*2^(exponent - 31)
	else
		return -(mantissa/131072 + 1)*2^(exponent - 31)
	end
end
local function writeF24(value: number)
	local bitOffset = bufferOffset*8
	bufferOffset += 3
	if value == 0 then
		buffer.writebits(activeBuffer, bitOffset, 24, 0b0_000000_00000000000000000) 
	elseif value >= 4294959104 then
		buffer.writebits(activeBuffer, bitOffset, 24, 0b0_111111_00000000000000000)
	elseif value <= -4294959104 then
		buffer.writebits(activeBuffer, bitOffset, 24, 0b1_111111_00000000000000000)
	elseif value ~= value then
		buffer.writebits(activeBuffer, bitOffset, 24, 0b0_111111_00000000000000001)
	else
		local sign = 0
		if value < 0 then sign = 1 value = -value end
		local mantissa, exponent = math.frexp(value)
		buffer.writebits(activeBuffer, bitOffset + 0, 17, mantissa*262144 - 131071.5)
		buffer.writebits(activeBuffer, bitOffset + 17, 6, exponent + 30)
		buffer.writebits(activeBuffer, bitOffset + 23, 1, sign)
	end
end


-- Read/writes.
dataTypes.Any = "Any" :: any
reads.Any = function() return anyreads[readU8()]() end
writes.Any = function(value: any)
	local write = anywrites[typeof(value)]
	if not write then error("Data type '"..typeof(value).."' not supported.") end
	write(value)
end

dataTypes.Nil = ("Nil" :: any) :: nil
reads.Nil = function() return nil end
writes.Nil = function(value: nil) end

dataTypes.NumberS8 = ("NumberS8" :: any) :: number
reads.NumberS8 = function() return readS8() end
writes.NumberS8 = function(value: number) allocate(1) writeS8(value) end

dataTypes.NumberS16 = ("NumberS16" :: any) :: number
reads.NumberS16 = function() return readS16() end 
writes.NumberS16 = function(value: number) allocate(2) writeS16(value) end

dataTypes.NumberS24 = ("NumberS24" :: any) :: number
reads.NumberS24 = function() return readS24() end 
writes.NumberS24 = function(value: number) allocate(3) writeS24(value) end

dataTypes.NumberS32 = ("NumberS32" :: any) :: number
reads.NumberS32 = function() return readS32() end 
writes.NumberS32 = function(value: number) allocate(4) writeS32(value) end

dataTypes.NumberU8 = ("NumberU8" :: any) :: number
reads.NumberU8 = function() return readU8() end
writes.NumberU8 = function(value: number) allocate(1) writeU8(value) end

dataTypes.NumberU16 = ("NumberU16" :: any) :: number
reads.NumberU16 = function() return readU16() end
writes.NumberU16 = function(value: number) allocate(2) writeU16(value) end

dataTypes.NumberU24 = ("NumberU24" :: any) :: number
reads.NumberU24 = function() return readU24() end 
writes.NumberU24 = function(value: number) allocate(3) writeU24(value) end

dataTypes.NumberU32 = ("NumberU32" :: any) :: number
reads.NumberU32 = function() return readU32() end 
writes.NumberU32 = function(value: number) allocate(4) writeU32(value) end

dataTypes.NumberF16 = ("NumberF16" :: any) :: number
reads.NumberF16 = function() return readF16() end
writes.NumberF16 = function(value: number) allocate(2) writeF16(value) end

dataTypes.NumberF24 = ("NumberF24" :: any) :: number
reads.NumberF24 = function() return readF24() end
writes.NumberF24 = function(value: number) allocate(3) writeF24(value) end

dataTypes.NumberF32 = ("NumberF32" :: any) :: number
reads.NumberF32 = function() return readF32() end
writes.NumberF32 = function(value: number) allocate(4) writeF32(value) end

dataTypes.NumberF64 = ("NumberF64" :: any) :: number
reads.NumberF64 = function() return readF64() end
writes.NumberF64 = function(value: number) allocate(8) writeF64(value) end

dataTypes.String = ("String" :: any) :: string
reads.String = function() return readString(readU8()) end
writes.String = function(value: string) local length = #value allocate(1 + length) writeU8(length) writeString(value) end

dataTypes.StringLong = ("StringLong" :: any) :: string
reads.StringLong = function() return readString(readU16()) end
writes.StringLong = function(value: string) local length = #value allocate(2 + length) writeU16(length) writeString(value) end

dataTypes.Buffer = ("Buffer" :: any) :: buffer
reads.Buffer = function() return readBuffer(readU8()) end
writes.Buffer = function(value: buffer) local length = buffer.len(value) allocate(1 + length) writeU8(length) writeBuffer(value) end

dataTypes.BufferLong = ("BufferLong" :: any) :: buffer
reads.BufferLong = function() return readBuffer(readU16()) end
writes.BufferLong = function(value: buffer) local length = buffer.len(value) allocate(2 + length) writeU16(length) writeBuffer(value) end

dataTypes.Instance = ("Instance" :: any) :: Instance
reads.Instance = function() return readInstance() end
writes.Instance = function(value: Instance) writeInstance(value) end

dataTypes.Boolean8 = ("Boolean8" :: any) :: boolean
reads.Boolean8 = function() return readU8() == 1 end
writes.Boolean8 = function(value: boolean) allocate(1) writeU8(if value then 1 else 0) end

dataTypes.NumberRange = ("NumberRange" :: any) :: NumberRange
reads.NumberRange = function() return NumberRange.new(readF32(), readF32()) end
writes.NumberRange = function(value: NumberRange) allocate(8) writeF32(value.Min) writeF32(value.Max) end

dataTypes.BrickColor = ("BrickColor" :: any) :: BrickColor
reads.BrickColor = function() return BrickColor.new(readU16()) end
writes.BrickColor = function(value: BrickColor) allocate(2) writeU16(value.Number) end

dataTypes.Color3 = ("Color3" :: any) :: Color3
reads.Color3 = function() return Color3.fromRGB(readU8(), readU8(), readU8()) end
writes.Color3 = function(value: Color3) allocate(3) writeU8(value.R*255 + 0.5)  writeU8(value.G*255 + 0.5)  writeU8(value.B*255 + 0.5) end

dataTypes.UDim = ("UDim" :: any) :: UDim
reads.UDim = function() return UDim.new(readS16()/1000, readS16()) end
writes.UDim = function(value: UDim) allocate(4) writeS16(value.Scale*1000) writeS16(value.Offset) end

dataTypes.UDim2 = ("UDim2" :: any) :: UDim2
reads.UDim2 = function() return UDim2.new(readS16()/1000, readS16(), readS16()/1000, readS16()) end
writes.UDim2 = function(value: UDim2) allocate(8) writeS16(value.X.Scale*1000) writeS16(value.X.Offset) writeS16(value.Y.Scale*1000) writeS16(value.Y.Offset) end

dataTypes.Rect = ("Rect" :: any) :: Rect
reads.Rect = function() return Rect.new(readF32(), readF32(), readF32(), readF32()) end
writes.Rect = function(value: Rect) allocate(16) writeF32(value.Min.X) writeF32(value.Min.Y) writeF32(value.Max.X) writeF32(value.Max.Y) end

dataTypes.Vector2S16 = ("Vector2S16" :: any) :: Vector2
reads.Vector2S16 = function() return Vector2.new(readS16(), readS16()) end
writes.Vector2S16 = function(value: Vector2) allocate(4) writeS16(value.X) writeS16(value.Y) end

dataTypes.Vector2F24 = ("Vector2F24" :: any) :: Vector2
reads.Vector2F24 = function() return Vector2.new(readF24(), readF24()) end
writes.Vector2F24 = function(value: Vector2) allocate(6) writeF24(value.X) writeF24(value.Y) end

dataTypes.Vector2F32 = ("Vector2F32" :: any) :: Vector2
reads.Vector2F32 = function() return Vector2.new(readF32(), readF32()) end
writes.Vector2F32 = function(value: Vector2) allocate(8) writeF32(value.X) writeF32(value.Y) end

dataTypes.Vector3S16 = ("Vector3S16" :: any) :: Vector3
reads.Vector3S16 = function() return vector.create(readS16(), readS16(), readS16()) end
writes.Vector3S16 = function(value: Vector3) allocate(6) writeS16(value.X) writeS16(value.Y) writeS16(value.Z) end

dataTypes.Vector3F24 = ("Vector3F24" :: any) :: Vector3
reads.Vector3F24 = function() return vector.create(readF24(), readF24(), readF24()) end
writes.Vector3F24 = function(value: Vector3) allocate(9) writeF24(value.X) writeF24(value.Y) writeF24(value.Z) end

dataTypes.Vector3F32 = ("Vector3F32" :: any) :: Vector3
reads.Vector3F32 = function() return vector.create(readF32(), readF32(), readF32()) end
writes.Vector3F32 = function(value: Vector3) allocate(12) writeF32(value.X) writeF32(value.Y) writeF32(value.Z) end

dataTypes.NumberU4 = ("NumberU4" :: any) :: {number}
reads.NumberU4 = function()
	local bitOffset = bufferOffset*8
	bufferOffset += 1
	return {
		buffer.readbits(activeBuffer, bitOffset + 0, 4),
		buffer.readbits(activeBuffer, bitOffset + 4, 4)
	}
end
writes.NumberU4 = function(value: {number})
	allocate(1)
	local bitOffset = bufferOffset*8
	bufferOffset += 1
	buffer.writebits(activeBuffer, bitOffset + 0, 4, value[1])
	buffer.writebits(activeBuffer, bitOffset + 4, 4, value[2])
end

dataTypes.BooleanNumber = ("BooleanNumber" :: any) :: {Boolean: boolean, Number: number}
reads.BooleanNumber = function()
	local bitOffset = bufferOffset*8
	bufferOffset += 1
	return {
		Boolean = buffer.readbits(activeBuffer, bitOffset + 0, 1) == 1,
		Number = buffer.readbits(activeBuffer, bitOffset + 1, 7),
	}
end
writes.BooleanNumber = function(value: {Boolean: boolean, Number: number})
	allocate(1)
	local bitOffset = bufferOffset*8
	bufferOffset += 1
	buffer.writebits(activeBuffer, bitOffset + 0, 1, if value.Boolean then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 1, 7, value.Number)
end

dataTypes.Boolean1 = ("Boolean1" :: any) :: {boolean}
reads.Boolean1 = function()
	local bitOffset = bufferOffset*8
	bufferOffset += 1
	return {
		buffer.readbits(activeBuffer, bitOffset + 0, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 1, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 2, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 3, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 4, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 5, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 6, 1) == 1,
		buffer.readbits(activeBuffer, bitOffset + 7, 1) == 1,
	}
end
writes.Boolean1 = function(value: {boolean})
	allocate(1)
	local bitOffset = bufferOffset*8
	bufferOffset += 1
	buffer.writebits(activeBuffer, bitOffset + 0, 1, if value[1] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 1, 1, if value[2] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 2, 1, if value[3] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 3, 1, if value[4] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 4, 1, if value[5] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 5, 1, if value[6] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 6, 1, if value[7] then 1 else 0)
	buffer.writebits(activeBuffer, bitOffset + 7, 1, if value[8] then 1 else 0)
end

dataTypes.CFrameF24U8 = ("CFrameF24U8" :: any) :: CFrame
reads.CFrameF24U8 = function()
	return CFrame.Angles(readU8()/40.58451048843331, readU8()/40.58451048843331, readU8()/40.58451048843331)
		+ vector.create(readF24(), readF24(), readF24())
end
writes.CFrameF24U8 = function(value: CFrame)
	local rx, ry, rz = value:ToEulerAnglesXYZ()
	allocate(12)
	writeU8(rx*40.58451048843331 + 0.5) writeU8(ry*40.58451048843331 + 0.5) writeU8(rz*40.58451048843331 + 0.5)
	writeF24(value.X) writeF24(value.Y) writeF24(value.Z)
end

dataTypes.CFrameF32U8 = ("CFrameF32U8" :: any) :: CFrame
reads.CFrameF32U8 = function()
	return CFrame.fromEulerAnglesXYZ(readU8()/40.58451048843331, readU8()/40.58451048843331, readU8()/40.58451048843331)
		+ vector.create(readF32(), readF32(), readF32())
end
writes.CFrameF32U8 = function(value: CFrame)
	local rx, ry, rz = value:ToEulerAnglesXYZ()
	allocate(15)
	writeU8(rx*40.58451048843331 + 0.5) writeU8(ry*40.58451048843331 + 0.5) writeU8(rz*40.58451048843331 + 0.5)
	writeF32(value.X) writeF32(value.Y) writeF32(value.Z)
end

dataTypes.CFrameF32U16 = ("CFrameF32U16" :: any) :: CFrame
reads.CFrameF32U16 = function()
	return CFrame.fromEulerAnglesXYZ(readU16()/10430.219195527361, readU16()/10430.219195527361, readU16()/10430.219195527361)
		+ vector.create(readF32(), readF32(), readF32())
end
writes.CFrameF32U16 = function(value: CFrame)
	local rx, ry, rz = value:ToEulerAnglesXYZ()
	allocate(18)
	writeU16(rx*10430.219195527361 + 0.5) writeU16(ry*10430.219195527361 + 0.5) writeU16(rz*10430.219195527361 + 0.5)
	writeF32(value.X) writeF32(value.Y) writeF32(value.Z)
end

dataTypes.Region3 = ("Region3" :: any) :: Region3
reads.Region3 = function()
	return Region3.new(
		vector.create(readF32(), readF32(), readF32()),
		vector.create(readF32(), readF32(), readF32())
	)
end
writes.Region3 = function(value: Region3)
	local halfSize = value.Size/2
	local position = value.CFrame.Position
	local minimum = position - halfSize
	local maximum = position + halfSize
	allocate(24)
	writeF32(minimum.X) writeF32(minimum.Y) writeF32(minimum.Z)
	writeF32(maximum.X) writeF32(maximum.Y) writeF32(maximum.Z)
end

dataTypes.NumberSequence = ("NumberSequence" :: any) :: NumberSequence
reads.NumberSequence = function()
	local length = readU8()
	local keypoints = table.create(length)
	for index = 1, length, 1 do
		keypoints[index] = NumberSequenceKeypoint.new(readU8()/255, readU8()/255, readU8()/255)
	end
	return NumberSequence.new(keypoints)
end
writes.NumberSequence = function(value: NumberSequence)
	local length = #value.Keypoints
	allocate(1 + length*3)
	writeU8(length)
	for index, keypoint in value.Keypoints do
		writeU8(keypoint.Time*255 + 0.5) writeU8(keypoint.Value*255 + 0.5) writeU8(keypoint.Envelope*255 + 0.5)
	end
end

dataTypes.ColorSequence = ("ColorSequence" :: any) :: ColorSequence
reads.ColorSequence = function()
	local length = readU8()
	local keypoints = table.create(length)
	for index = 1, length, 1 do
		keypoints[index] = ColorSequenceKeypoint.new(readU8()/255, Color3.fromRGB(readU8(), readU8(), readU8()))
	end
	return ColorSequence.new(keypoints)
end
writes.ColorSequence = function(value: ColorSequence)
	local length = #value.Keypoints
	allocate(1 + length*4)
	writeU8(length)
	for index, keypoint in value.Keypoints do
		writeU8(keypoint.Time*255 + 0.5)
		writeU8(keypoint.Value.R*255 + 0.5) writeU8(keypoint.Value.G*255 + 0.5) writeU8(keypoint.Value.B*255 + 0.5)
	end
end

local characterIndices = {}
local characters = require(script.Characters)
for index, value in characters do characterIndices[value] = index end
local characterBits = math.ceil(math.log(#characters + 1, 2))
local characterBytes = characterBits/8
dataTypes.Characters = ("Characters" :: any) :: string
reads.Characters = function()
	local length = readU8()
	local characterArray = table.create(length)
	local bitOffset = bufferOffset*8
	bufferOffset += math.ceil(length*characterBytes)
	for index = 1, length do
		table.insert(characterArray, characters[buffer.readbits(activeBuffer, bitOffset, characterBits)])
		bitOffset += characterBits
	end
	return table.concat(characterArray)
end
writes.Characters = function(value: string)
	local length = #value
	local bytes = math.ceil(length*characterBytes)
	allocate(1 + bytes)
	writeU8(length)
	local bitOffset = bufferOffset*8
	for index = 1, length do
		buffer.writebits(activeBuffer, bitOffset, characterBits, characterIndices[value:sub(index, index)])
		bitOffset += characterBits
	end
	bufferOffset += bytes
end

local enumIndices = {}
local enums = require(script.Enums)
for index, static in enums do enumIndices[static] = index end
dataTypes.EnumItem = ("EnumItem" :: any) :: EnumItem
reads.EnumItem = function() return enums[readU8()]:FromValue(readU16()) end
writes.EnumItem = function(value: EnumItem) allocate(3) writeU8(enumIndices[value.EnumType]) writeU16(value.Value) end

local staticIndices = {}
local statics = require(script.Static1)
for index, static in statics do staticIndices[static] = index end
dataTypes.Static1 = ("Static1" :: any) :: any
reads.Static1 = function() return statics[readU8()] end
writes.Static1 = function(value: any) allocate(1) writeU8(staticIndices[value] or 0) end

local staticIndices = {}
local statics = require(script.Static2)
for index, static in statics do staticIndices[static] = index end
dataTypes.Static2 = ("Static2" :: any) :: any
reads.Static2 = function() return statics[readU8()] end
writes.Static2 = function(value: any) allocate(1) writeU8(staticIndices[value] or 0) end

local staticIndices = {}
local statics = require(script.Static3)
for index, static in statics do staticIndices[static] = index end
dataTypes.Static3 = ("Static3" :: any) :: any
reads.Static3 = function() return statics[readU8()] end
writes.Static3 = function(value: any) allocate(1) writeU8(staticIndices[value] or 0) end


-- Any Types
anyreads[0] = function() return nil end
anywrites["nil"] = function(value: nil) allocate(1) writeU8(0) end

anyreads[1] = function() return -readU8() end
anyreads[2] = function() return -readU16() end
anyreads[3] = function() return -readU24() end
anyreads[4] = function() return -readU32() end
anyreads[5] = function() return readU8() end
anyreads[6] = function() return readU16() end
anyreads[7] = function() return readU24() end
anyreads[8] = function() return readU32() end
anyreads[9] = function() return readF32() end
anyreads[10] = function() return readF64() end
anywrites.number = function(value: number)
	if value%1 == 0 then
		if value < 0 then
			if value > -256 then
				allocate(2) writeU8(1) writeU8(-value)
			elseif value > -65536 then
				allocate(3) writeU8(2) writeU16(-value)
			elseif value > -16777216 then
				allocate(4) writeU8(3) writeU24(-value)
			elseif value > -4294967296 then
				allocate(5) writeU8(4) writeU32(-value)
			else
				allocate(9) writeU8(10) writeF64(value)
			end
		else
			if value < 256 then
				allocate(2) writeU8(5) writeU8(value)
			elseif value < 65536 then
				allocate(3) writeU8(6) writeU16(value)
			elseif value < 16777216 then
				allocate(4) writeU8(7) writeU24(value)
			elseif value < 4294967296 then
				allocate(5) writeU8(8) writeU32(value)
			else
				allocate(9) writeU8(10) writeF64(value)
			end
		end
	elseif value > -1048576 and value < 1048576 then
		allocate(5) writeU8(9) writeF32(value)
	else
		allocate(9) writeU8(10) writeF64(value)
	end
end

anyreads[11] = function() return readString(readU8()) end
anywrites.string = function(value: string) local length = #value allocate(2 + length) writeU8(11) writeU8(length) writeString(value) end

anyreads[12] = function() return readBuffer(readU8()) end
anywrites.buffer = function(value: buffer) local length = buffer.len(value) allocate(2 + length) writeU8(12) writeU8(length) writeBuffer(value) end

anyreads[13] = function() return readInstance() end
anywrites.Instance = function(value: Instance) allocate(1) writeU8(13) writeInstance(value) end

anyreads[14] = function() return readU8() == 1 end
anywrites.boolean = function(value: boolean) allocate(2) writeU8(14) writeU8(if value then 1 else 0) end

anyreads[15] = function() return NumberRange.new(readF32(), readF32()) end
anywrites.NumberRange = function(value: NumberRange) allocate(9) writeU8(15) writeF32(value.Min) writeF32(value.Max) end

anyreads[16] = function() return BrickColor.new(readU16()) end
anywrites.BrickColor = function(value: BrickColor) allocate(3) writeU8(16) writeU16(value.Number) end

anyreads[17] = function() return Color3.fromRGB(readU8(), readU8(), readU8()) end
anywrites.Color3 = function(value: Color3) allocate(4) writeU8(17) writeU8(value.R*255 + 0.5)  writeU8(value.G*255 + 0.5)  writeU8(value.B*255 + 0.5) end

anyreads[18] = function() return UDim.new(readS16()/1000, readS16()) end
anywrites.UDim = function(value: UDim) allocate(5) writeU8(18) writeS16(value.Scale*1000) writeS16(value.Offset) end

anyreads[19] = function() return UDim2.new(readS16()/1000, readS16(), readS16()/1000, readS16()) end
anywrites.UDim2 = function(value: UDim2) allocate(9) writeU8(19) writeS16(value.X.Scale*1000) writeS16(value.X.Offset) writeS16(value.Y.Scale*1000) writeS16(value.Y.Offset) end

anyreads[20] = function() return Rect.new(readF32(), readF32(), readF32(), readF32()) end
anywrites.Rect = function(value: Rect) allocate(17) writeU8(20) writeF32(value.Min.X) writeF32(value.Min.Y) writeF32(value.Max.X) writeF32(value.Max.Y) end

anyreads[21] = function() return Vector2.new(readF32(), readF32()) end
anywrites.Vector2 = function(value: Vector2) allocate(9) writeU8(21) writeF32(value.X) writeF32(value.Y) end

anyreads[22] = function() return vector.create(readF32(), readF32(), readF32()) end
anywrites.Vector3 = function(value: Vector3) allocate(13) writeU8(22) writeF32(value.X) writeF32(value.Y) writeF32(value.Z) end

anyreads[23] = function()
	return CFrame.Angles(readU16()/10430.219195527361, readU16()/10430.219195527361, readU16()/10430.219195527361)
		+ vector.create(readF32(), readF32(), readF32())
end
anywrites.CFrame = function(value: CFrame)
	local rx, ry, rz = value:ToOrientation()
	allocate(19)
	writeU8(23)
	writeU16(rx*10430.219195527361 + 0.5) writeU16(ry*10430.219195527361 + 0.5) writeU16(rz*10430.219195527361 + 0.5)
	writeF32(value.X) writeF32(value.Y) writeF32(value.Z)
end

anyreads[24] = function()
	return Region3.new(
		vector.create(readF32(), readF32(), readF32()),
		vector.create(readF32(), readF32(), readF32())
	)
end
anywrites.Region3 = function(value: Region3)
	local halfSize = value.Size/2
	local position = value.CFrame.Position
	local minimum = position - halfSize
	local maximum = position + halfSize
	allocate(25)
	writeU8(24)
	writeF32(minimum.X) writeF32(minimum.Y) writeF32(minimum.Z)
	writeF32(maximum.X) writeF32(maximum.Y) writeF32(maximum.Z)
end

anyreads[25] = function()
	local length = readU8()
	local keypoints = table.create(length)
	for index = 1, length, 1 do
		keypoints[index] = NumberSequenceKeypoint.new(readU8()/255, readU8()/255, readU8()/255)
	end
	return NumberSequence.new(keypoints)
end
anywrites.NumberSequence = function(value: NumberSequence)
	local length = #value.Keypoints
	allocate(2 + length*3)
	writeU8(25)
	writeU8(length)
	for index, keypoint in value.Keypoints do
		writeU8(keypoint.Time*255 + 0.5) writeU8(keypoint.Value*255 + 0.5) writeU8(keypoint.Envelope*255 + 0.5)
	end
end

anyreads[26] = function()
	local length = readU8()
	local keypoints = table.create(length)
	for index = 1, length, 1 do
		keypoints[index] = ColorSequenceKeypoint.new(readU8()/255, Color3.fromRGB(readU8(), readU8(), readU8()))
	end
	return ColorSequence.new(keypoints)
end
anywrites.ColorSequence = function(value: ColorSequence)
	local length = #value.Keypoints
	allocate(2 + length*4)
	writeU8(26)
	writeU8(length)
	for index, keypoint in value.Keypoints do
		writeU8(keypoint.Time*255 + 0.5)
		writeU8(keypoint.Value.R*255 + 0.5) writeU8(keypoint.Value.G*255 + 0.5) writeU8(keypoint.Value.B*255 + 0.5)
	end
end

anyreads[27] = function()
	return enums[readU8()]:FromValue(readU16())
end
anywrites.EnumItem = function(value: EnumItem)
	allocate(4)
	writeU8(27)
	writeU8(enumIndices[value.EnumType])
	writeU16(value.Value)
end

anyreads[28] = function()
	local value = {}
	while true do
		local typeId = readU8()
		if typeId == 0 then return value else value[anyreads[typeId]()] = anyreads[readU8()]() end
	end
end
anywrites.table = function(value: {[any]: any})
	allocate(1)
	writeU8(28)
	for index, value in value do anywrites[typeof(index)](index) anywrites[typeof(value)](value) end
	allocate(1)
	writeU8(0)
end


return {
	Import = function(cursor: Cursor)
		activeCursor = cursor
		activeBuffer = cursor.Buffer
		bufferLength = cursor.BufferLength
		bufferOffset = cursor.BufferOffset
		instances = cursor.Instances
		instancesOffset = cursor.InstancesOffset
	end,
	
	Export = function()
		activeCursor.BufferLength = bufferLength
		activeCursor.BufferOffset = bufferOffset
		activeCursor.InstancesOffset = instancesOffset
		return activeCursor
	end,
	
	Truncate = function()
		local truncatedBuffer = buffer.create(bufferOffset)
		buffer.copy(truncatedBuffer, 0, activeBuffer, 0, bufferOffset)
		if instancesOffset == 0 then return truncatedBuffer else return truncatedBuffer, instances end
	end,
	
	Ended = function()
		return bufferOffset >= bufferLength
	end,
	
	DataTypes = dataTypes,
	Reads = reads,
	Writes = writes,
}