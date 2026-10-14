# Specification for EVIL OTTO

## General description

The player is Otto. More precisely, evil Otto: instead of throwing balls to students who answer correctly, he throws balls at students who give stupid answers. The map is an ASCII representation of our lecture hall (semicircular rows of chairs facing upwards, three projector screens at the top, Otto standing in front of the middle projector, Otto's dialogue box between the three projector screens).

Each round is like so: Otto asks a question, then one dialogue box per student appears one by one (with highlighted students in the ASCII art), with the stupid answer always coming last. Once the stupid answer is on screen, the other two dialogue boxes disappear after a small delay, Otto becomes red and angry after another small delay, and the aiming sequence starts after a third delay.

The player is then gets a trajectory line swinging across the lecture hall and the player has two actions: first lock in the radial angle and second to lock in the distance. The goal is to hit the student who gave the stupid answer. On a hit, the player scores points. Then the cycle repeats.

## Technologies

- ASCII lecture hall hardcoded in .rodata
- seat entity array (three answering students per round, exactly one of them dumb)
- trajectory line swinging across the classroom, driven by an angle table of (dx,dy) integer pairs
- two input locks: the first locks the radial angle, the second locks the distance
- Manhattan-distance hit test with a small hit radius
- top scores written to a file and shown at game over
- sound effects via system() and aplay using short WAV clips

## Assignment details

- This is a two-person project.
- Target OS is the one provided by the university (64-bit Linux).
- Libraries: only libc (read/write/system). No graphical or audio libraries.
- Rendering: terminal ASCII art printed with write(), colored with ANSI escape codes for foreground and background.
- Input: keyboard-based. The spacebar locks (first press locks the angle, second press locks the distance) and q quits. There is no mouse input.
- Ending: the game is lost after 3 misses, at which point the Dean invites Otto to a little chat (game over). There is no final win state; the game is score attack, so the goal is a high score, which is recorded permanently.

## Program overview

```c

// ---------- GLOBALS ----------
seat* seats; // seats array (data is in .bss, x,y of every chair on screen)
int seats_size;

int otto_x, otto_y; // Otto never moves
int otto_mad; // 0 - normal eyes, 1 - red eyes (mad)

char* question; // pointer to the current question string (data is in .rodata)
char* answers[3]; // pointers to the three answer strings, last one is always dumb
int dumb_idx; // index of the seat that gave the stupid answer (the target)

int aim_angle; // index into the angle table, advances every tick while aiming
int aim_locked_angle; // -1 until the first lock
int aim_dist; // pulses 1..max every tick once the angle is locked
int aim_locked_dist; // -1 until the second lock

int score;
int streak;
int misses; // 3 misses trigger the Dean ending
int quit_flag; // set by q, checked by the main loop

const int ANGLE_SPEED;
const int DIST_SPEED;
const int MAX_MISSES; // 3
// dialogue timing (in ticks):
const int ANSWER_DELAY; // delay between dialogue boxes
const int MAD_DELAY; // delay before the red eyes
const int AIM_DELAY; // delay before aiming starts


// ---------- GAME LOOP ----------
/*
Sets the terminal to raw mode, hides the cursor, draws the hall, zeroes the score.
*/
void initialize();

/*
Plays one full round: asks the question, shows the answers one by one with delays,
hides the sincere boxes, turns mad (red eyes), runs aiming, resolves hit or miss.
Is run until 3 misses or quit.
Calls ask_question, show_answers, get_mad, aim, resolve_throw in this order.
*/
void play_round(int round_no);

/*
Restores the terminal, shows the cursor again, prints the score and the top scores.
Saves the score to file if it made the list.
*/
void game_over();


// ---------- ROUND ----------

/*
Used in play_round.
Picks a random question, two sincere answers and one dumb answer from tables.
Picks three random seats and marks one of them dumb (the target).
*/
void ask_question();

/*
Used in play_round.
Shows the student dialogue boxes one by one with ANSWER_DELAY ticks between them.
The last box is always the stupid answer.
*/
void show_answers();

/*
Used in play_round.
Hides the two sincere boxes, waits MAD_DELAY, sets otto_mad = 1 (red eyes),
then waits AIM_DELAY.
*/
void get_mad();

/*
Used in play_round.
Waits the given number of ticks (fixed interval each). Used for all stage delays.
*/
void wait_ticks(int n);


// ---------- AIMING ----------

/*
Used in play_round.
Swings the trajectory line across the classroom using the angle table.
The first spacebar press locks the radial angle (sets aim_locked_angle).
The distance then pulses along the locked ray and the second spacebar press
locks it (sets aim_locked_dist). Non-blocking input is read every tick.
*/
void aim();

/*
Used in aim.
Looks up the direction for an angle table index (dx,dy pairs, integers only).
Return:
  direction vector for that angle, via the out-parameters.
*/
void get_angle_dir(int angle_idx, int* dx, int* dy);

/*
Used in play_round.
Computes the landing point from the locked angle and distance and checks the
Manhattan distance to the dumb seat. On a hit it adds score and grows the streak
and prints a taunt. On a miss it resets the streak, increments misses and prints
the miss line while setting otto_mad back to 0.
Return:
  0 - miss
  1 - hit
*/
bool resolve_throw();


// ---------- RENDERING ----------

/*
Used after every state change rather than on a fixed tick.
Draws the hall, the screens, Otto (normal or red eyes depending on otto_mad),
whichever dialogue boxes are currently visible, the trajectory line while aiming,
and the score, misses and streak at the bottom.
*/
void render();

/*
Used in game_over.
Reads the top scores file, inserts the current score if it made the list,
writes the file back and prints the table. The file is plain text, one score per line.
*/
void show_top_scores(int score);

```

### Structs

Number of bytes to the left and description to the right.

```txt
seat:
  2 - x
  2 - y
  1 - is_dumb
  1 - is_hit
```

## Non technical notes

- will play audio on some dialogue lines (hopefully)
- red eyes reuse the same ASCII art with O instead of o, printed in red
- the trajectory line is a yellow background that never modifies the art, it only colors cells
