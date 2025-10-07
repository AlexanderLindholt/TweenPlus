---
layout:
  width: default
  title:
    visible: true
  description:
    visible: false
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
  metadata:
    visible: true
---

# Introduction

When you require the module, it'll return a function, which you can use to create tweens:

```lua
local Tween = require(script.TweenPlus)

local tween = Tween(
	workspace.Part, -- Instance to tween.
	{} -- Values to tween.
)
```

You simply input all the values you would like to tween:

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



{% hint style="warning" %}
In game context, make sure to require the APIMap module on the server, otherwise Tween+ won't function.
{% endhint %}
