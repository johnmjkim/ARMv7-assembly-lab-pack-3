.syntax unified
.global main
@ SYSTICK Constants
.set SHPR3, 0xE000ED20

@ GPIOTE Constants
.set GPIOTE_EVENTS_IN0, 0x40006100
.set GPIOTE_INTENSET, 0x40006304
.set GPIOTE_CONFIG0, 0x40006510

@ NVIC Constants
.set NVIC_ISER0, 0xE000E100
.set NVIC_IPR1, 0xE000E404

.type main, %function
main:
  nop
  push {lr} 
  bl init_leds
  pop {lr}

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

  @ set SYST_CSR ENABLE - bit 0
  @ set SYST_CSR CLKSOURCE - bit 2
  ldr r0, =SYST_CSR
  ldr r1, =(1 << 0 | 1 << 2)
  str r1, [r0]

  @ we should toggle the LED for 1 HZ
  @ two toggles must be done in 64M cycles
  @ one toggle must be done in 32M cycles
  @ count down from ONETENTH_TOGGLE (3.2M =0x30D400) cycles repeating 10 times
  ldr r0, =SYST_RVR
  ldr r1, =ONETENTH_TOGGLE
  str r1, [r0]

  @ @ set priority of SYSTICK
  @ @ SHPR3: B3.2.12 in ARMv7-M Reference Manual
  @ ldr r0, =SHPR3
  @ ldr r1, =(1 << 29) @ set the 29-31th bit priority 1 (lower priority)
  @ str r1, [r0]

  mov r2, 10

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
  moveq r2, 10

  b loop

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

  ldr r0, =0x10
  push {lr}
  bl delay
  pop {lr}

  bx lr
.size GPIOTE_IRQHandler, .-GPIOTE_IRQHandler

@ .global SysTick_Handler
@ .type SysTick_Handler, %function
@ @ Interrupts and toggle led
@ @ --parameters--
@ @ none
@ @ --return--
@ @ none
@ SysTick_Handler:
@   nop

@   push {r1-r2, lr}
@   bl leds_toggle
@   pop {r1-r2, lr}

@   bx lr
@ .size SysTick_Handler, .-SysTick_Handler

.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
  mov r0, 0b01111
  bl write_column_pins
  mov r0, 0b10000
  bl write_row_pins
SysTick_Handler_infloop:
  nop
  b SysTick_Handler_infloop
.size SysTick_Handler, .-SysTick_Handler

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

.data
.set ONE_TOGGLE, 0x1E84800 @ 32M cycles
.set ONETENTH_TOGGLE, 0x30D400 @ 3.2M cycles

@ SysTick register
.set SYST_CSR, 0xE000E010
.set SYST_RVR, 0xE000E014
.set SYST_CVR, 0xE000E018
.set SYST_CALIB, 0xE000E01C
