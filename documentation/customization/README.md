---
icon: ballot
---

# Options

The options is a table, where you may provide any options you like.\
You are not required to provide all, or even any, as all options have defaults.

Example options:

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
