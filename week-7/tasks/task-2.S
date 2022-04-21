.syntax unified
.global main

.type main, %function
main:
  nop
  push {lr}
  bl init_leds
  pop {lr}
  b loop
.size main, .-main

loop:
  mov r0, 6
  push {lr}
  bl blink_codepoint
  pop {lr}
  push {lr}
  bl blink_space
  pop {lr}
  b loop

.type blink_codepoint, %function
blink_codepoint:
  push {r4-r6}
  mov r4, #24
  mov r6, r0
  mul r6, r6, r4
  mov r4, #4
  ldr r0, =morse_table
  ldr r5, [r0, r6]
  mul r5, r5, r4
  add r5, r5, r6
  mov r4, r6
blink_code_point_loop_start:
  cmp r4, r5
  beq blink_code_point_loop_end
  add r4, #4
  ldr r6, [r0, r4]
  cmp r6, #0
  beq blink_code_point_if_dot
  cmp r6, #1
  beq blink_code_point_if_dash
blink_code_point_if_dot:
  push {lr}
  bl blink_dot
  pop {lr}
  b blink_code_point_loop_start

blink_code_point_if_dash:
  push {lr}
  bl blink_dash
  pop {lr}
  b blink_code_point_loop_start

blink_code_point_loop_end:
  pop {r4-r6}
  bx lr
.size blink_codepoint, .-blink_codepoint

.type blink_dot, %function
@ Blinks leds for one dot length and pause one dot length
@ --parameters--
@ none
@ --return--
@ none
blink_dot:
  nop
  push {lr}
  bl leds_on
  pop {lr}
  
  push {lr}
  bl pause_dot
  pop {lr}

  push {lr}
  bl leds_off
  pop {lr}
    
  push {lr}
  bl pause_dot
  pop {lr}

  bx lr
.size blink_dot, .-blink_dot

.type blink_dash, %function
@ Blinks leds for three dot lengths and pause one dot length
@ --parameters--
@ none
@ --return--
@ none
blink_dash:
  push {lr}
  bl leds_on
  pop {lr}

  push {r4, r5}
  mov r5, #3
  mov r4, 0
blink_dash_loop_start:
  cmp r4, r5
  beq blink_dash_loop_end

  push {lr}
  bl pause_dot
  pop {lr}

  add r4, #1
  b blink_dash_loop_start
blink_dash_loop_end:
  pop {r4, r5}

  push {lr}
  bl leds_off
  pop {lr}

  push {lr}
  bl pause_dot
  pop {lr}

  bx lr
.size blink_dash, .-blink_dash

.type blink_space, %function
@ Doesn't blinks leds for seven dash length
@ --parameters--
@ none
@ --return--
@ none
blink_space:
  push {r4, r5}
  mov r5, #7
  mov r4, 0
blink_space_loop_start:
  cmp r4, r5
  beq blink_space_loop_end
  push {lr}
  bl pause_dot
  pop {lr}
  add r4, #1
  b blink_space_loop_start
blink_space_loop_end:
  pop {r4, r5}
  bx lr
.size blink_dash, .-blink_dash

.type leds_on, %function
leds_on:
  ldr r0, =0b01010
  push {lr}
  bl write_row_pins
  pop {lr}
  ldr r0, =0b10101
  push {lr}
  bl write_column_pins
  pop {lr}
  bx lr
.size leds_on, .-leds_on

.type leds_off, %function
leds_off:
  ldr r0, =0b00000
  push {lr}
  bl write_row_pins
  pop {lr}
  ldr r0, =0b11111
  push {lr}
  bl write_column_pins
  pop {lr}
  bx lr
.size leds_off, .-leds_off

.type pause_dot, %function
pause_dot:
  push {r4, r5}
  ldr r5, =cycle
  ldr r5, [r5]
  ldr r4, =0
pause_dot_loop_start:
  cmp r4, r5
  beq pause_dot_loop_end
  add r4, #1
  b pause_dot_loop_start
pause_dot_loop_end:
  pop {r4, r5}
  bx lr
.size pause_dot, .-pause_dot

.data
cycle:
.word 0x400000

.data
input_string:
.asciz "INPUT STRING"

@ to make sure our table starts on a word boundary
.align 2

@ Each entry in the table is 6 words long
@ - The first word is the number of dots and dashes for this entry
@ - The next 5 words are 0 for a dot, 1 for a dash, or padding (value doesn't matter)
@
@ E.g., 'G' is dash-dash-dot. There are 2 extra words to pad the entry size to 6 words
morse_table:
  .word 2, 0, 1, 0, 0, 0 @ A
  .word 4, 1, 0, 0, 0, 0 @ B
  .word 4, 1, 0, 1, 0, 0 @ C
  .word 3, 1, 0, 0, 0, 0 @ D
  .word 1, 0, 0, 0, 0, 0 @ E
  .word 4, 0, 0, 1, 0, 0 @ F
  .word 3, 1, 1, 0, 0, 0 @ G
  .word 4, 0, 0, 0, 0, 0 @ H
  .word 2, 0, 0, 0, 0, 0 @ I
  .word 4, 0, 1, 1, 1, 0 @ J
  .word 3, 1, 0, 1, 0, 0 @ K
  .word 4, 0, 1, 0, 0, 0 @ L
  .word 2, 1, 1, 0, 0, 0 @ M
  .word 2, 1, 0, 0, 0, 0 @ N
  .word 3, 1, 1, 1, 0, 0 @ O
  .word 4, 0, 1, 1, 0, 0 @ P
  .word 4, 1, 1, 0, 1, 0 @ Q
  .word 3, 0, 1, 0, 0, 0 @ R
  .word 3, 0, 0, 0, 0, 0 @ S
  .word 1, 1, 0, 0, 0, 0 @ T
  .word 3, 0, 0, 1, 0, 0 @ U
  .word 4, 0, 0, 0, 1, 0 @ V
  .word 3, 0, 1, 1, 0, 0 @ W
  .word 4, 1, 0, 0, 1, 0 @ X
  .word 4, 1, 0, 1, 1, 0 @ Y
  .word 4, 1, 1, 0, 0, 0 @ Z