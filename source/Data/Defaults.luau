--!optimize 2

-- Services.
local CollectionService = game:GetService("CollectionService")

-- Initialize defaults table with default defaults.
local defaults = {
	Time = 1,
	
	EasingDirection = "In",
	
	DelayTime = 0,
	Reverses = false,
	RepeatCount = 0,
	
	FPS = nil
}

-- Merge user defaults.
local userDefaults = CollectionService:GetTagged("TweenDefaults")[1]
if userDefaults then
	userDefaults = require(userDefaults)
	if type(userDefaults) == "table" then
		local options = {
			Time = true,
			
			EasingDirection = true,
			
			DelayTime = true,
			Reverses = true,
			RepeatCount = true,
			
			FPS = true
		}
		for key in userDefaults do
			if options[key] then defaults[key] = userDefaults[key] end
		end
	end
end

-- Remove falses.
for key, value in defaults do
	if value == false then
		defaults[key] = nil
	end
end

-- Remove DelayTime if 0.
if defaults.DelayTime == 0 then defaults.DelayTime = nil end

-- Invert time.
defaults.InverseTime = 1/defaults.Time
defaults.Time = nil

-- Convert FPS to interval.
local fps = defaults.FPS
if fps then
	defaults.Interval = 1/fps
	defaults.FPS = nil
end

-- Return final defaults.
return defaults