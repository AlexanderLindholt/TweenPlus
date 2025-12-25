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

# Global tweening

The server and client tween APIs basically identical, allowing you to reuse the same code on both ends. Only the `Replicated` option is server-only, obviously.

Any server tweens whose `Replicated` option has _not_ been set to `false`, will act as a global tween that replicates to all clients in the game server.

{% hint style="warning" %}
There’s a limit of 256 total global tweens at once due to optimizations.
{% endhint %}

{% hint style="warning" %}
It’s crucial that you initialize the Tween+ module on the clients by requiring it.
{% endhint %}
