# Dice-Poker
Recreated Dice Poker in Roblox and added an AI adversary using Expectimax.

Play here: https://www.roblox.com/games/13449914869/Dice-Poker-AI

## Files included
game.lua
- Contains the game mechanics, including GUI manipulation to give visuals to the game:
 - Starting the game, giving players their hands, running the game timer, determing players hand value and the winner of the round, and displaying all of the previously mentioned actions.

Files not included
- Many small files for handling client side actions, such as locking a dice.

ai.lua
- Has the implementation of the AI in the game, including a random AI, stylized AI, and the expectimax AI.
  - For the random AI, I simply gave the AI their starting randomized hand and made them keep it.
 - For the stylized AI, I gave the AI directions depending on their hand state, to mimic my style of play.
 - For the expectimax AI, I wrote an expected value function, and used the weighted average of every state to determine the choice that gave the maximized result.
  - Inspiration for my algorithm, including further explanation: https://www.geeksforgeeks.org/expectimax-algorithm-in-game-theory/ 

