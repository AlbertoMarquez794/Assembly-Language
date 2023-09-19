; Blink.asm
; Este es un comentario que describe el nombre del archivo y su propósito.
; Created: 8/22/2023 1:51:09 PM
; Author : hugor
; Estos comentarios indican la fecha de creación y el autor del código.

; Replace with your application code
; Esto es un marcador de posición que sugiere que aquí se debe colocar el código de la aplicación real.

.include "m328pdef.inc"
; Esta línea incluye el archivo de definición "m328pdef.inc", que contiene definiciones de registros y constantes para el microcontrolador ATmega328P.

; Configura el puntero de pila para el final de la RAM
ldi r16, high(ramend)
out sph, r16
ldi r16, low(ramend)
out spl, r16
; Estas líneas configuran el puntero de pila (stack pointer) al final de la memoria RAM del microcontrolador ATmega328P.

; Carga 0x00 en el registro R21
ldi r21, 0x00 ; R21 = 0000 0000 (Estado inicial)
out ddrb, r21 ; Configura todos los pines del puerto B como entradas (0, inicializar los pines)
sbi ddrb, 5 ; Configura el quinto bit del puerto B (PB5) como salida (1)
sbi portb, 5 ; Establece el quinto bit del puerto B (PB5) en alto para encender un LED
; Estas líneas inicializan el registro DDRB para configurar el pin 5 (PB5) como una salida digital y luego establecen un nivel alto en ese pin utilizando el registro PORTB.
BLK1:
	; Etiqueta del bucle principal
	; 0x55 (0101 0101)
	ldi r16, 0x55 ; Carga el valor 0x55 (85) en el registro R16
	out portb, r16 ; Establece los bits del puerto B según el valor en R16 (0 1 0 1 0 1 0 1)
	;Establece los bits de PBO a PB7 segun los bits de R16. 
	rcall delay_2 ; Llama a la subrutina "delay_2" para crear un retardo
	ldi r16, 0xAA ; Carga el valor 0xAA en el registro R16 (170) (1 0 1 0 1 0 1 0) 
	out portb, r16 ; Establece los bits del puerto B según el valor en R16
	rcall delay_2 ; Llama a la subrutina "delay_2" para crear otro retardo
	rjmp BLK1 ; Salta de nuevo a la etiqueta "BLK1" para repetir el proceso
; Este código parpadea el pin 5 alternando entre los valores 0x55 y 0xAA utilizando registros y llamadas a la rutina de retraso "delay_2".

delay:
	ldi r20, 0xF2  ;Carga el valor OxF2 (242= en el registro 20 ¿Es nuestro limite?
	out tcnt0, r20 ;Esta parte va ser nuestro limite de desbordamiento
	ldi r20, 0b00000010 ;R20 = 2 en decimal
	out tccr0b, r20 ;Tomamos los ultimos 3 bits 0-1-0
	;Se toma como escalamiento
	again: 
	in r20, tifr0 ;Lee el registro de banderas de interrupciones del timer 0
	sbrs r20, tov0 ; Salta si el bit TOV0 esta claro, es decir, igual a cero
	rjmp again
	ldi r20, 0x00 ;r20 = 0x00
	out tccr0b, r20 ;Restablece el registro de control del TIMER a cero
	ldi r20, (1<<tov0) ;Carca el valor donde tov0 es el bit que representa el desbordamiento
	out tifr0, r20 ;limpia la bandera
	ret ;retorno de la funcion
; Esta es la rutina de retraso "delay" utilizando el temporizador 0 (Timer 0) del ATmega328P. Espera hasta que se desborde el temporizador.

delay_1:
	ldi r20, 50
	L1: ldi r21, 150
	L2: ldi r22, 250
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
; Esta es otra rutina de retraso "delay_1" que realiza un retardo mediante bucles anidados.

delay_2: ;Con bandera de desbordamiento
	ldi r20, 0xFF ;R20 = 255
	ldi r21, 0x3C ;R21 = 60
	; Configuración de los registros TCNT1H y TCNT1L del Timer1/Counter1 (Temporizador/Contador1).
	;TCNT1H generalmente almacena los bits más significativos del timer 1
	;TCNT1L se almacena generalmente los bits menos significativos
	sts TCNT1H, r20  ; Almacena el contenido del registro r20 en TCNT1H (parte alta).
	sts TCNT1L, r21  ; Almacena el contenido del registro r21 en TCNT1L (parte baja).
	ldi r20, 0x00   ; Carga el valor 0x00 en el registro r20.
	ldi r21, 0x05   ; Carga el valor 0x05 en el registro r21.
	; Configuración de los registros de control del Timer1/Counter1 para el modo CTC y el preescalado.
	
	;Registros de control para poder configurar el timer en modo CTC y el pre-escalado
	sts tccr1a, r20  ;tccr1a = 0x00 = 0
	sts tccr1b, r21 ;tccr1b = 0x05 = 5
	;El timer se configurara para contar hacia atras desde este valor hasta cero
	;tov1 es la bandera de desbordamiento
	again_1: 
		;Todo este ciclo de ejecucion está en torno al timer 1
		in r20, tifr1 ;Registro de banderas de interrupción del Timer 1
		sbrs r20, tov1 ;Si el bit 'TOV1' está establecido (0) no salta, en caso contrario es que ha surgido un desbordamiento  
		rjmp again_1
		;Inicializas todo en cero para poder utilizar en algun momento
		ldi r20, 0x00
		sts tccr1a, r20
		sts tccr1b, r20
		ldi r20, 0x01
		out tifr1, r20
		ret
; Esta es la rutina de retraso "delay_2" que utiliza el temporizador 1 (Timer 1) del ATmega328P para generar un retardo.

