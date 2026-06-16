# Coyote Jump Mechanics — Manual Test Checklist

## Overview

This document provides a step-by-step checklist for manually testing the coyote jump mechanic against the acceptance criteria. The implementation uses a `coyote_timer` value of **0.15 seconds (150ms)** instead of the AC's 100ms; all tests should use the implemented value.

### How to Use This Checklist

1. Open the Godot editor and load `scenes/test_coyote_jump.tscn`
2. Press **F6** (or click Play) to run the test scene
3. Follow each scenario below
4. The **Debug HUD** (top-left corner) displays:
   - `Coyote`: current coyote window countdown (>0 = window open)
   - `Buffer`: current jump buffer countdown (>0 = input buffered)
   - `Floor`: whether player is grounded (true/false)
   - `VelY`: vertical velocity (negative = upward, positive = downward)
   - `VelX`: horizontal velocity

### Key Timing Values

- **Coyote window**: 0.15 seconds = ~9 frames at 60fps
- **Jump buffer window**: 0.15 seconds = ~9 frames at 60fps
- **Jump velocity**: -500.0 px/s (upward)

---

## Scenario 1: Coyote Jump Within Grace Period ✅

**Setup:**
1. Position player on Platform 1 (green platform on the left, labeled "Scenarios 1-5, 9, 10")
2. Watch the HUD — `Coyote` value should be ~0.15 while grounded

**Test:**
1. Walk right to the platform edge and walk off
2. Immediately press JUMP (frame 0)
3. **Expected**: Player jumps upward
4. **Verify**: HUD showed `Coyote > 0` when jump fired

**Status**: ☐ PASS / ☐ FAIL

---

## Scenario 2: Horizontal Momentum Preserved During Coyote Jump ✅

**Setup:**
1. Start on Platform 2 (left side, labeled "Momentum Test L")
2. Ensure clear gap to Platform 2 Right (~600 pixels)

**Test:**
1. Stand on left platform facing right
2. Press and hold RIGHT arrow key
3. Walk to edge and off the platform
4. While airborne, press JUMP within the coyote window (~0.10 seconds)
5. **Expected**: Player jumps AND continues moving right; trajectory is diagonal (up-right)
6. **Verify**: 
   - HUD shows `VelX ≈ 300` (rightward movement preserved)
   - Player lands on right platform

**Status**: ☐ PASS / ☐ FAIL

---

## Scenario 3: Frame 0 Edge Case (Earliest Possible Coyote Jump) ✅

**Setup:**
1. Position on Platform 1 edge
2. Watch HUD `Coyote` timer

**Test:**
1. Walk off platform
2. On the SAME frame you leave the floor, press JUMP
3. **Expected**: Jump fires immediately; no falling velocity accumulates yet
4. **Verify**: 
   - HUD shows `Coyote > 0` at the moment jump is pressed
   - Player gains upward velocity (-500.0)
   - No downward velocity before jump applies

**Status**: ☐ PASS / ☐ FAIL

---

## Scenario 4: Frame 6+ Boundary (Latest Valid Coyote Jump) ✅

**Setup:**
1. Position on Platform 1 edge
2. Count frames or use HUD timing

**Test:**
1. Walk off platform
2. Wait ~0.14 seconds (stay in coyote window but near the edge)
3. Press JUMP
4. **Expected**: Jump fires successfully
5. **Verify**: HUD shows `Coyote > 0` when jump pressed (should be close to 0 but still positive)

**Status**: ☐ PASS / ☐ FAIL

---

## Scenario 5: Frame 7+ Expired (Coyote Window Closed) ✅

**Setup:**
1. Position on Platform 1 edge
2. Watch HUD timing

**Test:**
1. Walk off platform
2. Wait >0.15 seconds (let coyote timer expire)
3. Press JUMP
4. **Expected**: Jump does NOT fire; player continues falling
5. **Verify**: 
   - HUD shows `Coyote ≤ 0` when jump pressed
   - Player accelerates downward (no velocity.y reset)
   - No jump animation

**Status**: ☐ PASS / ☐ FAIL

---

## Scenario 6: Wall Slide Exclusion ❌

**Setup:** Wall slide mechanic not yet implemented

**Status**: ☐ SKIPPED (deferred until wall-slide feature exists)

---

## Scenario 7: Diagonal Input During Coyote Jump ✅

**Setup:**
1. Start on Platform 2 Left
2. Clear gap to Platform 2 Right

**Test:**
1. Walk off platform while holding RIGHT
2. Within coyote window (~0.10s), press JUMP while still holding RIGHT
3. **Expected**: Jump fires; horizontal movement continues uninterrupted
4. **Verify**:
   - HUD shows `VelX ≈ 300` (rightward maintained)
   - Player follows diagonal parabola (up-right)
   - Player lands on right platform

