tunnel-vision
=============
Tunnel Vision is a game designed on the Xilinx Nexys 3 FPGA board.  It uses the Picoblaze softcore to control the gameplay. The display controller lets the user view the game via a monitor through a  VGA cable. 

Gameplay:  
The player tries to avoid hitting the walls as he travels down the tunnel by moving his vehicle left and right. The space in between the walls steadily decreases until the player hits a wall.  The score is displayed during gameplay.

Controls:   <br />
The player can move his vehicle left and right by using the left and right pushbuttons on the Nexys3.  When the game is over, hitting the middle button will reset course.  The top button starts the game and the bottom pushbutton pauses it. Different courses and icons can be selected by enabling switch1 on the Nexys3. Different levels are selected by enabling switch2, and multiplayer mode can be enabled with switch3 (yet to be implemented).

Features:   <br />
The player will be able to select different vehicles, backgrounds, and speed levels.  The courses are generated randomly through a combination of a pseudo-random generator (LFSR) and user input (via pushbuttons and switches).

Future Work:   <br />
In the future, we hope to add features such as:
-Nintendo controller integration
-Soundtrack
-Multiplayer options
-Powerups/Bonuses

Site Navigation: 
Our code and documentation can all be found here. Our distribution of tasks, workflow, and progress can be viewed through the milestones and issues.
