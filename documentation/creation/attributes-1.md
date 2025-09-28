---
layout:
  width: default
  title:
    visible: true
  description:
    visible: false
  tableOfContents:
    visible: false
  outline:
    visible: true
  pagination:
    visible: true
  metadata:
    visible: true
---

# Hidden properties

In Tween+ you can tween method-based properties, which are not direct properties of the instance.\
They work the same as usual properties in Tween+.

Example usage of hidden properties:

```lua
local tween = Tween(
	workspace.Model,
	{
		Pivot = workspace.Model:GetPivot().CFrame -- The hidden 'Pivot' property. Read/write with `:GetPivot()` and `:PivotTo()`.
	}
)
```



Here are the currently supported hidden properties:

* [Pivot](https://create.roblox.com/docs/reference/engine/classes/PVInstance#summary-methods)
* [Scale](https://create.roblox.com/docs/reference/engine/classes/Model#Scale)

As far as I'm aware, there are no other hidden properties.\
Make sure to let me know if I missed any!
