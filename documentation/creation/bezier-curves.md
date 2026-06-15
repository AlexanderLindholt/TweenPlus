---
icon: bezier-curve
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
---

# Bézier curves

As opposed to moving in a straight line from point A to B in a space, you can have tweens follow smooth paths to achieve beautiful and natural motion in 3D and 2D scenes of any kind.

Whether it’s a seamless multi-point 3D camera animation for a cutscene, fancy 2D GUI tweens, or something even more interesting, it’s almost certainly possible with Tween+.

{% hint style="info" %}
If you’re new to Bézier Curves, consider checking out this amazing [video](https://www.youtube.com/watch?v=aVwxzDHniEw) about it.
{% endhint %}

All relevant datatypes are supported:

* CFrame
* Vector3
* Vector2
* UDim2
* UDim



And it couldn’t be any simpler to use:

```luau
local tween = Tween(
	workspace.CoolPart,
	{
		-- Passing a table triggers the Bézier path.
		-- Format: {Destination, ControlPoint1, ControlPoint2 (Optional)}
		Position = {workspace.Destination.Position, workspace.ControlPoint.Position}
	}
)
```

