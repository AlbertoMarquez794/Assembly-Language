.include "m328pdef.inc" ; Incluye el archivo de definici�n del microcontrolador ATmega328P.

.org 0x00 ; Establece la direcci�n de inicio del programa en 0x00.
     jmp main ; Salta a la etiqueta "main".

.org OVF1addr ; Establece una direcci�n espec�fica para la rutina de interrupci�n de desbordamiento del Timer1, llamada "TIM1_OVF".
     jmp TIM1_OVF ; Salta a la rutina de interrupci�n cuando ocurre un desbordamiento del Timer1.

.org 0x40 ; Inicia el programa principal a partir de la direcci�n 0x40.

main: ; Etiqueta "main" donde comienza el programa principal.
      call serial_init ; Llama a la funci�n "serial_init", que probablemente configure la comunicaci�n serial.
      ldi r16, high(ramend) ; Carga el byte alto de la direcci�n final de la memoria RAM en r16.
      out sph, r16 ; Escribe el valor de r16 en el registro sph, configurando el l�mite superior de la memoria RAM.
      ldi r16, low(ramend) ; Carga el byte bajo de la direcci�n final de la memoria RAM en r16.
      out spl, r16 ; Escribe el valor de r16 en el registro spl, configurando el l�mite inferior de la memoria RAM.

      sbi ddrb, 5 ; Configura el bit 5 del registro ddrb como salida.
      sbi portb, 5 ; Establece en alto (enciende) el bit 5 del puerto B.

	  ldi r20, 0x00 ; Carga el valor 0x00 en r20.
	  ldi r21, 0x05 ; Carga el valor 0x05 en r21.
	  sts TCCR1A, r20 ; Escribe el valor de r20 (00000000) en el registro TCCR1A.
	  sts TCCR1B, r21 ; Escribe el valor de r21 (00000101) en el registro TCCR1B.

	  ldi r20, 0x00 ; Carga el valor 0x00 en r20 (esto parece ser un error, deber�a ser r21 en lugar de r20).
	  ldi r20, (1<<TOIE1) ; Carga en r20 el resultado de la operaci�n (1<<TOIE1), que configura la interrupci�n de desbordamiento del Timer1.
	  sts TIMSK1, r20 ; Escribe el valor de r20 en el registro TIMSK1 para habilitar la interrupci�n de desbordamiento del Timer1.

	  sei ; Habilita las interrupciones globales.

	  ldi r20, 0xFF ; Carga el valor 0xFF en r20.
      ldi r21, 0x3C ; Carga el valor 0x3C en r21.
      sts TCNT1H, r20 ; Escribe el valor de r20 en el registro TCNT1H del Timer1.
      sts TCNT1L, r21 ; Escribe el valor de r21 en el registro TCNT1L del Timer1.
	  ;�Preguntar?
      ldi r16, 32 ; Carga el valor 32 en r16.
      out portb, r16 ; Escribe el valor de r16 en el puerto B, encendiendo el LED conectado al pin 5.

here: ; Etiqueta "here" que marca el inicio de un bucle infinito.
      jmp here ; Salta de nuevo a la etiqueta "here", creando un bucle infinito.

.org 0x0200 ; Establece la direcci�n para la rutina de interrupci�n "TIM1_OVF".

TIM1_OVF : ; Etiqueta para la rutina de interrupci�n "TIM1_OVF".
      in r16, portb ; Lee el estado del puerto B y lo coloca en r16.
      ldi r17, 32 ; Carga el valor 32 en r17.
      eor r16, r17 ; Realiza una operaci�n XOR entre r16 y r17.
      out portb, r16 ; Escribe el resultado de la operaci�n en el puerto B.
      reti ; Retorna de la rutina de interrupci�n.
