# Acceptance Criteria: Coyote Jump Mechanic

## Scenario 1: Successful coyote jump within grace period
```
Scenario: Player performs coyote jump within 6 frames of leaving platform
  Given the player is standing on a platform
  And the player runs off the platform edge
  When the player presses jump within 6 frames (100ms) of leaving the platform
  Then the player jumps upward with standard jump velocity
  And the player's vertical velocity changes from falling to +20 units/frame
  And the player gains 5 units of height before gravity pulls them down
  And the coyote jump counter resets
```

## Scenario 2: Coyote jump with horizontal momentum preservation
```
Scenario: Player maintains horizontal movement while performing coyote jump
  Given the player is running rightward at 8 units/frame horizontally
  And the player runs off a platform edge
  When the player presses jump within 6 frames of leaving the platform
  Then the player jumps upward with standard jump velocity
  And the player's horizontal velocity remains 8 units/frame (momentum preserved)
  And the player follows a parabolic trajectory (up-right arc)
  And horizontal movement is not interrupted
```

## Scenario 3: Edge case - coyote jump at frame 0 (earliest possible)
```
Scenario: Player jumps on the exact frame they leave the platform
  Given the player is on a platform edge
  When the player presses jump on frame 0 (the instant they fall off)
  Then the jump command is registered immediately
  And the player jumps with standard jump velocity
  And no falling velocity is accumulated
  And the coyote jump window closes
```

## Scenario 4: Edge case - coyote jump at frame 6 (latest possible)
```
Scenario: Player jumps at the boundary of the coyote grace period (frame 6)
  Given the player fell off a platform 6 frames ago
  When the player presses jump on frame 6 (100ms after leaving platform)
  Then the jump is accepted as a valid coyote jump
  And the player jumps with standard jump velocity
  And the coyote jump window closes
```

## Scenario 5: Error case - coyote jump window expired (frame 7)
```
Scenario: Player attempts jump after coyote grace period expires
  Given the player fell off a platform 7 frames ago
  When the player presses jump on frame 7 (105ms after leaving platform)
  Then the jump is NOT executed
  And the player continues falling with accumulated gravity velocity
  And no jump animation plays
  And the player must land on solid ground to jump again
```

## Scenario 6: Error case - coyote jump unavailable on wall slide
```
Scenario: Player cannot use coyote jump when sliding down a wall
  Given the player is sliding down a vertical wall
  And the player's vertical velocity is negative (downward)
  When the player presses jump while wall-sliding
  Then the wall jump mechanic activates instead (if available)
  And the coyote jump does NOT activate
  And the player bounces away from the wall with wall jump velocity
```

## Scenario 7: Movement combination - diagonal input during coyote jump
```
Scenario: Player provides diagonal input during coyote jump recovery
  Given the player fell off a platform 2 frames ago
  And the player is holding right arrow
  When the player presses jump within 6 frames
  And continues holding right during the jump
  Then the player jumps upward with standard jump velocity
  And horizontal rightward movement continues uninterrupted (8 units/frame)
  And the player's trajectory is a diagonal parabola (up-right)
  And input direction changes mid-jump are respected
```

## Scenario 8: Movement combination - direction change during coyote jump
```
Scenario: Player changes direction mid-coyote-jump
  Given the player is running left and falls off a platform
  And the player presses jump within 6 frames
  When the player releases left and presses right during the jump arc
  Then the jump velocity is applied immediately
  And horizontal velocity begins changing from leftward to rightward
  And the player's trajectory curves toward the right
  And momentum transition is smooth (no jerky direction snaps)
```

## Scenario 9: Error case - coyote jump on ground (no recovery needed)
```
Scenario: Player attempts coyote jump while standing on solid ground
  Given the player is standing on a platform
  And the player's vertical velocity is 0 (not falling)
  When the player presses jump
  Then the normal jump mechanic executes (not coyote jump)
  And the player jumps with standard jump velocity
  And the coyote timer does NOT start
  And this consumes the player's air jump budget (if applicable)
```

## Scenario 10: Error case - coyote jump with active upward velocity
```
Scenario: Coyote jump is unavailable while player has upward momentum
  Given the player recently jumped and is ascending
  And the player's vertical velocity is positive (+15 units/frame upward)
  When the player presses jump again
  Then a second jump is NOT executed
  And the player continues ascending with original jump velocity
  And the coyote mechanic does NOT activate
  And only air-jump or double-jump mechanics (if available) are considered
```

## Scenario 11: Edge case - multiple platforms with coyote chain
```
Scenario: Player uses coyote jump to recover after falling between platforms
  Given the player is running across platform A
  And platform B is 3 units below and 4 units ahead
  When the player runs off platform A
  And presses jump within 6 frames while airborne
  And the coyote jump allows the player to reach platform B
  Then the player lands on platform B successfully
  And the coyote timer resets upon landing
  And the player can perform another coyote jump if they fall again
```

## Scenario 12: Movement combination - jump during direction input lag
```
Scenario: Player jumps with input buffering (jump pressed slightly before leaving platform)
  Given the player is on a platform edge
  And the player presses jump 1 frame before running off
  When the jump input is buffered and the player leaves the platform
  Then the buffered jump executes within the coyote window
  And the player jumps with standard jump velocity
  And the jump is treated as a valid coyote jump, not a ground jump
```
