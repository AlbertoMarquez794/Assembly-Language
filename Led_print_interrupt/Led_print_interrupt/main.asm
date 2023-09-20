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

;Configuracion de las interrepciones de overflow de temporizadores 0 y 1
.org OVF0addr
     jmp TIM0_OVF
.org OVF1addr
     jmp TIM1_OVF

.org 0x40
main: 
	call serial_init
	ldi r16, high(ramend) ;Carga el valor alto de la direccion de memoria RAM
	out sph, r16 ;Almacena el contenido de r16 en el registro SPH
	ldi r16, low(ramend) ;Carga el valor bajon de la direccion de memoria RAM en r16
	out spl, r16 ;Utiliza para apuntar a la parte baja de la pila en la memoria RAM

	; Configurar el bit 5 del puerto B como salida y establecerlo en alto (1) 
	sbi ddrb, 5
	sbi portb, 5

	; Configurar el bit 4 del puerto D como salida y establecerlo en alto (1)
	sbi ddrd, 4
	sbi portd, 4

	; Cargar valores específicos en registros
	ldi r20, 0xFF ; R20 = 255
	ldi r21, 0x3C ; R21 = 60 [0011 1100]

	; Almacenar los valores en los registros TCNT1H y TCNT1L del temporizador 1
	sts TCNT1H, r20 ;TCNT1H = 255
	sts TCNT1L, r21 ;TCNT1L = 60
	;TCNT1H 1 1 1 1 1 1 1 1
	;TCNT1L 1 1 1 1 0 0 0 0
	;En este caso, se carga 255 (0xFF) en TCNT1H y 60 (0x3C) en TCNT1L. 
	;Esto significa que el temporizador 1 comenzará a contar desde 0xFF3C 
	;(255 en TCNT1H y 60 en TCNT1L) y contará hacia arriba hasta 0xFFFF
	;antes de desbordarse.
	; Cargar el valor 0xFD en el registro r23
	ldi r23, 0xFD ;r23 = 253

	; Escribir el valor en el registro TCNT0 del temporizador 0
	out TCNT0, r23 ;TCNT0 = 0000 0000l 
	;++++++++++++++++++++++++++++++++++++++++++
	;Todo esto es del contador 1
	;Este parte es la que enciende el led
	ldi r16, 32          ; Cargar el valor 32 en el registro r16
	out portb, r16       ; Escribir el valor de r16 en el registro PORTB
	;Escribir el valor 32 en el registro 16. El bit 5 de PORTB se establece en alto, lo que significa que el LED
	;conectado al 
    ldi r16, 16          ; Cargar el valor 16 en el registro r16
    out portd, r16       ; Escribir el valor de r16 en el registro PORTD
	;TCCR1A-TCCR1B, TCCR1C son registros de control del Timer1/Timer2
	ldi r20, 0x00        ; Cargar el valor 0 en el registro r20
	ldi r21, (1<<CS12)|(1<<CS10) ; Cargar el valor binario 00000101 (9) en r21
	sts TCCR1A, r20      ; Almacenar el valor de r20 en el registro TCCR1A 0
	sts TCCR1B, r21      ; Almacenar el valor de r21 en el registro TCCR1B 9
	; 0 0 0 0 0 1 0 1
	; CS12 = 1
	; CS10 = 1
	; Caso = 101
	;clk/1024 (from prescaler)7
	; El TCCR1B se configura como un prescaler en 1024. El timer 1 contará pulsos de reloj del sistema divididos por un factor de 1024
	;++++++++++++++++++++++++++++++++++++++++++++
	ldi r20, 0x00        ; Cargar el valor 0 en el registro r20
	out TCCR0A, r20      ; Escribir el valor de r20 en el registro TCCR0A (Timer/Counter 1 Control Register A) registro para controlar el Timer/Counter1
	ldi r21, (1<<CS02)|(1<<CS01) ; Cargar el valor binario 00000110 en r21
	;	CS02 = 1
	; CS01 = 1
	; 0 0 0 0 0 1 1 0
	; El timer 0 se esta usando como contador y obtiene pulsos de una fuente externa
	out TCCR0B, r21      ; Escribir el valor de r21 en el registro TCCR0B, 6
	;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	;Esta parte es la interrùpción
	ldi r20, 0x00        ; Cargar el valor 0 en el registro r20
	;Normal port operation, OC0A disconnected
	;Estás deshabilitando todas las funciones especiales
	ldi r20, (1<<TOIE0)  ; Cargar el valor binario 00000001 en r20
	; 0 0 0 0 0 0 0 1
	sts TIMSK0, r20      ; Almacenar el valor de r20 en el registro TIMSK0
	;activa la interrupción
	;TIMSK0: este registro es para activar las interrupciones. 
	;Si el bit 0 está activo signifca que está permitido las interrupciones de overflow. 
	;Si el bit 1 está activo, significa que cuando se compare el valor del OCR0A y TCNT0, y sean iguales, 
	;entonces se disparará una interrupción. Igualmente si está en 1 el bit 3, ocurre lo mismo pero con el OCR0B.
	;relacionadas con el Timer/Counter0 (Temporizador/Contador 0).
	;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	ldi r20, 0x00        ; Cargar el valor 0 en el registro r20
	ldi r20, (1<<TOIE1)  ; Cargar el valor binario 00000001 en r20
	sts TIMSK1, r20      ; Almacenar el valor de r20 en el registro TIMSK1, significa que el desbordamiento está activo
	;El registro TIMSK1 (Timer/Counter1 Interrupt Mask Register) es un registro de configuración utilizado 
	;en los microcontroladores AVR, como el ATmega328P, para habilitar o deshabilitar interrupciones 
	;relacionadas con el Timer/Counter1 (Temporizador/Contador 0).

	sei                  ; Habilitar las interrupciones globales

	here:
		jmp here             ; Bucle infinito, salta a sí mismo repetidamente

	;Ocurre cuando hay oveflow del temporizador 1
	.org 0x0100
	TIM0_OVF:
		in r16, portb        ; Leer el valor del registro PORTB en r16
		ldi r17, 32          ; Cargar el valor 32 en el registro r17
		eor r16, r17         ; Realizar una operación XOR entre r16 y r17
		;Cambias el quinto bit de estado alto a bajo y viceversa
		out portb, r16       ; Escribir el resultado de vuelta en el registro PORTB
		ldi r23, 0xFD        ; Cargar el valor 0xFD (253, 1111 1101 ) en r23
		out TCNT0, r23       ; Escribir el valor de r23 en el registro TCNT0 que es 254 y aumentará con cada puso de roloj hasta que alcance su valor maximo
		;255 y luego se desbordará
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
