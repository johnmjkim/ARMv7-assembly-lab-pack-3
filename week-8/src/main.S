.syntax unified
.global main
@ GPIOTE Constants
.set GPIOTE_EVENTS_IN0, 0x40006100
.set GPIOTE_EVENTS_IN1, 0x40006104
.set GPIOTE_INTENSET, 0x40006304
.set GPIOTE_CONFIG0, 0x40006510
.set GPIOTE_CONFIG1, 0x40006514

@ NVIC Constants
.set NVIC_ISER0, 0xE000E100

.type main, %function
main:
  @ 0: init leds
  bl init_leds
  @ 1: Configure GPIOTE_CONFIG[0]
  @ Need to setup: mode, pin, port, polarity in the configuration register for GPIOTE[0]
  @ Section 6.9.4.8 in nRF52833 reference manual
  @ mode = 1 (event), pin = 14 and port = 0 (P0.14 = Button A), polarity = 1 (LoToHi)
  ldr r0, =GPIOTE_CONFIG0
  ldr r1, =(1 | 14 << 8 | 0 << 13 | 1 << 16)
  str r1, [r0]

  @ 1: Configure GPIOTE_CONFIG[1]
  @ Need to setup: mode, pin, port, polarity in the configuration register for GPIOTE[1]
  @ Section 6.9.4.8 in nRF52833 reference manual
  @ mode = 1 (event), pin = 23 and port = 0 (P0.23 = Button B), polarity = 1 (LoToHi)
  ldr r0, =GPIOTE_CONFIG1
  ldr r1, =(1 | 23 << 8 | 0 << 13 | 1 << 16)
  str r1, [r0]

  @ 2: Enable Interrupt for GPIOTE[0], GPIOTE[1] (id = 6)
  @ S6.9.4.6 in nRF52833 reference manual
  ldr r0, =GPIOTE_INTENSET
  ldr r1, =0b11
  str r1, [r0]

  @ 3: enable GPIOTE (interrupt #6 = NVIC_GPIOTE_ID) in NVIC_ISER0
  @ NVIC_ISER0: B3.4.4 in ARMv7-M Reference Manual
  ldr r0, =NVIC_ISER0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

loop:
  nop
  b loop
.size main, .-main

.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
  @ setup a breakpoint here to check when the interrupt occurs.
  push {lr}
  bl leds_toggle
  pop {lr}
  @ clear event for button A
  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, =0
  str r1, [r0]
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  @ clear event for button B
  ldr r0, =GPIOTE_EVENTS_IN1
  ldr r1, =0
  str r1, [r0]
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  bx lr
.size GPIOTE_IRQHandler, .-GPIOTE_IRQHandler

.type leds_toggle, %function
leds_toggle:
  push {lr}
  bl read_row
  pop {lr}

  eor r0, r0, 0b01010
  push {lr}
  bl write_row_pins
  pop {lr}

  push {lr}
  bl read_column
  pop {lr}

  eor r0, r0, 0b01010
  push {lr}
  bl write_column_pins
  pop {lr}

  bx lr
.size leds_toggle, .-leds_toggle