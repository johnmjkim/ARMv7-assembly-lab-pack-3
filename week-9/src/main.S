.syntax unified
.global main

.type main, %function
main:
  nop
  @ 0: init leds
  push {lr} 
  bl init_leds
  pop {lr}

  push {lr} 
  bl setupGPIOTE
  pop {lr}

  @ 3: disable GPIOTE (interrupt #6 = NVIC_GPIOTE_ID) in NVIC_ICER0
  @ NVIC_ICER0: B3.4.5 in ARMv7-M Reference Manual
  ldr r0, =NVIC_ICER0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

  push {lr} 
  bl setupSYSTICK
  pop {lr}

  @ initial blink time
  ldr r4, =ONE_SECOND

  @ initial player A, B score
  mov r6, 5
  mov r7, 5

  b loop
.size main, .-main

loop:
  @ get SYST_CSR COUNTFLAG - bit 16
  ldr r0, =SYST_CVR
  ldr r1, [r0]

  ldr r0, =SYST_CSR
  ldr r3, [r0]

  @ compare SYST_CSR COUNTFLAG is 1 or 0
  lsr r3, r3, 16
  cmp r3, 1
  IT EQ
  subeq r2, r2, 1

  push {lr}
  cmp r2, 0
  IT EQ
  bleq SysTick_Handler
  pop {lr} 

  cmp r2, 0
  IT EQ
  moveq r2, 100

  push {lr}
  bl display_A_score
  pop {lr}

  push {lr}
  bl display_B_score
  pop {lr}

  cmp r6, 0
  beq end

  cmp r7, 0
  beq end

  b loop

end:
  nop
  b end

.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
  nop
  add r6, 1
  sub r7, 1

  @ reduce blink delay by -20%
  mov r5, 8
  mul r4, r4, r5
  mov r5, 10
  udiv r4, r4, r5

  @ clear event for button A
  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, =0
  str r1, [r0]

  ldr r0, =0x10
  push {lr}
  bl delay
  pop {lr}
  nop
  bx lr
.size GPIOTE_IRQHandler, .-GPIOTE_IRQHandler

.global SysTick_Handler
.type SysTick_Handler, %function
@ Interrupts and toggle led
@ --parameters--
@ none
@ --return--
@ none
SysTick_Handler:
  nop
  @ clear GPIOTE and NVIC pending interrupt
  @ clear event for button A
  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, =0
  str r1, [r0]

  @ NVIC_ICPR0: B3.4.7 in ARMv7-M Reference Manual
  ldr r0, =NVIC_ICPR0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

  @ enable GPIOTE (interrupt #6 = NVIC_GPIOTE_ID) in NVIC_ISER0
  @ NVIC_ISER0: B3.4.4 in ARMv7-M Reference Manual
  ldr r0, =NVIC_ISER0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

  @ delay leds blink
  mov r0, r4

  @ led blinks at center
  push {r1-r2, lr}
  bl led_center_blink
  pop {r1-r2, lr}

  @ 3: disable GPIOTE (interrupt #6 = NVIC_GPIOTE_ID) in NVIC_ICER0
  @ NVIC_ICER0: B3.4.5 in ARMv7-M Reference Manual
  ldr r0, =NVIC_ICER0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

  bx lr
.size SysTick_Handler, .-SysTick_Handler

.type led_center_blink, %function
led_center_blink:
  push {r0, lr}
  mov r0, 2
  mov r1, 2
  bl led_on
  pop {r0, lr}

  push {lr}
  bl delay
  pop {lr}

  push {r0, lr}
  bl led_off
  pop {r0, lr}

  bx lr
.size led_center_blink, .-led_center_blink

.type display_A_score, %function
@ --parameters--
@ r6: score of player A
display_A_score:
  push {r0-r3}
  ldr r2, =A_board
  mov r3, 0
display_A_score_loop:
  cmp r3, r6
  beq display_A_score_end

  ldr r0, [r2, r3, lsl 2]
  add r3, #10
  ldr r1, [r2, r3, lsl 2]
  sub r3, #10

  push {r2, r3, lr}
  bl led_blink
  pop {r2, r3, lr}

  add r3, r3, 1

  b display_A_score_loop

display_A_score_end:
  pop {r0-r3}
  bx lr
.size display_A_score, .-display_A_score

.type display_B_score, %function
@ --parameters--
@ r7: score of player B
display_B_score:
  push {r0-r3}
  ldr r2, =B_board
  mov r3, 0
display_B_score_loop:
  cmp r3, r7
  beq display_B_score_end

  ldr r0, [r2, r3, lsl 2]
  add r3, #10
  ldr r1, [r2, r3, lsl 2]
  sub r3, #10

  push {r2, r3, lr}
  bl led_blink
  pop {r2, r3, lr}

  add r3, r3, 1

  b display_B_score_loop

display_B_score_end:
  pop {r0-r3}
  bx lr
.size display_B_score, .-display_B_score

.type led_blink, %function
@ --parameters--
@ r0: row index (0-4 with 0 being the top row)
@ r1: column index (0-4 with 0 being the left most column)
@ --return--
@ none
led_blink:
  push {lr}
  bl led_on
  pop {lr}

  push {lr}
  bl led_off
  pop {lr}

  bx lr
.size led_blink, .-led_blink

.type led_on, %function
@ --parameters--
@ r0: row index (0-4 with 0 being the top row)
@ r1: column index (0-4 with 0 being the left most column)
@ --return--
@ none
led_on:
  push {r2}
  ldr r2, =0b1
  lsl r0, r2, r0
  push {r1, lr}
  bl write_row_pins
  pop {r1, lr}

  ldr r2, =0b1
  lsl r1, r2, r1
  ldr r0, =0b11111
  eor r0, r0, r1
  push {lr}
  bl write_column_pins
  pop {lr}

  pop {r2}

  bx lr
.size led_on, .-led_on

.type led_off, %function
@ Interrupts and toggle led
@ --parameters--
@ none
@ --return--
@ none
led_off:
  push {r2}
  ldr r0, =0b00000
  push {lr}
  bl write_row_pins
  pop {lr}

  ldr r0, =0b11111
  push {lr}
  bl write_column_pins
  pop {lr}
  pop {r2}

  bx lr
.size led_off, .-led_off

.type setupGPIOTE, %function
setupGPIOTE:
  @ 1: Configure GPIOTE_CONFIG[0]
  @ Need to setup: mode, pin, port, polarity in the configuration register for GPIOTE[0]
  @ Section 6.9.4.8 in nRF52833 reference manual
  @ mode = 1 (event), pin = 14 and port = 0 (P0.14 = Button A), polarity = 1 (LoToHi)
  ldr r0, =GPIOTE_CONFIG0
  ldr r1, =(1 | 14 << 8 | 0 << 13 | 1 << 16)
  str r1, [r0]

  @ 2: Enable Interrupt for GPIOTE[0] (id = 6)
  @ S6.9.4.6 in nRF52833 reference manual
  ldr r0, =GPIOTE_INTENSET
  ldr r1, =0b1
  str r1, [r0]

  @ 3: enable GPIOTE (interrupt #6 = NVIC_GPIOTE_ID) in NVIC_ISER0
  @ NVIC_ISER0: B3.4.4 in ARMv7-M Reference Manual
  ldr r0, =NVIC_ISER0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

  @ 4: set priority of GPIOTE
  @ NVIC_IPR1: B3.4.9 in ARMv7-M Reference Manual
  ldr r0, =NVIC_IPR1
  ldr r1, =(1 << 21) @ set the 21-23th bit priority 1 (higher priority)
  str r1, [r0]

  bx lr
.size setupGPIOTE, .-setupGPIOTE

.type setupSYSTICK, %function
setupSYSTICK:
  @ set SYST_CSR ENABLE - bit 0
  @ set SYST_CSR CLKSOURCE - bit 2
  ldr r0, =SYST_CSR
  ldr r1, =(1 << 0 | 1 << 2)
  str r1, [r0]

  @ we should blink the LED with 5 seconds period
  @ count down from FIFTY_MILLISECONDS (3.2M =0x30D400) cycles repeating 100 times
  ldr r0, =SYST_RVR
  ldr r1, =FIFTY_MILLISECONDS
  str r1, [r0]

  @ set priority of SYSTICK
  @ SHPR3: B3.2.12 in ARMv7-M Reference Manual
  ldr r0, =SHPR3
  ldr r1, =(1 << 30) @ set the 29-31th bit priority 2 (lower priority)
  str r1, [r0]

  @ cycles repeating 100 times
  mov r2, 100

  bx lr
.size setupSYSTICK, .-setupSYSTICK

.data
A_board:
.word 0, 1, 2, 3, 4, 0, 1, 2, 3, 4
.word 0, 0, 0, 0, 0, 1, 1, 1, 1, 1

B_board:
.word 4, 3, 2, 1, 0, 4, 3, 2, 1, 0
.word 4, 4, 4, 4, 4, 3, 3, 3, 3, 3

.data
.set ONE_MILLISECONDS, 0x9C400 @ 0.64M cycles
.set FIFTY_MILLISECONDS, 0x30D400 @ 3.2M cycles
.set ONE_SECOND, 0x3D09000 @ 64M cycles
.set HUNDRED_MILLISECONDS, 0x61A800 @ 6.4M cycles

@ SysTick register
.set SYST_CSR, 0xE000E010
.set SYST_RVR, 0xE000E014
.set SYST_CVR, 0xE000E018
.set SYST_CALIB, 0xE000E01C
.set SHPR3, 0xE000ED20

@ GPIOTE Constants
.set GPIOTE_EVENTS_IN0, 0x40006100
.set GPIOTE_EVENTS_IN1, 0x40006104
.set GPIOTE_INTENSET, 0x40006304
.set GPIOTE_CONFIG0, 0x40006510
.set GPIOTE_CONFIG1, 0x40006514

@ NVIC Constants
.set NVIC_ISER0, 0xE000E100
.set NVIC_ICER0, 0xE000E180
.set NVIC_ICPR0, 0xE000E280
.set NVIC_IPR1, 0xE000E404