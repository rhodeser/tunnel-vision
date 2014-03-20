Tunnel Vision
=============
Tunnel Vision is a game designed on the _Xilinx Nexys 3_ FPGA board.  It uses the _Picoblaze_ softcore to control the gameplay. The display controller lets the user view the game via a monitor through a  VGA cable.

### Gameplay    <br /> 
The player tries to avoid hitting the walls as he travels down the tunnel by moving his vehicle left and right. The space in between the walls steadily decreases until the player hits a wall.  The score is based on the amount of time the vehicle remains "alive", and is displayed on the 7-segment display.

### Controls   <br />
The player can move his vehicle by using the left and right pushbuttons on the Nexys3.  When the game is over, hitting the middle button will reset the course.  The top button starts the game and the bottom pushbutton pauses it. Different icons and speeds can be selected by toggling the switches on the board. 

### Features   <br />
The player will be able to select different vehicles, backgrounds, and speed levels.  The courses are generated randomly through a combination of a pseudo-random generator (LFSR) and user input (via pushbuttons and switches).

### Future Work   <br />
In the future, we hope to add features such as:   <br />
- Nintendo controller integration   <br /> 
- Soundtrack   <br />
- Multiplayer options   <br />
- Powerups/Bonuses   <br />

### Site Navigation    <br />
Our code and documentation can all be found here. Our distribution of tasks, workflow, and progress can be viewed through the milestones and issues. The progress report, final presentation, and final report can be viewed in the __doc__ folder.


