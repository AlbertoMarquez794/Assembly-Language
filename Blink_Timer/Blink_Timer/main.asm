;
; Blink.asm
;
; Created: 8/22/2023 1:51:09 PM
; Author : hugor
;


; Replace with your application code

.include "m328pdef.inc"

ldi r16, high(ramend)
out sph, r16
ldi r16, low(ramend)
out spl, r16

ldi r21, 0x00
out ddrb, r21
sbi ddrb, 5
sbi portb, 5
BLK1: ldi r16, 0x55
      out portb, r16
	  rcall delay_2
	  ldi r16, 0xAA
	  out portb, r16
	  rcall delay_2
	  rjmp BLK1

delay: 
     ldi r20, 0xF2
	 out tcnt0, r20
	 ldi r20, 0b00000010
	 out tccr0b, r20
again: in r20, tifr0
       sbrs r20, tov0
	   rjmp again
	   ldi r20, 0x00
	   out tccr0b, r20
	   ldi r20, (1<<tov0)
	   out tifr0, r20
	   ret
	
delay_1: 
     ldi r20, 50
L1:  ldi r21, 150
L2:  ldi r22, 250
L3: 
     nop
	 nop
	 dec r22
	 brne L3

	 dec r21
	 brne L2

	 dec r20
	 brne L1
	 ret   


delay_2: ldi r20, 0xFF
         ldi r21, 0x3C
         sts TCNT1H,r20
         sts TCNT1L,r21
		 ldi r20, 0x00
		 ldi r21, 0x05
		 sts tccr1a, r20
		 sts tccr1b, r21
again_1: in r20, tifr1
         sbrs r20, tov1
		 rjmp again_1
		 ldi r20, 0x00
		 sts tccr1a, r20
		 sts tccr1b, r20
		 ldi r20, 0x01
		 out tifr1, r20
		 ret
