# Introduction

When you require the module, it will return a function, which you can use to create tweens.\
Example:

```lua
local Tween = require(script.TweenPlus)

local tween = Tween(
	workspace.Part, -- Instance to tween.
	{} -- Properties to tween.
)
```

You simply input all the properties you would like to tween, like so:

```lua
local tween = Tween(
	workspace.Part,
	{
		Position = Vector3.new(0, 10, 0),
		Color = Color3.fromRGB(255, 255, 0)
		-- And as many more as you'd like.
	}
)
```
