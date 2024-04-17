# New way to maintain settings
Time to time constants appears in your code.  Some time constants are less constant.  They have different types for example date of feature start, rfc_dest to other system, and number of parallel tasks. 

To maintain settings you have to create a table of 1 row or class for constant. Both this way has different costs to create settings, add settings, and change settings. Less is better.

![comparison](img/img_01.png "comparison")

And you have tens of table of 1 row that replicate each other.

I have solution that have best part of both way to maintain settings. Easy to create, easy add, easy maintain. As bonus you can have documentation for settings like flag_25 type xfeld.

We can hold 
+ single value
+ single structure
+ table of value
+ table of struct


to hold this different variables in one table I serialized them in json and save in table of text255

to read settings:
+ select data
+ join string
+ deserealizate

after installation navigate to screen #2 
![comparison](img/img_02.png "comparison")

We need to adjust something 
Make layout bigger
from
![comparison](img/img_03.png "comparison") 
to ![comparison](img/img_04.png "comparison")
