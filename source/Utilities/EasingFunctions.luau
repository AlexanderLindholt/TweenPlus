--!optimize 2
--!native

-- Elastic constants.
local elasticInP = 0.3
local elasticInA = 1.0
local elasticInS = elasticInP*0.25
local elasticOutP = 0.3
local elasticOutA = 1.0
local elasticOutS = elasticOutP*0.25
local elasticInOutP = 0.45
local elasticInOutA = 1.0
local elasticInOutS = elasticInOutP*0.25

-- Back constants.
local backS = 1.70158
local backInOutS = backS*1.525

-- Linear easing.
local function linear(alpha)
	return alpha
end

-- Quad easing.
local function inQuad(alpha)
	return alpha*alpha
end
local function outQuad(alpha)
	return alpha*(2 - alpha)
end
local function inOutQuad(alpha)
	alpha *= 2
	return if alpha < 1 then
		0.5*alpha*alpha
		else
		1 - 0.5*(2 - alpha)^2
end
local function outInQuad(alpha)
	return if alpha < 0.5 then
		0.5*outQuad(alpha*2)
		else
		0.5*inQuad((alpha - 0.5)*2) + 0.5
end

-- Cubic easing.
local function inCubic(alpha)
	return alpha^3
end
local function outCubic(alpha)
	return 1 + (alpha - 1)^3
end
local function inOutCubic(alpha)
	alpha *= 2
	return if alpha < 1 then
		0.5*alpha^3
		else
		0.5*((alpha - 2)^3 + 2)
end
local function outInCubic(alpha)
	return if alpha < 0.5 then
		0.5*((2*alpha - 1)^3 + 1)
		else
		0.5*(2*alpha - 1)^3 + 0.5
end

-- Quart easing.
local function inQuart(alpha)
	return alpha^4
end
local function outQuart(alpha)
	return 1 - (alpha - 1)^4
end
local function inOutQuart(alpha)
	alpha *= 2
	return if alpha < 1 then
		0.5*alpha^4
		else
		-0.5*((alpha - 2)^4 - 2)
end
local function outInQuart(alpha)
	return if alpha < 0.5 then
		0.5*(1 - (alpha*2 - 1)^4)
		else
		0.5*((2*alpha - 1)^4) + 0.5
end

-- Quint easing.
local function inQuint(alpha)
	return alpha^5
end
local function outQuint(alpha)
	return 1 + (alpha - 1)^5
end
local function inOutQuint(alpha)
	alpha *= 2
	return if alpha < 1 then
		0.5*alpha^5
		else
		0.5*((alpha - 2)^5 + 2)
end
local function outInQuint(alpha)
	return if alpha < 0.5 then
		0.5*((2*alpha - 1)^5 + 1)
		else
		0.5*(2*alpha - 1)^5 + 0.5
end

-- Sine easing.
local function inSine(alpha)
	return 1 - math.cos(alpha*math.pi*0.5)
end
local function outSine(alpha)
	return math.sin(alpha*math.pi*0.5)
end
local function inOutSine(alpha)
	return 0.5*(1 - math.cos(math.pi*alpha))
end
local function outInSine(alpha)
	return if alpha < 0.5 then
		0.5*math.sin(alpha*math.pi)
		else
		0.5*(1 - math.cos((2*alpha - 1)*math.pi*0.5)) + 0.5
end

-- Exponential easing.
local function inExponential(alpha)
	return if alpha == 0 then
		0
		else
		2^(10*(alpha - 1))
end
local function outExponential(alpha)
	return if alpha == 1 then
		1
		else
		1 - 2^(-10*alpha)
end
local function inOutExponential(alpha)
	alpha *= 2
	return if alpha < 1 then
		0.5*2^(10*(alpha - 1))
		else
		0.5*(2 - 2^(-10*(alpha - 1)))
end
local function outInExponential(alpha)
	return if alpha < 0.5 then
		0.5*outExponential(alpha*2)
		else
		0.5*(inExponential(2*alpha - 1) + 1)
end

-- Circular easing.
local function inCircular(alpha)
	return 1 - math.sqrt(1 - alpha*alpha)
end
local function outCircular(alpha)
	return math.sqrt(1 - (alpha - 1)^2)
end
local function inOutCircular(alpha)
	alpha *= 2
	return if alpha < 1 then
		0.5*(1 - math.sqrt(1 - alpha*alpha))
		else
		0.5*(math.sqrt(1 - (alpha - 2)^2) + 1)
end
local function outInCircular(alpha)
	return if alpha < 0.5 then
		0.5*outCircular(alpha*2)
		else
		0.5*(inCircular(2*alpha - 1) + 1)
