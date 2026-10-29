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
  tags:
    visible: true
  actions:
    visible: true
  anchors:
    visible: true
---

# Introduction

As opposed to moving in a straight line from point A to B, you can have tweens follow smooth curves to achieve beautiful and natural motion in 3D and 2D scenes of any kind.

{% hint style="info" %}
If you’re new to Bézier Curves, consider checking out [this amazing video](https://www.youtube.com/watch?v=aVwxzDHniEw) about it.
{% endhint %}

All coordinate datatypes are supported:

* CFrame
* Vector3
* Vector2
* UDim2



And it couldn’t be any simpler to use:

```luau
local tween = Tween(
	workspace.CoolPart,
	{
		-- Passing a table triggers a Bézier path.
		-- Format: {Destination, ControlPoint1, ControlPoint2 (Optional)}
		Position = {workspace.Destination.Position, workspace.ControlPoint.Position}
	}
)
```
