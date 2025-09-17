# Global tweening

The server and client tween APIs are identical, allowing you to reuse the same code on both ends.

Any server tweens whose `Replicated` option has not been set to `false` will act as a global tween that replicates to all clients in the game.

{% hint style="warning" %}
There's a limit of 256 total global tweens at once due to optimizations.
{% endhint %}

{% hint style="warning" %}
It's crucial that you require Tween+ on the clients as well.
{% endhint %}
