.syntax unified
.global main

.type main, %function
main:
  nop
  push {lr} 
  bl init_leds
  pop {lr}

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
  b loop

.global SysTick_Handler
.type SysTick_Handler, %function
@ Interrupts and toggle led
@ --parameters--
@ none
@ --return--
@ none
SysTick_Handler:
  nop

  push {lr}
  bl leds_toggle
  pop {lr}

  bx lr
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