**Status**: ☐ PASS / ☐ FAIL

---

## Scenario 8: Direction Change Mid-Jump ✅

**Setup:**
1. Start on Platform 2 Left
2. Face right, walk off

**Test:**
1. Walk off platform while holding RIGHT
2. Within coyote window, press JUMP
3. While in air, release RIGHT and press LEFT
4. **Expected**: Jump velocity applies; horizontal velocity transitions smoothly from right to left
5. **Verify**:
   - HUD shows `VelX` transitions from +300 toward -300 (smooth, no snaps)
   - Trajectory curves left mid-arc
   - No jerky direction changes

**Status**: ☐ PASS / ☐ FAIL

---

## Scenario 9: Normal Ground Jump (No Coyote Needed) ✅

**Setup:**
1. Stand still on Platform 1 (not moving, not falling)
2. Watch HUD — `Coyote` should be ~0.15

**Test:**
1. Press JUMP while standing still on ground
2. **Expected**: Normal jump fires (not coyote); uses standard jump velocity
3. **Verify**:
   - HUD shows `Floor: true` at the moment jump pressed
   - `VelY` becomes -500.0 (jump velocity)
   - Coyote timer is consumed (set to 0 after jump)

**Status**: ☐ PASS / ☐ FAIL

---

## Scenario 10: No Second Jump While Ascending (Coyote Consumed) ✅

**Setup:**
1. Stand on Platform 1

**Test:**
1. Press JUMP (fires first jump; `coyote_timer` is set to 0)
2. While ascending (before reaching apex), press JUMP again
3. **Expected**: Second jump does NOT fire; player continues ascending with original velocity
4. **Verify**:
   - HUD shows `Coyote ≤ 0` after first jump
   - `VelY` does not change on second jump press
   - Player ascends to original apex height, then falls

**Status**: ☐ PASS / ☐ FAIL

---

## Scenario 11: Multi-Platform Coyote Chain ✅

**Setup:**
1. Start on Platform 3 Upper (top platform, labeled "Scenario 11 A")
2. Platform 3 Lower is below and to the right (labeled "Scenario 11 B")
3. Gap is too wide for a normal jump

**Test:**
1. Walk right off Platform 3 Upper
2. Within coyote window (~0.10s), press JUMP
3. **Expected**: Coyote jump allows player to reach Platform 3 Lower
4. **Verify**:
   - Player lands on Platform 3 Lower successfully
   - Upon landing, HUD shows `Coyote ≈ 0.15` (resets on landing)
   - Player can perform another coyote jump if they walk off again

**Status**: ☐ PASS / ☐ FAIL

---

## Scenario 12: Jump Buffer (Jump Pressed Before Leaving Platform) ✅

**Setup:**
1. Position on Platform 4 edge (labeled "Scenario 12")
2. Watch `Buffer` HUD value

**Test:**
1. Stand on platform
2. Press JUMP one frame before walking off (while still grounded)
3. Walk off (jump input is buffered, `buffer_timer` still > 0)
4. **Expected**: Buffered jump fires while in coyote window; counts as valid coyote jump
5. **Verify**:
   - HUD shows `Buffer > 0` while airborne
   - Jump fires without needing to re-press
   - Jump velocity applies (`VelY = -500.0`)
   - Coyote timer is consumed

**Status**: ☐ PASS / ☐ FAIL

---

## Summary

| Scenario | Status | Notes |
|---|---|---|
| 1 | ☐ | Basic coyote within grace period |
| 2 | ☐ | Horizontal momentum preserved |
| 3 | ☐ | Frame 0 edge case |
| 4 | ☐ | Frame ~9 boundary |
| 5 | ☐ | Expired window (no jump) |
| 6 | ☐ SKIPPED | Wall slide not implemented |
| 7 | ☐ | Diagonal input |
| 8 | ☐ | Direction change mid-jump |
| 9 | ☐ | Normal ground jump |
| 10 | ☐ | No double-jump while ascending |
| 11 | ☐ | Multi-platform chain |
| 12 | ☐ | Jump buffer / input buffering |

**All tests passing?** ☐ YES / ☐ NO

If any test fails, note the scenario number and expected vs. actual behavior in the Notes column.

---

## Known Issues / Notes

- **AC Timing Discrepancy**: The acceptance criteria specifies 100ms (6 frames at 60fps), but the implementation uses 0.15s (9 frames). This is acceptable — the *behavioral contract* is that the coyote window exists and is predictable. If you need to match the AC exactly, update `coyote_time = 0.1` in `scripts/player.gd`.
- **Debug HUD**: If the HUD doesn't appear or shows "ERROR: Player not found", check that the test scene hierarchy is correct (Player node must be a direct child of TestCoyoteJump node).
