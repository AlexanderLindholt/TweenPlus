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

# Re-use data

Sometimes we can avoid sending certain data, as we may use other data to calculate it.

For example, when a player joins mid-tween, we want to inform them of how many repetitions we’ve done already. You might think we should also inform the client of whether or not we’re going in reverse at the moment. But we can actually utilize some simple math in this case:

Since we already have the repetition count, we can use that to calculate the direction we’re moving in. It’s merely a simple check to see if the repetition count is odd or even — if it’s odd, we’re going in reverse, otherwise we’re not.

This simple principle of re-using data can be applied in many other cases as well. Small optimizations like these add up, and can result in greatly reduced network traffic together.
