;
; Multiplication.asm
;
; Created: 09/09/2023 09:48:59 p. m.
; Author : AlbertoMarquez794
;

.include "./m328Pdef.inc"

.equ LDIG = 0x321
.equ HDIG = 0x322
.def den = r23
.def quo = r24
.def num = r25

init:
    call serial_init

start:
   	ldi r31, 0x00
	ldi r20, 0x00
    ldi r19, 0x3e ;load '>' onto r19
    call serial_transmit ;print '>'

loop:
     cpi r31, 0x04
	 breq mult ;Cuando llegas a cuatro es que ya tienes los caracteres
	 inc r31
	 rjmp lecNum

lecNum:
	call serial_receive
	push r19
	cpi r19, 0x0a ;Si ya presiono enter
	rjmp decodificar
	rjmp lecNum


decodificar: ;Agarra lo que esté en el stack y lo covierte a un numero y lo guarda en un registro
	pop r19 ;Saca el new line
	call serial_transmit
	cpi r19, 0x2d ;Verificas si es un signo negativo, positivo no importa
	breq bandera_negativo
	cpi r31, 0x04
	breq decodificar2
	cpi r19, 0x2B
	breq loop
	pop r19 ;Tomamos el numero de la pila
	andi r19, 0x0f ; Convertir de caracter a hexadecimal
	mov r2, r19	;guardar en r2
	ldi r19, 0x2A
	call serial_transmit
	rjmp loop

decodificar2: ;Agarra lo que esté en el stack y lo covierte a un numero y lo guarda en un registro
	pop r19 ;Tomamos el numero
	;subi r19, 0x30 
	andi r19, 0x0f ; Convertir de caracter a hexadecimal
	mov r3, r19	;guardar en r3
	rjmp loop	

bandera_negativo:
	inc r20
	rjmp loop

mult:
	mul r2, r3 ; Resultado en r0 maximo 81
	ldi r19, 0x3D ;Cargamos el '=' para poder imprimir
	call serial_transmit
	cpi r20, 0x01 ;Significa que tenemos nos dieron en la entrada un número negativo
	breq imprime_menos
	mov r19, r2
	call serial_transmit
	rjmp stop
	;breq  imprime_menos
	;rjmp imprime_numero

stop:
	call stop

imprime_menos:
	ldi r19, 0x2D
	call serial_transmit
	rjmp imprime_numero

imprime_numero:
	mov r19, quo ; imprime el registro de las decenas
	call serial_transmit ; imprime el registro de las unidades
	mov r19, den ;ori registro, 0x30
	call serial_transmit
	; Antes de imprimir, convertir de numero decimal a caracter
	rjmp reset

reset: 
	ldi r19, 0x0a
	call serial_transmit
	;registros de unidades y decenas, mandarlos a 0
	rjmp start


;hex to dec
bin_ascii_converter : 
         ldi den, 10
		 mov num, r30
         rcall divide
	     ori num, 0x30
		 sts HDIG, num
		 mov num, quo
		 rcall divide
		 ori num, 0x30
		 sts LDIG, num
		 ret
;divide
divide: 
        ldi quo, 0
    d1: inc quo
	    sub num, den
		brcc d1
		dec quo
		add num, den
		ret

print: 
       ldi r16, 0x00
	   ldi r17, 0x00
	   ldi r18, 0x00
       ldi r30, 2
       lds r16, HDIG
	   push r16
	   lds r17, LDIG
	   push r17
	   ldi r18, 0x3d
       push r18
    p1: 
	    pop r19
	    rcall serial_transmit
		subi r30, 1
		brcc p1
		ret

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
serial_receive:
         lds r16, 0xc0 ;get value in USART Control and Status Register A
         sbrs r16, 7 ;if receive is complete skip next instruction
         rjmp serial_receive
         lds r19, 0xc6 ;load value in USART I/O data register into r19
         ret