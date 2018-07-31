# luatris
A version of the classic four-piece block game in Lua through LÖVE. Because why not.

## Dependencies
* Lua 5.1
* LÖVE 11.1

## Running
Run `love game` in the `luatris` folder. Simple as that.
If you don't have LÖVE installed on your computer, provide the path to the executable instead of `love`

## Controls
Currently, the keys are as follows:
* The left and right arrow keys move the current tetromino left and right.
* The down arrow key soft drops the current tetromino (For the uninformed, this means that the tetromino drops quicker).
* The up arrow key hard drops the current tetromino (Again, for the uninformed, this means that the tetromino will immediately move straight down to the ground)
* The `Z` and `X` keys rotate the current tetromino counter-clockwise and clockwise, respectively.
* The spacebar holds the current tetromino, allowing it to be recalled by pressing spacebar again
* Holding the escape key for three seconds closes the game.
The game will feature customizable controls at a later date.

## Other Stuff
If you want to have fun with grid sizes (rather than the default 10 by 20), change the `width` and `height` values in line 77, in the `grid` table.

N.B. This currently only works with a height-to-width ratio of 2:1.   
