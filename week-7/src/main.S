.syntax unified
.global main

.type main, %function
main:
  nop
  bl init_leds
  b loop
.size main, .-main

loop:
  push {lr}
  bl blink_dot
  pop {lr}
  push {r4, r5}
  ldr r5, =cycle
  ldr r5, [r5]
  ldr r4, =0
pause:
  cmp r4, r5
  beq loop
  add r4, #1
  b pause

.type blink_dot, %function
@ Blinks an led
@ --parameters--
@ none
@ --return--
@ none
blink_dot:
  nop
  push {r4, r5}
  ldr r0, =0b01010
  push {lr}
  bl write_row_pins
  pop {lr}
  ldr r0, =0b10101
  push {lr}
  bl write_column_pins
  pop {lr}
  ldr r5, =cycle
  ldr r5, [r5]
  ldr r4, =0
blink_dot_loop_start:
  cmp r4, r5
  beq blink_dot_loop_end
  add r4, #1
  b blink_dot_loop_start
blink_dot_loop_end:
  pop {r4, r5}
  ldr r0, =0b00000
  push {lr}
  bl write_row_pins
  pop {lr}
  ldr r0, =0b11111
  push {lr}
  bl write_column_pins
  pop {lr}
  bx lr
.size blink_dot, .-blink_dot

.data
cycle:
.word 0x400000