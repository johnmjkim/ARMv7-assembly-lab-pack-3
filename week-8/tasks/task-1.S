.syntax unified
.global main

.type main, %function
main:
  nop
  ldr r0, =SYST_CSR
  @ set SYST_CSR ENABLE - bit 0
  @ set SYST_CSR CLKSOURCE - bit 2
  ldr r1, =(1 << 0 | 1 << 2)
  str r1, [r0]
  ldr r0, =SYST_RVR
  @ count down from 4000000 cycles (=0x3D0900)
  ldr r1, =0x3D0900
  str r1, [r0]

  b loop
.size main, .-main

loop:
  ldr r0, =SYST_CVR
  ldr r1, [r0]
  @ get SYST_CSR COUNTFLAG - bit 16
  ldr r0, =SYST_CSR
  ldr r2, [r0]
  @ compare SYST_CSR COUNTFLAG is 1 or 0
  lsr r2, r2, 16
  cmp r2, 1
  beq finished
  b loop

finished:
  nop
  b finished

@ SysTick register
.set SYST_CSR, 0xE000E010
.set SYST_RVR, 0xE000E014
.set SYST_CVR, 0xE000E018
.set SYST_CALIB, 0xE000E01C
