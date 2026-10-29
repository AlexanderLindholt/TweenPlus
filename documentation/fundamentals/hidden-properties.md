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

# Hidden properties

Certain properties are only configurable via methods (such as `:PivotTo()`).

Fortunately, you can tween these properties as if they were just normal properties in Tween+.\
Here’s an example:

<pre class="language-luau"><code class="lang-luau">local tween = Tween(
	workspace.Model,
	{
<strong>		Pivot = workspace.Model:GetPivot().CFrame -- The hidden 'Pivot' property. Read/write with `:GetPivot()` and `:PivotTo()`.
</strong>	}
)
</code></pre>



These are all the method-based properties:

* [Pivot](https://create.roblox.com/docs/reference/engine/classes/PVInstance#summary-methods)
* [Scale](https://create.roblox.com/docs/reference/engine/classes/Model#Scale)

