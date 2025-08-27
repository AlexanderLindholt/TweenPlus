---
icon: fill-drip
---

# Customization

The customization works with a table, where you can provide any customizations you want.\
You don’t have to provide all, or even any, because they all have defaults.

You use it like this:

```lua
local tween = Tween(
	workspace.Part,
	{
		Position = Vector3.new(0, 10, 0),
		Color = Color3.fromRGB(255, 255, 0)
	},
	{ -- Customization (optional).
		Time = 10,
		EasingStyle = "Sine",
		EasingDirection = "InOut"
	}
)
```
