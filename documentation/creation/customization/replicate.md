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

# Replicate

`Replicate` is one of the many options.

The value controls whether or not the tween will be replicated to the clients (players).\
This option is server-only and requires specific networking [set up](/broken/pages/0RaGVRUWA0uSIHHlGxib).

{% hint style="info" %}
Useful for internal server tweens that have no reason to be attempted to be replicated.
{% endhint %}

{% hint style="warning" %}
Tween+ does not and is unable to disable Roblox’s replication. Therefore, on top of ensuring `Replicate` is set to `false`, ensure the instance doesn’t exist on any clients, otherwise Roblox will automatically replicate it every frame, leading to a lot of unnecessary network traffic.
{% endhint %}
