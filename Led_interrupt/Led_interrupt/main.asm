;
; Led_interrupt.asm
;
; Created: 9/13/2023 10:55:29 AM
; Author : hugor
;


; Replace with your application code
.include "m328pdef.inc"
.org 0x00
     jmp main
.org OVF1addr
     jmp TIM1_OVF

.org 0x40
main: call serial_init
      ldi r16, high(ramend)
      out sph, r16
      ldi r16, low(ramend)
      out spl, r16

      sbi ddrb, 5
      sbi portb, 5

	  ldi r20, 0x00
	  ldi r21, 0x05
	  sts TCCR1A, r20
	  sts TCCR1B, r21

	  ldi r20, 0x00
	  ldi r20, (1<<TOIE1)
	  sts TIMSK1, r20

	  sei 

	  ldi r20, 0xFF
      ldi r21, 0x3C
      sts TCNT1H,r20
      sts TCNT1L,r21

      ldi r16, 32
      out portb, r16

here: 
      jmp here


.org 0x0200
TIM1_OVF :  in r16, portb
            ldi r17, 32
			eor r16, r17
	        out portb, r16
			reti


			;initialise serial connection
serial_init:
         ldi r16, 103
         clr r17
         sts 0xc5, r17
         sts 0xc4, r16
         ldi r16, (1<<4)|(1<<3)
         sts 0xc1, r16
         ldi r16, 0b00001110
         sts 0xc2, r16
         ret
;transmit byte stored in r19 over serial
serial_transmit:
         lds r16, 0xc0
         sbrs r16, 5
         rjmp serial_transmit
         sts 0xc6, r19
         ret
;wait for byte to be sent, store it in r19 and return