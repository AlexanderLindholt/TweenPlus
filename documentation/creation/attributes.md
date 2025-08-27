# Attributes

_If you aren't already familiar with attributes, please check out_ [_Roblox's explanation_](https://create.roblox.com/docs/scripting/attributes)_._



Starting a value name off with `@` will let Tween+ know that it's an attribute.\
Other than that they work the same as usual properties.

Example usage of attributes:

```lua
local tween = Tween(
	workspace.Part,
	{
		Position = Vector3.new(0, 10, 0),
		Color = Color3.fromRGB(255, 255, 0),
		["@Coolness"] = 10 -- Attribute named 'Coolness'.
	}
)
```
