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

In Tween+, you can tween method-based properties just like normal properties.

Here’s an example:

<pre class="language-lua"><code class="lang-lua">local tween = Tween(
	workspace.Model,
	{
<strong>		Pivot = workspace.Model:GetPivot().CFrame -- The hidden 'Pivot' property. Read/write with `:GetPivot()` and `:PivotTo()`.
</strong>	}
)
</code></pre>



Here are the supported method-based properties:

* [Pivot](https://create.roblox.com/docs/reference/engine/classes/PVInstance#summary-methods)
* [Scale](https://create.roblox.com/docs/reference/engine/classes/Model#Scale)
