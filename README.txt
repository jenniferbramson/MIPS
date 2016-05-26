Jennifer Bramson
jib41@pitt.edu

This creates an LED bug invaders game, intended to be run on MARS with an LED display simulator.

I used a circular buffer starting at address 10020000 and ending at 100201FF to mimic a queue. Each item in the queue takes up one word. 200 in hex is 512 in decimal. 512 divided by 4 is 128, so the queue can hold up to 128 items at once. I implemented the circular queue to hold 127 items so that the pointers could be used to calculate the number of items within the queue without ambiguity. If it goes above this, a queue overflow error is issued. Each stored word contains the item type, x-value, y-value, and radius.

Once the game has begun (the center key pressed), an initial time is stored in $s4 using syscall 30. Throughout the two minutes of this game, the total time is compared  against $s5 to see if 100 ms have passed. If 100 ms have passed, _itemLoop initiates and moves the items in the queue. 100 ms means that the items in the queue move pretty quickly, making the game quite challenging. When _itemLoop completes, the total time is compared against $t8, adding bugs when the total time exceeds the number in $t8. The number at $t8 does not grow at a constant rate, but a varied rate thanks to a decreasing number in $t9, which is the number added to $t8 after each time that bugs are added.

The items in the queue are moved by a loop which removes the item at the front of the loop, does the necessary changes to it (such as turning off a previous light and turning on a new light) then re-adds the item to the end of the queue. To delete an item then, the item is just not re-added. The loop iterates a number of times equal to the size of the queue. The size is determined by subtracting the pointer to four before the start of the queue from the pointer to the end of the queue, then dividing that number by four (as each item is a word). The pointer to the start is actually four before the start of the queue because otherwise it would be necessary to put a special case for the first item in the queue to get a correct size returned. This way, each item insertion uniformly adds four, making the size easy to calculate.

Finally, when a bug is hit, a wave is created where each of the eight pulses making up the wave is a separate item, this gives the pulses independence. Since the items are independent, if one pulse hits a bug, that pulse can be deleted while the others remain. Since a wave is created each time a bug is hit, incrementing the bugs hit there is convenient.

There are no known bugs, except the ones that you shoot at. 