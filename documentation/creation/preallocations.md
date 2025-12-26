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

# Preallocations

```diff
+ The more preallocations, the more tweens you can have with quicker start/stop.
The preallocation amount is equal to
the amount of tweens you can have with quicker start/stop.

- The more preallocations, the more memory/RAM is used.
The memory consumption can be calculated like this:
Bytes  =  PreallocationAmount * 8
```

You can set the preallocation amount via the `TweenPreallocations` attribute on the main module. It’s obviously recommended to leave it at what you believe to be the maximum amount of tweens you’re going to be using at once.

{% hint style="success" %}
This is a very small optimization, therefore it’s nothing to worry about, rather merely a recommendation if you don’t mind spending a few seconds typing a reasonable number.
{% endhint %}

{% hint style="info" %}
The default is 256, which is fine as is.
{% endhint %}
