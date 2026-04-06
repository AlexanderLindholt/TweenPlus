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
---

# Preallocations

The `TweenPreallocations` attribute on the main module enables pre-sizing of the internal active tween table (default is `256`).

{% hint style="info" %}
Only increase this if you’re starting hundreds of tweens at once and want a tiny performance boost.
{% endhint %}
