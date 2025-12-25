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

# Hidden properties

In Tween+, you can tween method-based properties, which are not direct properties of the instance.\
They work the same as usual properties in Tween+.

Example usage of hidden properties:

<pre class="language-lua"><code class="lang-lua">local tween = Tween(
	workspace.Model,
	{
<strong>		Pivot = workspace.Model:GetPivot().CFrame -- The hidden 'Pivot' property. Read/write with `:GetPivot()` and `:PivotTo()`.
</strong>	}
)
</code></pre>



Here are the currently supported hidden properties:

* [Pivot](https://create.roblox.com/docs/reference/engine/classes/PVInstance#summary-methods)
* [Scale](https://create.roblox.com/docs/reference/engine/classes/Model#Scale)

I believe there are none I missed.\
If I did miss some, please let me know!