end

-- Elastic easing.
local function inElastic(alpha)
	local s = if elasticInA < 1 then
		elasticInP*0.25
	else
		elasticInP/(2*math.pi)*math.asin(1/elasticInA)
	local t = alpha - 1
	return -elasticInA*2^(10*t)*math.sin((t - s)*(2*math.pi/elasticInP))
end
local function outElastic(alpha)
	local s = if elasticOutA < 1 then
		elasticOutP*0.25
	else
		elasticOutP/(2*math.pi)*math.asin(1/elasticOutA)
	return elasticOutA*2^(-10*alpha)*math.sin((alpha - s)*(2*math.pi/elasticOutP)) + 1
end
local function inOutElastic(alpha)
	local s = if elasticInOutA < 1 then
		elasticInOutP*0.25
	else
		elasticInOutP/(2*math.pi)*math.asin(1/elasticInOutA)
	alpha *= 2
	local t = alpha - 1
	return if alpha < 1 then
		-0.5*elasticInOutA*2^(10*t)*math.sin((t - s)*(2*math.pi/elasticInOutP))
		else
		0.5*elasticInOutA*2^(-10*t)*math.sin((t - s)*(2*math.pi/elasticInOutP)) + 1
end
local function outInElastic(alpha)
	return if alpha < 0.5 then
		0.5*outElastic(alpha*2)
		else
		0.5*(inElastic(2*alpha - 1) + 1)
end

-- Back easing.
local function inBack(alpha)
	return alpha*alpha*((backS + 1)*alpha - backS)
end
local function outBack(alpha)
	local a = alpha - 1
	return a*a*((backS + 1)*a + backS) + 1
end
local function inOutBack(alpha)
	alpha *= 2
	if alpha < 1 then
		return 0.5*alpha*alpha*((backInOutS + 1)*alpha - backInOutS)
	else
		alpha -= 2
		return 0.5*(alpha*alpha*((backInOutS + 1)*alpha + backInOutS) + 2)
	end
end
local function outInBack(alpha)
	return if alpha < 0.5 then
		0.5*outBack(alpha*2)
		else
		0.5*(inBack(2*alpha - 1) + 1)
end

-- Bounce easing.
local function outBounce(alpha)
	return if alpha < 1/2.75 then
		7.5625*alpha*alpha
		elseif alpha < 2/2.75 then
		7.5625*(alpha - 1.5/2.75)^2 + 0.75
		elseif alpha < 2.5/2.75 then
		7.5625*(alpha - 2.25/2.75)^2 + 0.9375
		else
		7.5625*(alpha - 2.625/2.75)^2 + 0.984375
end
local function inBounce(alpha)
	return 1 - outBounce(1 - alpha)
end
local function inOutBounce(alpha)
	return if alpha < 0.5 then
		0.5*inBounce(2*alpha)
		else
		0.5*outBounce(2*alpha - 1) + 0.5
end
local function outInBounce(alpha)
	return if alpha < 0.5 then
		0.5*outBounce(2*alpha)
		else
		0.5*inBounce(2*alpha - 1) + 0.5
end

-- Map and return easing functions.
return {
	Linear = linear,
	Quad = {
		In = inQuad,
		Out = outQuad,
		InOut = inOutQuad,
		OutIn = outInQuad,
	},
	Cubic = {
		In = inCubic,
		Out = outCubic,
		InOut = inOutCubic,
		OutIn = outInCubic,
	},
	Quart = {
		In = inQuart,
		Out = outQuart,
		InOut = inOutQuart,
		OutIn = outInQuart,
	},
	Quint = {
		In = inQuint,
		Out = outQuint,
		InOut = inOutQuint,
		OutIn = outInQuint,
	},
	Sine = {
		In = inSine,
		Out = outSine,
		InOut = inOutSine,
		OutIn = outInSine,
	},
	Exponential = {
		In = inExponential,
		Out = outExponential,
		InOut = inOutExponential,
		OutIn = outInExponential,
	},
	Circular = {
		In = inCircular,
		Out = outCircular,
		InOut = inOutCircular,
		OutIn = outInCircular,
	},
	Elastic = {
		In = inElastic,
		Out = outElastic,
		InOut = inOutElastic,
		OutIn = outInElastic,
	},
	Back = {
		In = inBack,
		Out = outBack,
		InOut = inOutBack,
		OutIn = outInBack,
	},
	Bounce = {
		In = inBounce,
		Out = outBounce,
		InOut = inOutBounce,
		OutIn = outInBounce,
	}
}