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

# Replicate

This value controls whether or not the tween will be replicated to the clients (players).\
The option is server-only and requires specific networking [set up](https://app.gitbook.com/s/yQ73a7xL7651w6YiS7XC/networking).

{% hint style="warning" %}
Tween+ does not and is unable to disable Roblox’s replication.

Therefore, for local server tweens, on top of ensuring `Replicate` is not set to `true`, ensure the instance doesn’t exist on any clients, otherwise Roblox will automatically replicate it every frame, leading to a lot of unnecessary network traffic.
{% endhint %}

