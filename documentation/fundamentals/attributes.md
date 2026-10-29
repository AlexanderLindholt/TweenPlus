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

# Attributes

_If you aren’t already familiar with attributes, check out the_ [_official documentation_](https://create.roblox.com/docs/scripting/attributes)_._

Starting a value name off with `@` will let Tween+ know it’s an attribute.\
Other than that they work the same as normal properties.

Example usage of attributes:

<pre class="language-luau"><code class="lang-luau">local tween = Tween(
	workspace.Part,
	{
		Position = Vector3.new(0, 10, 0),
		Color = Color3.fromRGB(255, 255, 0),
<strong>		["@Coolness"] = 10 -- Attribute named 'Coolness'.
</strong>	}
)
</code></pre>

