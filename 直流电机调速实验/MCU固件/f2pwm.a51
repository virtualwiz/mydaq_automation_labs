;; SYSCLK 24 MHz

;; Extra GPIO data and mode SFRs
	p5 data 0c8h
	p1m1 data 091h
	p1m0 data 092h
	p3m1 data 0b1h
	p3m0 data 0b2h
	p5m1 data 0c9h
	p5m0 data 0cah

;; Comparator SFRs
	cmpcr1 data 0e6h
	cmpen equ 080h
	cmpif equ 040h
	pie equ 020h
	nie equ 010h
	pis equ 008h
	nis equ 004h
	cmpoe equ 002h
	cmpres equ 001h

	cmpcr2 data 0e7h
	invcmpo equ 080h
	disfit equ 040h
	lcdty equ 03fh

;; Timer SFRs and constants
	auxr data 08eh
	intclko data 08fh
	ie2 data 0afh
	t2h data 0d6h
	t2l data 0d7h
	pwmcnt equ 10000h	; Duty range: 65535 downto 0
	rotcnt equ 1c23h	; Encoder count interrupt interval 50Hz

;; Variables
	pwmflag bit 20h.0
	pwmdutyh_h equ 031h
	pwmdutyh_l equ 030h
	pwmdutyl_h equ 033h
	pwmdutyl_l equ 032h

;; Onboard peripherals
	dac bit p1.4
	led bit p1.0

org 0000h			; Reset
	ljmp reset
	
org 00abh			; Comparator interrupt
	ljmp cmp_isr

org 000bh			; Timer 0 interrupt
	ljmp t0_isr

org 0063h
	ljmp t2_isr
	
org 0100h			; Principal
reset:
	;; Stack initialise
	mov sp, #60h
	
	;; GPIO initialise
	mov p1m0, #00010101b	; DAC, LED, CMP PP mode
	mov p1m1, #00000000b
	mov p3m0, #00000000b
	mov p3m1, #00000000b
	mov p5m0, #00000000b
	mov p5m1, #00000000b

	;; Comparator initialise
	mov cmpcr1, #11110110b	; cmpen, cmpif, pie, nie, pis, nis, cmpoe, cmpres(ro)
	mov cmpcr2, #00001000b	; invcmpo, disfit, lcdty(5 downto 0)

	;; Timer (PWM) initialise
	orl auxr, #10000000b	; Timer 0 1T mode
	mov intclko, #00000001b	; Timer 0 clock output enable
	anl tmod, #11110000b	; Timer 0 mode 0
	mov tl0, #00001000b
	mov th0, #00001000b
	setb dac
	clr pwmflag
	setb tr0		; Timer 0 start
	setb et0		; Timer 0 interrupt enable
	
	;; Timer (RPM counter) initialise
	anl auxr, #11111011b	; Timer 2 12T mode;
	mov t2l, #low rotcnt
	mov t2h, #high rotcnt
	orl auxr, #00010000b	; Timer 2 start
	orl ie2, #00000100b	; Timer 2 interrupt enable
	
	;; Interrupt initialise
	setb ea

	;; Select working registers in PSW
	clr rs0
	clr rs1
	
loop:
	cjne r1, #5d, loop
	mov r1, #0d		; Reset interval counter
count:
	cpl led
	inc r0
	mov pwmdutyh_h, r0
	mov pwmdutyh_l, #0d

	mov a, #0ffh		; inv16 algorithm: subtract 0ffh by pwmdutyh
	clr c
	subb a, #0d
	mov pwmdutyl_l, a
	mov a, #0ffh
	subb a, r0
	mov pwmdutyl_h, a 
	mov r0, #0d		; Reset pulse counter
	
restart:
	sjmp loop
	
cmp_isr:
	anl cmpcr1, #not cmpif
	inc r0
	reti

t0_isr:
	cpl pwmflag
	jnb pwmflag, rdylow
rdyhigh:
	mov tl0, pwmdutyl_l
	mov th0, pwmdutyl_h
	jmp t0_isrret
rdylow:
	mov tl0, pwmdutyh_l
	mov th0, pwmdutyh_h
t0_isrret:
	reti

t2_isr:
	inc r1
	anl ie2, #11111011b	; Re-enable interrupt
	orl ie2, #00000100b
	reti
	
end
	
