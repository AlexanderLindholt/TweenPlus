---
icon: box-archive
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

# Installation

{% tabs %}
{% tab title="GitHub (recommended)" icon="github" %}
<a href="https://github.com/AlexanderLindholt/TweenPlus/releases/latest" class="button primary">See Latest Release</a>

* Download the `.rbxm` file.
* Find the file in your file explorer.
* Drag the file into Roblox Studio.
* Place it anywhere you like and enjoy!

\
**Bonus:** The package will auto-update if you enable it in the `PackageLink` inside.
{% endtab %}

{% tab title="Creator Store" icon="basket-shopping-simple" %}
<a href="https://create.roblox.com/store/asset/100081703118723" class="button primary">Get Roblox Asset</a>

* Click `Get Model`.
* Open the ToolBox in Roblox Studio.
* Go to the `Inventory` tab.
* Click on `Tween+` to insert.
* Place it anywhere you like and enjoy!
{% endtab %}

{% tab title="Wally" icon="box-isometric" %}
<a href="https://wally.run/package/alexanderlindholt/tweenplus" class="button primary">View Wally Package</a>

* Open project directory in a terminal.
* Initialize with `wally init`.
* Add Tween+ in the  `wally.toml` file:

```toml
[dependencies]
Tween = "alexanderlindholt/tweenplus@*"
```

* Run `wally install` and enjoy!

\
Get the latest version at any time with `wally update`.
{% endtab %}
{% endtabs %}

