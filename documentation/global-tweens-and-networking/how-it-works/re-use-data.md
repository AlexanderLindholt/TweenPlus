# Re-use data

Sometimes we can avoid sending certain data, as we may use other data to calculate it.

For example, when a player joins mid-tween, we want to inform them of how many repetitions we've done already. You might think we should also inform the client of whether or not we're going in reverse at the moment. But actually, we can utilize some simple math in this case.

Since we have the repetition count already, we can use that to calculate whether or not we're going in reverse at the moment. It's just a simple check to see if the repetition count is odd or even — if it's odd, we're going in reverse, otherwise we're not.

This simple principle of re-using data can be applied in many other cases as well. Small optimizations like these add up, and can result in greatly reduced network traffic in the end.
