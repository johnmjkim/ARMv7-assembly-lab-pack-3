.syntax unified
.global main

.type main, %function
main:
  nop
  bl init_leds
  b loop
.size main, .-main

loop:
  bl blink_dot
  bl blink_dot
  bl blink_dot
  bl blink_dash
  bl blink_dash
  bl blink_dash
  b loop

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