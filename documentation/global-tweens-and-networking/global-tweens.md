# Global tweens

The server and client tween APIs basically identical, allowing you to reuse the same code on both ends. Only the `Replicated` option is server-only, obviously.

Any server tweens, whose `Replicated` option is set to `true`, will act as a global tween that replicates to all clients in the game server.



When using global tweens, make sure to:

* Initialize the Tween+ module on the clients by requiring it.
* Set the `Replicated` option to `true` on the tween you wish to make global.



{% hint style="warning" %}
There’s a limit of 256 total global tweens at once due to optimizations.
{% endhint %}
