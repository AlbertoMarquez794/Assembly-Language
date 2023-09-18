;
; Led_print_interrupt.asm
;
; Created: 9/14/2023 9:03:41 AM
; Author : hugor
;


; Replace with your application code
.include "m328pdef.inc"
.org 0x00
     jmp main
.org OVF0addr
     jmp TIM0_OVF
.org OVF1addr
     jmp TIM1_OVF

.org 0x40
main: call serial_init

	ldi r16, high(ramend) ;Carga el valor alto de la direccion de memoria RAM
	out sph, r16 ;Almacena el contenido de r16 en el registro SPH
	ldi r16, low(ramend) ;Carga el valor bajon de la direccion de memoria RAM en r16
	out spl, r16 ;Utiliza para apuntar a la parte baja de la pila en la memoria RAM

	; Configurar el bit 5 del puerto B como salida y establecerlo en alto
	sbi ddrb, 5
	sbi portb, 5

	; Configurar el bit 4 del puerto D como salida y establecerlo en alto
	sbi ddrd, 4
	sbi portd, 4

	; Cargar valores específicos en registros
	ldi r20, 0xFF ; R20 = 255
	ldi r21, 0x3C ; R21 = 60

	; Almacenar los valores en los registros TCNT1H y TCNT1L del temporizador 1
	sts TCNT1H, r20
	sts TCNT1L, r21

	; Cargar el valor 0xFD en el registro r23
	ldi r23, 0xFD ;r23 = 253

	; Escribir el valor en el registro TCNT0 del temporizador 0
	out TCNT0, r23


	ldi r16, 32          ; Cargar el valor 32 en el registro r16
	out portb, r16       ; Escribir el valor de r16 en el registro PORTB
    ldi r16, 16          ; Cargar el valor 16 en el registro r16
    out portd, r16       ; Escribir el valor de r16 en el registro PORTD

	ldi r20, 0x00        ; Cargar el valor 0 en el registro r20
	ldi r21, (1<<CS12)|(1<<CS10) ; Cargar el valor binario 00001001 en r21
	sts TCCR1A, r20      ; Almacenar el valor de r20 en el registro TCCR1A 0
	sts TCCR1B, r21      ; Almacenar el valor de r21 en el registro TCCR1B 5

	ldi r20, 0x00        ; Cargar el valor 0 en el registro r20
	out TCCR0A, r20      ; Escribir el valor de r20 en el registro TCCR0A (Timer/Counter 1 Control Register A) registro para controlar el Timer/Counter1
	ldi r21, (1<<CS02)|(1<<CS01) ; Cargar el valor binario 00000110 en r21
	out TCCR0B, r21      ; Escribir el valor de r21 en el registro TCCR0B, 6

	ldi r20, 0x00        ; Cargar el valor 0 en el registro r20
	ldi r20, (1<<TOIE0)  ; Cargar el valor binario 00000001 en r20
	sts TIMSK0, r20      ; Almacenar el valor de r20 en el registro TIMSK0

	;El registro TIMSK0 (Timer/Counter0 Interrupt Mask Register) es un registro de configuración utilizado 
	;en los microcontroladores AVR, como el ATmega328P, para habilitar o deshabilitar interrupciones 
	;relacionadas con el Timer/Counter0 (Temporizador/Contador 0).

	ldi r20, 0x00        ; Cargar el valor 0 en el registro r20
	ldi r20, (1<<TOIE1)  ; Cargar el valor binario 00000001 en r20
	sts TIMSK1, r20      ; Almacenar el valor de r20 en el registro TIMSK1
	;El registro TIMSK1 (Timer/Counter1 Interrupt Mask Register) es un registro de configuración utilizado 
	;en los microcontroladores AVR, como el ATmega328P, para habilitar o deshabilitar interrupciones 
	;relacionadas con el Timer/Counter1 (Temporizador/Contador 0).

	sei                  ; Habilitar las interrupciones globales

	here:
		jmp here             ; Bucle infinito, salta a sí mismo repetidamente

	.org 0x0100
	TIM0_OVF:
		in r16, portb        ; Leer el valor del registro PORTB en r16
		ldi r17, 32          ; Cargar el valor 32 en el registro r17
		eor r16, r17         ; Realizar una operación XOR entre r16 y r17
		out portb, r16       ; Escribir el resultado de vuelta en el registro PORTB
		ldi r23, 0xFD        ; Cargar el valor 0xFD en r23
		out TCNT0, r23       ; Escribir el valor de r23 en el registro TCNT0
		ldi r18, 0           ; Cargar 0 en r18 (posiblemente para algún propósito futuro)
		reti                 ; Retornar de la interrupción

	.org 0x0200
	TIM1_OVF:
		in r16, portd        ; Leer el valor del registro PORTD en r16
		ldi r17, 16          ; Cargar el valor 16 en el registro r17
		eor r16, r17         ; Realizar una operación XOR entre r16 y r17
		out portd, r16       ; Escribir el resultado de vuelta en el registro PORTD
		inc r18              ; Incrementar el valor en r18
		ori r18, 0x30        ; Realizar una operación OR con 0x30 en r18
		mov r19, r18         ; Copiar el valor de r18 en r19
		call serial_transmit ; Llamar a la función serial_transmit
		reti                 ; Retornar de la interrupción

	; Inicializar la conexión serial
	serial_init:
		ldi r16, 103         ; Cargar el valor 103 en r16
		clr r17              ; Borrar r17 (posiblemente para algún propósito futuro)
		sts 0xc5, r17        ; Almacenar el valor de r17 en la dirección 0xc5
		sts 0xc4, r16        ; Almacenar el valor de r16 en la dirección 0xc4
		ldi r16, (1<<4)|(1<<3) ; Cargar el valor binario 00011000 en r16
		sts 0xc1, r16        ; Almacenar el valor de r16 en la dirección 0xc1
		ldi r16, 0b00001110  ; Cargar el valor binario 00001110 en r16
		sts 0xc2, r16        ; Almacenar el valor de r16 en la dirección 0xc2
		ret                  ; Retornar de la función

	; Transmitir un byte almacenado en r19 por serial
	serial_transmit:
		lds r16, 0xc0        ; Leer un valor de alguna dirección específica en r16
		sbrs r16, 5          ; Saltar si el bit 5 de r16 está en 0
		rjmp serial_transmit ; Saltar de vuelta a serial_transmit si se cumple la condición anterior
		sts 0xc6, r19        ; Almacenar el valor de r19 en la dirección 0xc6
		ret                  ; Retornar de la función
