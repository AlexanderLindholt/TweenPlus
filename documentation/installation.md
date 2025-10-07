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
---

# Installation

{% stepper %}
{% step %}
### Get the module

{% tabs %}
{% tab title="Creator Store" %}
<a href="https://create.roblox.com/store/asset/100081703118723" class="button primary">Get Roblox Asset</a>

* Click `Get Model`.
* Open the ToolBox in Roblox Studio.
* Go to the `Inventory` tab.
* Click on `Tween+` to insert.
{% endtab %}

{% tab title="GitHub" %}
<a href="https://github.com/AlexanderLindholt/TweenPlus/releases/latest" class="button primary">See Latest Release</a>

* Download the `.rbxm` file.
* Find the file in your file explorer.
* Drag the file into Roblox Studio.
{% endtab %}
{% endtabs %}
{% endstep %}

{% step %}
### Place it

Find a great place for the module, where other scripts can reference it.
{% endstep %}

{% step %}
### Install dependencies

* [Inxpect](https://devforum.roblox.com/t/3799622)\
  A simple, efficient API map builder.\
  &#xNAN;_&#x4D;ake sure to_ [_tag_](https://create.roblox.com/docs/studio/properties#instance-tags) _the module `APIMap`._
* [Players+](https://github.com/AlexanderLindholt/PlayersPlus)\
  A simple custom player list, which only includes ready clients.\
  &#xNAN;_&#x4D;ake sure to_ [_tag_](https://create.roblox.com/docs/studio/properties#instance-tags) _the module `PlayerList`._
{% endstep %}
{% endstepper %}
