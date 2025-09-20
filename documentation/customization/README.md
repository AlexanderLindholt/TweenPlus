---
icon: ballot
---

# Options

The options are provided in a table. You may provide any amount of options you like.\
Those not provided will fallback to their respective defaults.

Example:

```lua
local tween = Tween(
	workspace.Part,
	{
		Position = Vector3.new(0, 10, 0),
		Color = Color3.fromRGB(255, 255, 0)
	},
	{ -- Options (optional).
		Time = 10,
		EasingStyle = "Sine",
		EasingDirection = "InOut"
	}
)
```
