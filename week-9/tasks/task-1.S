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
.set NVIC_ICER0, 0xE000E180
.set NVIC_ICPR0, 0xE000E280

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

  push {lr} 
  bl setupSYSTICK
  pop {lr}

  @ initial blink time
  ldr r4, =ONE_SECOND

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
  b loop

.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:

  push {lr}
  bl led_center_blink
  pop {lr}

  @ setup a breakpoint here to check when the interrupt occurs.
  @ reduce blink delay by half
  lsr r4, r4, 1

  @ @ reduce blink delay by -20%
  @ mov r5, 8
  @ mul r4, r4, r5
  @ mov r5, 10
  @ udiv r4, r4, r5

  @ clear event for button A
  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, =0
  str r1, [r0]
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
  @ enable GPIOTE (interrupt #6 = NVIC_GPIOTE_ID) in NVIC_ISER0
  @ NVIC_ISER0: B3.4.4 in ARMv7-M Reference Manual
  ldr r0, =NVIC_ISER0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

  @ clear GPIOTE and NVIC pending interrupt
  @ NVIC_ICPR0: B3.4.7 in ARMv7-M Reference Manual
  ldr r0, =NVIC_ICPR0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

  @ delay leds blink
  mov r0, r4

  push {r1-r2, lr}
  bl leds_blink
  pop {r1-r2, lr}

  @ 3: disable GPIOTE (interrupt #6 = NVIC_GPIOTE_ID) in NVIC_ICER0
  @ NVIC_ICER0: B3.4.5 in ARMv7-M Reference Manual
  ldr r0, =NVIC_ICER0
  ldr r1, =(1 << 6) @ set the 6th bit since NVIC_GPIOTE_ID = 6
  str r1, [r0]

  bx lr
.size SysTick_Handler, .-SysTick_Handler

.type leds_blink, %function
leds_blink:

  push {r0, lr}
  bl leds_toggle
  pop {r0, lr}

  push {lr}
  bl delay
  pop {lr}

  push {r0, lr}
  bl leds_toggle
  pop {r0, lr}

  bx lr
.size leds_blink, .-leds_blink

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

.type led_center_blink, %function
led_center_blink:

  push {r0, lr}
  bl led_center_toggle
  pop {r0, lr}

  ldr r0, =FIFTY_MILLISECONDS

  push {lr}
  bl delay
  pop {lr}

  push {r0, lr}
  bl led_center_toggle
  pop {r0, lr}

  bx lr
.size led_center_blink, .-led_center_blink

.type led_center_toggle, %function
led_center_toggle:
  push {lr}
  bl read_row
  pop {lr}

  eor r0, r0, 0b00100
  push {lr}
  bl write_row_pins
  pop {lr}

  push {lr}
  bl read_column
  pop {lr}

  eor r0, r0, 0b00100
  push {lr}
  bl write_column_pins
  pop {lr}

  bx lr
.size led_center_toggle, .-led_center_toggle

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
  @ cycles repeating 100 times
  mov r2, 100

  bx lr
.size setupSYSTICK, .-setupSYSTICK

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
