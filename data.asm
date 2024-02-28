#include "hd6303x.asm"
#include "dtmf.asm"

#bank RAM

#addr 0x62
ram_d62: #res 2
ram_d64: #res 2

kbd_data0: #res 1 ;
kbd_data1: #res 1 ;
kbd_data2: #res 1 ;

#addr 0x65
standby_something:#res 1 ;

#addr 0x8c
lcd_data:#res 8

#addr 0x99
per2portb: #res 1

#addr 0x9c
lcd_timeout: #res 1

#addr 0x44
mul16_a: #res 2
#addr 0x4b
mul16_res: #res 4
mul16_b: #res 2


#bank EEPROM
reset:
	sei
	ldx 0x0100           ;setup stack
	txs
	lda A, 0xf0
	sta A, [RAM_CTRL]    ;enable ram (and standby bit)
	jsr hw_init
	gpio_test PROG_CONT ; I think this checks for cloning cable
	bne .skip
	jsr F_a308
.skip:
	jsr F_8243
	jsr F_84a4
.L_801a:
	jsr delay_7000
	tim bit0, [0x69]
	beq .L_8025
	jmp .L_80c0
.L_8025:
	tim bit7, [0x6d]
	beq .L_802f
	jsr F_85fe
	bra .L_8032
.L_802f:
	oim bit6, [0x6d]
.L_8032:
	tim bit5, [0x6d]
	beq .L_8047
	cim bit5, [0x6d]
	tst [0x0040]
	bne .L_8042
	jsr F_9906
.L_8042:
	jsr F_84c8
	bra .L_801a
.L_8047:
	tim bit2, [0x6c]
	beq .L_8054
	cim bit2, [0x6c]
	jsr F_8f66
	bra .L_801a
.L_8054:
	tim bit1, [0x6c]
	beq .L_8061
	cim bit1, [0x6c]
	jsr F_9191
	bra .L_801a
.L_8061:
	jsr F_9535
	tim bit0, [0x64]
	beq .L_807a
	tim bit6, [0x69]
	beq .L_807a
	cim bit7, [0x6b]
	cim bit6, [0x69]
	jsr F_9988
	jmp .L_801a
.L_807a:
	tim bit7, [standby_something]
	beq .L_8090
	tim bit5, [0x69]
	beq .L_8090
	cim bit7, [0x6b]
	cim bit5, [0x69]
	jsr F_9b8a
	jmp .L_801a
.L_8090:
	tim bit2, [0x69]
	beq .L_80a1
	cim bit7, [0x6b]
	cim bit2, [0x69]
	jsr F_9c13
	jmp .L_801a
.L_80a1:
	tim bit6, [0x6b]
	beq .L_80af
	cim bit6, [0x6b]
	jsr F_9c00
	jmp .L_801a
.L_80af:
	tim bit0, [0x6c]
	beq .L_80bd
	cim bit7, [0x6b]
	cim bit0, [0x6c]
	jsr F_9c21
.L_80bd:
	jmp .L_801a
.L_80c0:
	tim bit7, [0x6d]
	beq .L_80ca
	jsr F_85fe
	bra .L_80cd
.L_80ca:
	oim bit6, [0x6d]
.L_80cd:
	tim bit5, [0x6d]
	beq .L_80e3
	cim bit5, [0x6d]
	tst [0x0040]
	bne .L_80dd
	jsr F_9906
.L_80dd:
	jsr F_84c8
	jmp .L_801a
.L_80e3:
	tim bit1, [0x69]
	beq .L_80f1
	cim bit7, [0x6b]
	cim bit2, [0x69]
	jsr F_9c1a
.L_80f1:
	jmp .L_801a


check_lcd_timeout:
	dec [lcd_timeout]
	bne .L_8138
	tim bit2, [0x6d]
	beq .lcdoff

    lcd_on
    
	tim bit1, [0x6d]
	beq .L_8115
	oim bit4, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
.L_8115:
	cim bit2, [0x6d]
	bra .L_8134

.lcdoff:
    lcd_off
    
	tim bit1, [0x6d]
	beq .L_8131
	cim bit4, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
.L_8131:
	oim bit2, [0x6d]
.L_8134:
	lda A, 0x7
	sta A, [0x9c]
.L_8138:
	rts


hw_init:   ;clears ram
	lda A, 0x90
	ldx 0x0040
	clr B
.clear_loop:
	sta B, [X]
	dec A
	beq .clear_end
	inx
	bra .clear_loop
.clear_end:

	lda A, 0x4        ;set clock control to 010 (async internal, p2_2 output)
	sta A, [SCI_RMCR]   ;

	lda A, 0x2        ;p2_1-p2_7 as output, p2_0 input
	sta A, [P2_DIR]

	lda A, 0x44
	sta A, [P2]         ;MIC_OFF, ALARM p2_2 and p2_6 high

	lda A, 0x20       ;CTCSS_H on, other off
	sta A, [P6]

	lda A, 0x37       ;p6_0-p6_5 output, p6_6/7 input
	sta A, [P6_DIR]
;                      ;external io ports
	lda A, 0x80
	sta A, [PERIPH3.CTRL]

	lda A, 0x89
	sta A, [PERIPH2.CTRL] ;portc low = input, port b = output mode0, portc hi = input, porta = output mode 0
	lda A, 0x1
	sta A, [PERIPH3.PORTA]
	sta A, [0x95]
	lda A, 0x0
	sta A, [PERIPH3.PORTB]
	sta A, [0x96]
	lda A, 0x0
	sta A, [PERIPH3.PORTC]
	sta A, [0x97]
	lda A, 0xf9
	sta A, [PERIPH2.PORTA]
	sta A, [0x98]
	lda A, 0x0
	sta A, [PERIPH2.PORTB]
	sta A, [per2portb]
                    ;init lcd

    lcd_off

	gpio_on BUSY_IND ; BUSY_IND=1
	cim bit4, [0x98]
	oim bit2, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	jsr lcd_wait
	lda A, 0x0
	lda B, 0xff
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x1
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x2
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x3
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x4
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x5
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x6
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x7
	jsr send_lcd_data
	jsr F_98a6
	jsr F_98a6
	jsr F_98a6
	gpio_off BUSY_IND ;BUSY_IND=0
	oim bit4, [0x98]
	cim bit2, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	jsr init_lcd
	jsr lcd_seg_5_5_off
	oim bit0, [0x6e]
	lda A, 0xa
	sta A, [0x73]
	lda A, 0x18
	sta A, [0x78]
	lda A, 0x2e
	sta A, [0x7c]
	sta A, [0x7b]
	sta A, [0x9a]
	lda A, 0x3
	sta A, [0x8b]
	cim bit0, [TCSR2]
	cim bit1, [TCSR2]
	cim bit3, [TCSR2]
	ldd 0xff00
	std [FRCH]
	ldd [FRCH]
	addd 0x2710
	std [OCR1H]
	lda A, [TCSR1]
	ldd [OCR1H]
	std [OCR1H]
	lda A, [TCSR1]
	lda A, [FRCH]
	oim bit2, [TCSR1]
	oim bit3, [TCSR1]
	cli
	oim bit2, [0x71]
	jsr F_9910
	rts


F_8243:
	lda A, 0x3e
	sta A, [0x87]
	jsr F_8296
	sta A, [0x64]
	sta B, [standby_something]
	lda A, 0x31
	sta A, [0x87]
	jsr F_8296
	std [0x5c]
	lda A, 0x32
	sta A, [0x87]
	jsr F_8296
	std [0x5e]
	lda A, 0x0
	sta A, [0x87]
	jsr F_8296
	std [0x49]
	lda A, 0x33
	sta A, [0x87]
	jsr F_8296
	std [0x62]
	lda A, 0x34
	sta A, [0x87]
	jsr F_8296
	std [0x60]
	lda A, 0x3d
	sta A, [0x87]
	jsr F_8296
	and A, 0xf
	and B, 0xf
	sta A, [0x59]
	sta B, [0x5a]
	lda A, 0x3f
	sta A, [0x87]
	jsr F_8296
	and A, 0xf
	sta A, [0x5b]
	rts


F_8296:
.L_8296:
	sei
	oim bit7, [0x87]
	cim bit6, [0x87]
	gpio_off DI
	gpio_off CLX
	gpio_off CSA
	clr A
	clr B
	clr [0x0086]
	oim 0x9, [0x86]
	gpio_on CSA
	gpio_on CLX
	brn .L_8296
	brn .L_8296
	brn .L_8296
	brn .L_8296
	brn .L_8296
	gpio_off CLX
	sec
.L_82c2:
	gpio_off CLX
	bcc .L_82cc
	gpio_on DI
	bra .L_82d1
.L_82cc:
	gpio_off DI
	brn .L_8296
.L_82d1:
	gpio_on CLX
	dec [0x0086]
	beq .L_82de
	rol [0x0087]
	bra .L_82c2
.L_82de:
	gpio_off DI
	gpio_off CLX
	rol [0x0087]
	brn .L_8296
	brn .L_8296
	brn .L_8296
	brn .L_8296
	gpio_on CLX
	clr [0x0086]
	oim bit3, [0x86]
	brn .L_8296
	brn .L_8296
.L_82fc:
	gpio_off CLX
	nop
	nop
	gpio_test DO
	beq .L_8309
	sec
	bra .L_830c
.L_8309:
	clc
	brn .L_8296
.L_830c:
	rol A
	gpio_on CLX
	brn .L_8296
	brn .L_8296
	brn .L_8296
	dec [0x0086]
	bne .L_82fc
	clr [0x0086]
	oim bit3, [0x86]
.L_8321:
	gpio_off CLX
	nop
	nop
	gpio_test DO
	beq .L_832e
	sec
	bra .L_8331
.L_832e:
	clc
	brn .L_8331
.L_8331:
	rol B
	gpio_on CLX
	brn .L_8321
	brn .L_8321
	brn .L_8321
	dec [0x0086]
	bne .L_8321
	gpio_off CLX
	gpio_off CSA
	cli
	rts


F_8348:
.L_8348:
	sei
	psh A
	psh B
	lda A, 0x30
	gpio_off DI
	gpio_off CLX
	gpio_off CSA
	clr [0x0086]
	oim 0x9, [0x86]
	gpio_on CSA
	gpio_on CLX
	brn .L_8348
	brn .L_8348
	brn .L_8348
	brn .L_8348
	brn .L_8348
	gpio_off CLX
	sec
.L_8370:
	gpio_off CLX
	bcc .L_837a
	gpio_on DI
	bra .L_837f
.L_837a:
	gpio_off DI
	brn .L_8348
.L_837f:
	gpio_on CLX
	dec [0x0086]
	beq .L_838a
	rol A
	bra .L_8370
.L_838a:
	gpio_off CSA
	gpio_off CLX
	gpio_off DI
	oim bit7, [0x87]
	oim bit6, [0x87]
	clr [0x0086]
	oim 0x9, [0x86]
	gpio_on CSA
	gpio_on CLX
	brn .L_8348
	brn .L_8348
	brn .L_8348
	brn .L_8348
	brn .L_8348
	gpio_off CLX
	sec
.L_83b3:
	gpio_off CLX
	bcc .L_83bd
	gpio_on DI
	bra .L_83c2
.L_83bd:
	gpio_off DI
	brn .L_8348
.L_83c2:
	gpio_on CLX
	dec [0x0086]
	beq .L_83cf
	rol [0x0087]
	bra .L_83b3
.L_83cf:
	gpio_off DI
	gpio_off CLX
	gpio_off CSA
	rol [0x0087]
	cli
	jsr delay_10k
	gpio_on CSA
.L_83e2:
	gpio_test DO
	beq .L_83e2
	gpio_off CSA
	sei
	cim bit7, [0x87]
	oim bit6, [0x87]
	pul B
	pul A
	clr [0x0086]
	oim 0x9, [0x86]
	gpio_on CSA
	gpio_on CLX
	brn .L_840d
	brn .L_840d
	brn .L_840d
	brn .L_840d
	brn .L_840d
	gpio_off CLX
	sec
.L_840d:
	gpio_off CLX
	bcc .L_8417
	gpio_on DI
	bra .L_841c
.L_8417:
	gpio_off DI
	brn .L_841c
.L_841c:
	gpio_on CLX
	dec [0x0086]
	beq .L_8429
	rol [0x0087]
	bra .L_840d
.L_8429:
	rol [0x0087]
	clr [0x0086]
	oim bit4, [0x86]
.L_8432:
	gpio_off CLX
	asld
	bcc .L_843d
	gpio_on DI
	bra .L_8442
.L_843d:
	gpio_off DI
	brn .L_8442
.L_8442:
	gpio_on CLX
	dec [0x0086]
	bne .L_8432
	gpio_off DI
	gpio_off CLX
	gpio_off CSA
	cli
	jsr delay_10k
	gpio_on CSA
.L_845a:
	gpio_test DO
	beq .L_845a
	gpio_off CSA
	sei
	lda A, 0x0
	clr [0x0086]
	oim 0x9, [0x86]
	gpio_on CSA
	gpio_on CLX
	brn .L_847f
	brn .L_847f
	brn .L_847f
	brn .L_847f
	brn .L_847f
	gpio_off CLX
	sec
.L_847f:
	gpio_off CLX
	bcc .L_8489
	gpio_on DI
	bra .L_848e
.L_8489:
	gpio_off DI
	brn .L_848e
.L_848e:
	gpio_on CLX
	dec [0x0086]
	beq .L_8499
	rol A
	bra .L_847f
.L_8499:
	gpio_off DI
	gpio_off CLX
	gpio_off CSA
	cli
	rts


F_84a4:
	ldd [0x60]
	beq .L_84b6
	clr [0x0041]
.L_84ab:
	asld
	bcs .L_84ba
	inc [0x0041]
	tim bit4, [0x41]
	beq .L_84ab
.L_84b6:
	lda A, 0x10
	sta A, [0x41]
.L_84ba:
	lda A, 0xf
	sta A, [0x42]
	jsr lcd_c0_C
	jsr F_84c8
	oim bit6, [0x6d]
	rts


F_84c8:
	jsr F_a28e
	gpio_off BUSY_IND ;BUSY_IND=0
	tim bit3, [0x6c]
	bne .L_84da
	tim bit0, [0x6d]
	bne .L_84da
	bra .L_84fe
.L_84da:
	tim bit0, [0x6f]
	bne .L_84e6
	tim bit2, [0x70]
	bne .L_84ee
	bra .L_84f6
.L_84e6:
	jsr delay_3000
	jsr F_857f
	bra .L_853c
.L_84ee:
	jsr delay_3000
	jsr F_859b
	bra .L_853c
.L_84f6:
	jsr delay_3000
	jsr F_8563
	bra .L_853c
.L_84fe:
	jsr F_9a57
	jsr F_bb57
	lda A, [0x40]
	jsr F_a953
	bcs .L_850d
	bra .L_854b
.L_850d:
	jsr lcd_seg_5_7_on
	lda A, 0x33
	sta A, [0x87]
	jsr F_8296
	std [0x62]
	lda A, [0x40]
	jsr F_a961
	bcc .L_8525
	jsr lcd_seg_4_7_on
	bra .L_8528
.L_8525:
	jsr lcd_seg_4_7_off
.L_8528:
	lda A, [0x41]
	cmp A, [0x40]
	bne .L_8533
	jsr lcd_seg_1_7_on
	bra .L_8536
.L_8533:
	jsr lcd_seg_1_7_off
.L_8536:
	jsr delay_3000
	jsr F_8563
.L_853c:
	jsr F_a26b
	lda A, 0xf
	sta A, [0x9d]
	lda A, 0xfa
	sta A, [0x89]
	oim bit3, [0x6d]
	rts
.L_854b:
	jsr lcd_seg_5_7_off
	jsr lcd_seg_4_7_off
	jsr lcd_seg_1_7_off
	jsr lcd_c3_off
	cim bit2, [0x71]
	cim bit3, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	rts


F_8563:
	jsr F_a28e
	gpio_off BUSY_IND ;BUSY_IND=0
	gpio_on CTCSS_H ;CTCSS_H=1
	gpio_off CTCSS_L ;CTCSS_L=0
	lda A, [0x40]
	jsr F_8817
	lda A, [0x40]
	jsr F_85b7
	lda A, [0x40]
	jsr F_85e7
	rts


F_857f:
	jsr F_a28e
	gpio_off BUSY_IND ;BUSY_IND=0
	gpio_on CTCSS_H ;CTCSS_H=1
	gpio_off CTCSS_L ;CTCSS_L=0
	lda A, [0x41]
	jsr F_8817
	lda A, [0x41]
	jsr F_85b7
	lda A, [0x41]
	jsr F_85e7
	rts


F_859b:
	jsr F_a28e
	gpio_off BUSY_IND ;BUSY_IND=0
	gpio_on CTCSS_H ;CTCSS_H=1
	gpio_off CTCSS_L ;CTCSS_L=0
	lda A, [0x42]
	jsr F_8817
	lda A, [0x42]
	jsr F_85b7
	lda A, [0x42]
	jsr F_85e7
	rts


F_85b7:
	tim bit3, [0x64]
	beq .L_85ce
	add A, 0x21
	sta A, [0x87]
	jsr F_8296
	sta A, [0x57]
	beq .L_85ce
	oim bit1, [0x6e]
	jsr F_983d
	rts
.L_85ce:
	cim bit1, [0x6e]
	rts


delay_3000:
	ldx 3000/4 ;3 cycles
.loop:
	dex ;1 cycle
	bne .loop ;3 cycles 
	rts


delay_7000:
	ldx 7000/4
.loop:
	dex
	bne .loop
	rts


delay_10k:
	ldx 10*1000/4
.loop:
	dex
	bne .loop
	rts


F_85e7:
	jsr F_a97d
	bcc .L_85f5
	cim bit5, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	rts
.L_85f5:
	oim bit5, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	rts


F_85fe:
	tim bit6, [0x6d]
	bne .L_8604
	rts
.L_8604:
	gpio_off BUSY_IND ;BUSY_IND=0
	jsr F_9a57
	jsr F_a28e
.L_860d:
	tim bit0, [0x6f]
	bne .L_861b
	tim bit2, [0x70]
	bne .L_861f
	lda A, [0x40]
	bra .L_8621
.L_861b:
	lda A, [0x41]
	bra .L_8621
.L_861f:
	lda A, [0x42]
.L_8621:
	jsr F_a945
	bcs .L_8629
	jmp .L_86f1
.L_8629:
	oim bit1, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	oim bit1, [0x6d]
	clr [TCSR3]
	jsr F_87cb
	tim bit0, [0x71]
	beq .L_8647
	oim bit2, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
.L_8647:
	ldx 0x0384
.L_864a:
	tim bit7, [0x6d]
	bne .L_8652
	jmp .L_86f1

.L_8652:
	dex
	bne .L_864a
    
	oim bit7, [per2portb]
	lda A, [per2portb]
	sta A, [PERIPH2.PORTB]
	ldx 0x1388
.L_8660:
	tim bit7, [0x6d]
	bne .L_8668
	jmp .L_86f1
.L_8668:
	dex
	bne .L_8660
	cim bit0, [0x95]
	lda A, [0x95]
	sta A, [PERIPH3.PORTA]

	ldx 0x02ee
.L_8676:
	dex
	bne .L_8676

	oim bit5, [0x96]
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	ldx 0x2328
.L_8684:
	tim bit7, [0x6d]
	bne .L_868c
	jmp .L_86f1
.L_868c:
	dex
	bne .L_8684
	lda A, [PERIPH2.PORTC]
	and A, 0x10
	beq .L_86c0
	jmp .L_8732
.L_8699:
	cim bit5, [0x6d]
	oim bit0, [0x95]
	lda A, [0x95]
	sta A, [PERIPH3.PORTA]
	jsr delay_10k
	cim bit7, [per2portb]
	lda A, [per2portb]
	sta A, [PERIPH2.PORTB]
	oim bit4, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	cim bit1, [0x6f]
	clr [TCSR3]
	jmp .L_860d
.L_86c0:
	lda A, [0x5b]
	and A, 0xf
	beq .L_86cb
	jsr F_87bd
	bra .L_86ce
.L_86cb:
	cim bit4, [0x6c]
.L_86ce:
	jsr delay_7000
	lda A, [PERIPH2.PORTC]
	and A, 0x10
	bne .L_8732
	tim bit3, [0x6c]
	bne .L_86e7
	tim bit0, [0x6d]
	bne .L_86e7
	tim bit5, [0x6d]
	bne .L_8699
.L_86e7:
	tim bit7, [0x6d]
	beq .L_86f1
	tim bit6, [0x6d]
	bne .L_86ce
.L_86f1:
	tim bit1, [0x6f]
	beq .L_86ff
	cim bit1, [0x6f]
	clr [TCSR3]
	jsr F_98a6
.L_86ff:
	oim bit0, [0x95]
	lda A, [0x95]
	sta A, [PERIPH3.PORTA]
	jsr delay_10k
	cim bit7, [per2portb]
	lda A, [per2portb]
	sta A, [PERIPH2.PORTB]
	jsr delay_10k
	cim bit1, [0x98]
	oim bit4, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	cim bit1, [0x6d]
	jsr lcd_seg_3_7_off
	cim bit2, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	jsr F_84c8
	rts
.L_8732:
	oim bit0, [0x95]
	lda A, [0x95]
	sta A, [PERIPH3.PORTA]
	cim bit7, [per2portb]
	lda A, [per2portb]
	sta A, [PERIPH2.PORTB]
	oim bit4, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	jsr lcd_seg_3_7_off
	jsr delay_10k
	jsr F_8d25
	jsr delay_10k
	oim bit7, [per2portb]
	lda A, [per2portb]
	sta A, [PERIPH2.PORTB]
	ldx 0x1388
.L_8761:
	tim bit7, [0x6d]
	bne .L_8769
	jmp .L_86f1
.L_8769:
	dex
	bne .L_8761
	oim bit5, [0x96]
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	ldx 0x2328
.L_8777:
	tim bit7, [0x6d]
	bne .L_877f
	jmp .L_86f1
.L_877f:
	dex
	bne .L_8777
	lda A, [PERIPH2.PORTC]
	and A, 0x10
	beq .L_878c
	jmp .L_8732
.L_878c:
	cim bit0, [0x95]
	lda A, [0x95]
	sta A, [PERIPH3.PORTA]
	cim bit4, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	jsr lcd_seg_3_7_on
	jmp .L_86c0


F_87a2:
	tim bit3, [0x64]
	beq .L_87b9
	add A, 0x21
	sta A, [0x87]
	jsr F_8296
	sta B, [0x58]
	beq .L_87b9
	oim bit1, [0x6f]
	jsr F_97ac
	rts
.L_87b9:
	cim bit1, [0x6f]
	rts


F_87bd:
	lda A, 0xe6
	sta A, [0x74]
	lda A, [0x5b]
	and A, 0xf
	sta A, [0x75]
	oim bit4, [0x6c]
	rts


F_87cb:
	jsr lcd_seg_0_7_off
	jsr lcd_seg_3_7_on
	cim bit4, [0x98]
	lda A, [0x98]
	sta A, [PERIPH2.PORTA]
	tim bit3, [0x6c]
	bne .L_87e5
	tim bit0, [0x6d]
	bne .L_87e5
	bra .L_8803
.L_87e5:
	tim bit0, [0x6f]
	bne .L_87f1
	tim bit2, [0x70]
	bne .L_87fa
	bra .L_880c
.L_87f1:
	lda A, [0x41]
	jsr F_87a2
	lda A, [0x41]
	bra .L_8813
.L_87fa:
	lda A, [0x42]
	jsr F_87a2
	lda A, [0x42]
	bra .L_8813
.L_8803:
	jsr F_bb57
	jsr lcd_seg_4_7_off
	jsr lcd_seg_1_7_off
.L_880c:
	lda A, [0x40]
	jsr F_87a2
	lda A, [0x40]
.L_8813:
	jsr F_8a9f
	rts


F_8817:
	inc A
	sta A, [0x87]
	jsr F_8296
	std [mul16_a]
	oim bit2, [0x71]
	tim bit7, [mul16_a]
	beq .L_884d
	oim bit7, [0x43]
	cim bit7, [mul16_a]
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	beq .L_883d
	aim 0x3f, [0x96]
	aim 0xf, [0x97]
	jmp .L_8870
.L_883d:
	aim 0xf, [0x97]
	lda A, [PERIPH2.PORTC]
	and A, 0x80
	bne .L_884a
	jmp .L_888d
.L_884a:
	jmp .L_88a1
.L_884d:
	cim bit7, [0x43]
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	beq .L_8860
	aim 0x3f, [0x96]
	aim 0xf, [0x97]
	jmp .L_88c1
.L_8860:
	aim 0xf, [0x97]
	lda A, [PERIPH2.PORTC]
	and A, 0x80
	bne .L_886d
	jmp .L_88de
.L_886d:
	jmp .L_88f2
.L_8870:
	ldx 0x8dae
	clr [mul16_res]
.L_8876:
	ldd [X]
	xgdx
	cpx [mul16_a]
	xgdx
	bcc .L_8888
	inx
	inx
	inc [mul16_res]
	inc [mul16_res]
	bra .L_8876
.L_8888:
	lda B, [mul16_res]
	jmp .L_8912
.L_888d:
	clr A
	clr B
	ldx 0x063f
.L_8892:
	cpx [mul16_a]
	bcc .L_889e
	inc B
	xgdx
	addd 0x0190
	xgdx
	bra .L_8892
.L_889e:
	jmp .L_8925
.L_88a1:
	ldd [mul16_a]
	asld
	std [mul16_a]
	clr A
	clr B
	ldx 0x063f
.L_88ab:
	cpx [mul16_a]
	bcc .L_88b7
	inc B
	xgdx
	addd 0x0190
	xgdx
	bra .L_88ab
.L_88b7:
	ldx [mul16_a]
	xgdx
	lsrd
	xgdx
	stx [mul16_a]
	jmp .L_8925
.L_88c1:
	ldx 0x8de6
	clr [mul16_res]
.L_88c7:
	ldd [X]
	xgdx
	cpx [mul16_a]
	xgdx
	bcc .L_88d9
	inx
	inx
	inc [mul16_res]
	inc [mul16_res]
	bra .L_88c7
.L_88d9:
	lda B, [mul16_res]
	jmp .L_8912
.L_88de:
	clr A
	clr B
	ldx 0x07cf
.L_88e3:
	cpx [mul16_a]
	bcc .L_88ef
	inc B
	xgdx
	addd 0x01f4
	xgdx
	bra .L_88e3
.L_88ef:
	jmp .L_8925
.L_88f2:
	ldd [mul16_a]
	asld
	std [mul16_a]
	clr A
	clr B
	ldx 0x07cf
.L_88fc:
	cpx [mul16_a]
	bcc .L_8908
	inc B
	xgdx
	addd 0x01f4
	xgdx
	bra .L_88fc
.L_8908:
	ldx [mul16_a]
	xgdx
	lsrd
	xgdx
	stx [mul16_a]
	jmp .L_8925
.L_8912:
	ldx 0x8e76
	abx
	lda A, [X]
	ora A, [0x96]
	sta A, [0x96]
	lda A, [X + 0x1]
	ora A, [0x97]
	sta A, [0x97]
	jmp .L_8932
.L_8925:
	ldx 0x8eda
	abx
	lda A, [X]
	ora A, [0x97]
	sta A, [0x97]
	jmp .L_8932
.L_8932:
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	lda A, [0x97]
	sta A, [PERIPH3.PORTC]
	jsr F_8946
	jsr delay_3000
	jsr F_8d25
	rts


F_8946:
	sei
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	bne .L_8951
	jmp .L_89d9
.L_8951:
	lda A, [PERIPH2.PORTC]
	and A, 0x80
	beq .L_895b
	jmp .L_8999
.L_895b:
	tim bit7, [0x43]
	beq .L_8965
	ldd 0x0840
	bra .L_8968
.L_8965:
	ldd 0x0a50
.L_8968:
	asld
	asld
	std [0x81]
	tim bit7, [0x43]
	beq .L_8976
	ldd 0x4700
	bra .L_8979
.L_8976:
	ldd 0x58c0
.L_8979:
	addd [mul16_a]
	asld
	bcc .L_8983
	oim bit1, [0x82]
	bra .L_8986
.L_8983:
	cim bit1, [0x82]
.L_8986:
	asld
	bcc .L_898e
	oim bit0, [0x82]
	bra .L_8991
.L_898e:
	cim bit0, [0x82]
.L_8991:
	sta A, [0x83]
	lsr B
	sta B, [0x84]
	jmp .L_8a9a
.L_8999:
	tim bit7, [0x43]
	beq .L_89a3
	ldd 0x0840
	bra .L_89a6
.L_89a3:
	ldd 0x0a50
.L_89a6:
	asld
	asld
	std [0x81]
	tim bit7, [0x43]
	beq .L_89b4
	ldd 0x4700
	bra .L_89b7
.L_89b4:
	ldd 0x58c0
.L_89b7:
	addd [mul16_a]
	asld
	asld
	bcc .L_89c2
	oim bit1, [0x82]
	bra .L_89c5
.L_89c2:
	cim bit1, [0x82]
.L_89c5:
	asld
	bcc .L_89cd
	oim bit0, [0x82]
	bra .L_89d0
.L_89cd:
	cim bit0, [0x82]
.L_89d0:
	sta A, [0x83]
	lsr B
	lsr B
	sta B, [0x84]
	jmp .L_8a9a
.L_89d9:
	lda A, [PERIPH2.PORTC]
	and A, 0x80
	beq .L_89e3
	jmp .L_8a3a
.L_89e3:
	tim bit7, [0x43]
	beq .L_89ed
	ldd 0x0840
	bra .L_89f0
.L_89ed:
	ldd 0x0a50
.L_89f0:
	asld
	asld
	std [0x81]
	tim bit7, [0x43]
	beq .L_8a04
	ldd 0xa9f0
	std [mul16_res+1]
	lda A, 0x0
	sta A, [mul16_res]
	bra .L_8a0d
.L_8a04:
	ldd 0xd46c
	std [mul16_res+1]
	lda A, 0x0
	sta A, [mul16_res]
.L_8a0d:
	ldd [mul16_res+1]
	addd [mul16_a]
	std [mul16_res+1]
	lda A, [mul16_res]
	adc A, 0x0
	sta A, [mul16_res]
	tim bit0, [mul16_res]
	beq .L_8a23
	oim bit1, [0x82]
	bra .L_8a26
.L_8a23:
	cim bit1, [0x82]
.L_8a26:
	ldd [mul16_res+1]
	asld
	bcc .L_8a30
	oim bit0, [0x82]
	bra .L_8a33
.L_8a30:
	cim bit0, [0x82]
.L_8a33:
	sta A, [0x83]
	sta B, [0x84]
	jmp .L_8a9a
.L_8a3a:
	tim bit7, [0x43]
	beq .L_8a44
	ldd 0x0420
	bra .L_8a47
.L_8a44:
	ldd 0x0528
.L_8a47:
	asld
	asld
	std [0x81]
	tim bit7, [0x43]
	beq .L_8a5b
	ldd 0x54f8
	std [mul16_res+1]
	lda A, 0x0
	sta A, [mul16_res]
	bra .L_8a64
.L_8a5b:
	ldd 0x6a36
	std [mul16_res+1]
	lda A, 0x0
	sta A, [mul16_res]
.L_8a64:
	ldd [mul16_res+1]
	addd [mul16_a]
	std [mul16_res+1]
	lda A, [mul16_res]
	adc A, 0x0
	sta A, [mul16_res]
	ldd [mul16_res+1]
	asld
	std [mul16_res+1]
	rol [mul16_res]
	tim bit0, [mul16_res]
	beq .L_8a82
	oim bit1, [0x82]
	bra .L_8a85
.L_8a82:
	cim bit1, [0x82]
.L_8a85:
	ldd [mul16_res+1]
	asld
	bcc .L_8a8f
	oim bit0, [0x82]
	bra .L_8a92
.L_8a8f:
	cim bit0, [0x82]
.L_8a92:
	sta A, [0x83]
	lsr B
	sta B, [0x84]
	jmp .L_8a9a
.L_8a9a:
	oim bit0, [0x84]
	cli
	rts


F_8a9f:
	add A, 0x11
	sta A, [0x87]
	jsr F_8296
	std [0x47]
	tim bit7, [0x47]
	beq .L_8ad3
	oim bit7, [0x46]
	cim bit7, [0x47]
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	beq .L_8ac3
	aim 0x3f, [0x96]
	aim 0x9, [0x95]
	jmp .L_8af6
.L_8ac3:
	aim 0x9, [0x95]
	lda A, [PERIPH2.PORTC]
	and A, 0x80
	bne .L_8ad0
	jmp .L_8b13
.L_8ad0:
	jmp .L_8b27
.L_8ad3:
	cim bit7, [0x46]
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	beq .L_8ae6
	aim 0x3f, [0x96]
	aim 0x9, [0x95]
	jmp .L_8b47
.L_8ae6:
	aim 0x9, [0x95]
	lda A, [PERIPH2.PORTC]
	and A, 0x80
	bne .L_8af3
	jmp .L_8b64
.L_8af3:
	jmp .L_8b78
.L_8af6:
	ldx 0x8e1e
	clr [mul16_res]
.L_8afc:
	ldd [X]
	xgdx
	cpx [0x47]
	xgdx
	bcc .L_8b0e
	inx
	inx
	inc [mul16_res]
	inc [mul16_res]
	bra .L_8afc
.L_8b0e:
	lda B, [mul16_res]
	jmp .L_8b98
.L_8b13:
	clr A
	clr B
	ldx 0x063f
.L_8b18:
	cpx [0x47]
	bcc .L_8b24
	inc B
	xgdx
	addd 0x0190
	xgdx
	bra .L_8b18
.L_8b24:
	jmp .L_8bab
.L_8b27:
	ldd [0x47]
	asld
	std [0x47]
	clr A
	clr B
	ldx 0x063f
.L_8b31:
	cpx [0x47]
	bcc .L_8b3d
	inc B
	xgdx
	addd 0x0190
	xgdx
	bra .L_8b31
.L_8b3d:
	ldx [0x47]
	xgdx
	lsrd
	xgdx
	stx [0x47]
	jmp .L_8bab
.L_8b47:
	ldx 0x8e4a
	clr [mul16_res]
.L_8b4d:
	ldd [X]
	xgdx
	cpx [0x47]
	xgdx
	bcc .L_8b5f
	inx
	inx
	inc [mul16_res]
	inc [mul16_res]
	bra .L_8b4d
.L_8b5f:
	lda B, [mul16_res]
	jmp .L_8b98
.L_8b64:
	clr A
	clr B
	ldx 0x07cf
.L_8b69:
	cpx [0x47]
	bcc .L_8b75
	inc B
	xgdx
	addd 0x01f4
	xgdx
	bra .L_8b69
.L_8b75:
	jmp .L_8bab
.L_8b78:
	ldd [0x47]
	asld
	std [0x47]
	clr A
	clr B
	ldx 0x07cf
.L_8b82:
	cpx [0x47]
	bcc .L_8b8e
	inc B
	xgdx
	addd 0x01f4
	xgdx
	bra .L_8b82
.L_8b8e:
	ldx [0x47]
	xgdx
	lsrd
	xgdx
	stx [0x47]
	jmp .L_8bab
.L_8b98:
	ldx 0x8eae
	abx
	lda A, [X]
	ora A, [0x96]
	sta A, [0x96]
	lda A, [X + 0x1]
	ora A, [0x95]
	sta A, [0x95]
	jmp .L_8bb8
.L_8bab:
	ldx 0x8f20
	abx
	lda A, [X]
	ora A, [0x95]
	sta A, [0x95]
	jmp .L_8bb8
.L_8bb8:
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	lda A, [0x95]
	sta A, [PERIPH3.PORTA]
	jsr F_8bcc
	jsr delay_3000
	jsr F_8d25
	rts


F_8bcc:
	sei
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	bne .L_8bd7
	jmp .L_8c5f
.L_8bd7:
	lda A, [PERIPH2.PORTC]
	and A, 0x80
	beq .L_8be1
	jmp .L_8c1f
.L_8be1:
	tim bit7, [0x46]
	beq .L_8beb
	ldd 0x0840
	bra .L_8bee
.L_8beb:
	ldd 0x0a50
.L_8bee:
	asld
	asld
	std [0x81]
	tim bit7, [0x46]
	beq .L_8bfc
	ldd 0x5460
	bra .L_8bff
.L_8bfc:
	ldd 0x6978
.L_8bff:
	addd [0x47]
	asld
	bcc .L_8c09
	oim bit1, [0x82]
	bra .L_8c0c
.L_8c09:
	cim bit1, [0x82]
.L_8c0c:
	asld
	bcc .L_8c14
	oim bit0, [0x82]
	bra .L_8c17
.L_8c14:
	cim bit0, [0x82]
.L_8c17:
	sta A, [0x83]
	lsr B
	sta B, [0x84]
	jmp .L_8d20
.L_8c1f:
	tim bit7, [0x46]
	beq .L_8c29
	ldd 0x0840
	bra .L_8c2c
.L_8c29:
	ldd 0x0a50
.L_8c2c:
	asld
	asld
	std [0x81]
	tim bit7, [0x46]
	beq .L_8c3a
	ldd 0x5460
	bra .L_8c3d
.L_8c3a:
	ldd 0x6978
.L_8c3d:
	addd [0x47]
	asld
	asld
	bcc .L_8c48
	oim bit1, [0x82]
	bra .L_8c4b
.L_8c48:
	cim bit1, [0x82]
.L_8c4b:
	asld
	bcc .L_8c53
	oim bit0, [0x82]
	bra .L_8c56
.L_8c53:
	cim bit0, [0x82]
.L_8c56:
	sta A, [0x83]
	lsr B
	lsr B
	sta B, [0x84]
	jmp .L_8d20
.L_8c5f:
	lda A, [PERIPH2.PORTC]
	and A, 0x80
	beq .L_8c69
	jmp .L_8cc0
.L_8c69:
	tim bit7, [0x46]
	beq .L_8c73
	ldd 0x0840
	bra .L_8c76
.L_8c73:
	ldd 0x0a50
.L_8c76:
	asld
	asld
	std [0x81]
	tim bit7, [0x46]
	beq .L_8c8a
	ldd 0xce40
	std [mul16_res+1]
	lda A, 0x0
	sta A, [mul16_res]
	bra .L_8c93
.L_8c8a:
	ldd 0x01d0
	std [mul16_res+1]
	lda A, 0x1
	sta A, [mul16_res]
.L_8c93:
	ldd [mul16_res+1]
	addd [0x47]
	std [mul16_res+1]
	lda A, [mul16_res]
	adc A, 0x0
	sta A, [mul16_res]
	tim bit0, [mul16_res]
	beq .L_8ca9
	oim bit1, [0x82]
	bra .L_8cac
.L_8ca9:
	cim bit1, [0x82]
.L_8cac:
	ldd [mul16_res+1]
	asld
	bcc .L_8cb6
	oim bit0, [0x82]
	bra .L_8cb9
.L_8cb6:
	cim bit0, [0x82]
.L_8cb9:
	sta A, [0x83]
	sta B, [0x84]
	jmp .L_8d20
.L_8cc0:
	tim bit7, [0x46]
	beq .L_8cca
	ldd 0x0420
	bra .L_8ccd
.L_8cca:
	ldd 0x0528
.L_8ccd:
	asld
	asld
	std [0x81]
	tim bit7, [0x46]
	beq .L_8ce1
	ldd 0x6720
	std [mul16_res+1]
	lda A, 0x0
	sta A, [mul16_res]
	bra .L_8cea
.L_8ce1:
	ldd 0x80e8
	std [mul16_res+1]
	lda A, 0x0
	sta A, [mul16_res]
.L_8cea:
	ldd [mul16_res+1]
	addd [0x47]
	std [mul16_res+1]
	lda A, [mul16_res]
	adc A, 0x0
	sta A, [mul16_res]
	ldd [mul16_res+1]
	asld
	std [mul16_res+1]
	rol [mul16_res]
	tim bit0, [mul16_res]
	beq .L_8d08
	oim bit1, [0x82]
	bra .L_8d0b
.L_8d08:
	cim bit1, [0x82]
.L_8d0b:
	ldd [mul16_res+1]
	asld
	bcc .L_8d15
	oim bit0, [0x82]
	bra .L_8d18
.L_8d15:
	cim bit0, [0x82]
.L_8d18:
	sta A, [0x83]
	lsr B
	sta B, [0x84]
	jmp .L_8d20
.L_8d20:
	oim bit0, [0x84]
	cli
	rts


F_8d25:
.L_8d25:
	sei
	oim 0x38, [0x96]
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	lda A, 0x10
	sta A, [0x85]
	ldx [0x81]
.L_8d34:
	oim bit4, [0x96]
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	xgdx
	asld
	xgdx
	bcs .L_8d46
	oim bit3, [0x96]
	bra .L_8d4b
.L_8d46:
	cim bit3, [0x96]
	brn .L_8d25
.L_8d4b:
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	cim bit4, [0x96]
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	dec [0x0085]
	bne .L_8d34
	lda A, 0x10
	sta A, [0x85]
	ldx [0x83]
.L_8d63:
	oim bit4, [0x96]
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
.L_8d6b:
	xgdx
	asld
	xgdx
	bcs .L_8d75
	oim bit3, [0x96]
	bra .L_8d7a
.L_8d75:
	cim bit3, [0x96]
	brn .L_8d25
.L_8d7a:
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	cim bit4, [0x96]
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	dec [0x0085]
	lda A, [0x85]
	cmp A, 0x1
	bne .L_8d9d
	oim bit4, [0x96]
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	cim bit5, [0x96]
	bra .L_8d6b
.L_8d9d:
	cmp A, 0x0
	bne .L_8d63
	oim bit3, [0x96]
	oim bit4, [0x96]
	lda A, [0x96]
	sta A, [PERIPH3.PORTB]
	cli
	rts
D_8dae:
	#d8 0x00
	#d8 0xa0
	#d8 0x01
	#d8 0x40
	#d8 0x01
	#d8 0xe0
	#d8 0x02
	#d8 0x80
	#d8 0x03
	#d8 0x20
	#d8 0x03
	#d8 0xc0
	#d8 0x04
	#d8 0x60
	#d8 0x05
	#d8 0x00
	#d8 0x05
	#d8 0xa0
	#d8 0x06
	#d8 0x40
	#d8 0x06
	#d8 0xe0
	#d8 0x07
	#d8 0x80
	#d8 0x08
	#d8 0x1f
	#d8 0x0a
	#d8 0x00
	#d8 0x0b
	#d8 0x40
	#d8 0x0c
	#d8 0x80
	#d8 0x0d
	#d8 0x20
	#d8 0x0d
	#d8 0xc0
	#d8 0x0f
	#d8 0x00
	#d8 0x10
	#d8 0x40
	#d8 0x11
	#d8 0x80
	#d8 0x12
	#d8 0xc0
	#d8 0x13
	#d8 0x60
	#d8 0x14
	#d8 0xa0
	#d8 0x15
	#d8 0xe0
	#d8 0x17
	#d8 0x20
	#d8 0x18
	#d8 0x60
	#d8 0xff
	#d8 0xff
	#d8 0x00
	#d8 0xc8
	#d8 0x01
	#d8 0x90
	#d8 0x02
	#d8 0x58
	#d8 0x03
	#d8 0x20
	#d8 0x03
	#d8 0xe8
	#d8 0x04
	#d8 0xb0
	#d8 0x05
	#d8 0x78
	#d8 0x06
	#d8 0x40
	#d8 0x07
	#d8 0x08
	#d8 0x07
	#d8 0xd0
	#d8 0x08
	#d8 0x98
	#d8 0x09
	#d8 0x60
	#d8 0x0a
	#d8 0x27
	#d8 0x0c
	#d8 0x80
	#d8 0x0e
	#d8 0x10
	#d8 0x0f
	#d8 0xa0
	#d8 0x10
	#d8 0x68
	#d8 0x11
	#d8 0x30
	#d8 0x12
	#d8 0xc0
	#d8 0x14
	#d8 0x50
	#d8 0x15
	#d8 0xe0
	#d8 0x17
	#d8 0x70
	#d8 0x18
	#d8 0x38
	#d8 0x19
	#d8 0xc8
	#d8 0x1b
	#d8 0x58
	#d8 0x1c
	#d8 0xe8
	#d8 0x1e
	#d8 0x78
	#d8 0xff
	#d8 0xff
	#d8 0x01
	#d8 0x40
	#d8 0x02
	#d8 0x80
	#d8 0x03
	#d8 0xc0
	#d8 0x05
	#d8 0x00
	#d8 0x06
	#d8 0x40
	#d8 0x07
	#d8 0x80
	#d8 0x08
	#d8 0x1f
	#d8 0x09
	#d8 0x60
	#d8 0x0a
	#d8 0xa0
	#d8 0x0b
	#d8 0xe0
	#d8 0x0d
	#d8 0x20
	#d8 0x0e
	#d8 0x60
	#d8 0x0f
	#d8 0xa0
	#d8 0x10
	#d8 0xe0
	#d8 0x12
	#d8 0x20
	#d8 0x12
	#d8 0xc0
	#d8 0x13
	#d8 0x60
	#d8 0x14
	#d8 0xa0
	#d8 0x15
	#d8 0xe0
	#d8 0x17
	#d8 0x20
	#d8 0x18
	#d8 0x60
	#d8 0xff
	#d8 0xff
	#d8 0x01
	#d8 0x90
	#d8 0x03
	#d8 0x20
	#d8 0x04
	#d8 0xb0
	#d8 0x06
	#d8 0x40
	#d8 0x07
	#d8 0xd0
	#d8 0x09
	#d8 0x60
	#d8 0x0a
	#d8 0x27
	#d8 0x0b
	#d8 0xb8
	#d8 0x0d
	#d8 0x48
	#d8 0x0e
	#d8 0xd8
	#d8 0x10
	#d8 0x68
	#d8 0x11
	#d8 0xf8
	#d8 0x13
	#d8 0x88
	#d8 0x15
	#d8 0x18
	#d8 0x16
	#d8 0xa8
	#d8 0x17
	#d8 0x70
	#d8 0x18
	#d8 0x38
	#d8 0x19
	#d8 0xc8
	#d8 0x1b
	#d8 0x58
	#d8 0x1c
	#d8 0xe8
	#d8 0x1e
	#d8 0x78
	#d8 0xff
	#d8 0xff
	#d8 0x00
	#d8 0xf0
	#d8 0x00
	#d8 0xe0
	#d8 0x00
	#d8 0xd0
	#d8 0x00
	#d8 0xc0
	#d8 0x00
	#d8 0xb0
	#d8 0x00
	#d8 0xa0
	#d8 0x80
	#d8 0x90
	#d8 0x80
	#d8 0x80
	#d8 0x80
	#d8 0x70
	#d8 0x80
	#d8 0x60
	#d8 0x80
	#d8 0x50
	#d8 0x80
	#d8 0x40
	#d8 0x80
	#d8 0x30
	#d8 0x00
	#d8 0xf0
	#d8 0x00
	#d8 0xe0
	#d8 0x00
	#d8 0xd0
	#d8 0x00
	#d8 0xc0
	#d8 0x80
	#d8 0xc0
	#d8 0x80
	#d8 0xb0
	#d8 0x80
	#d8 0x90
	#d8 0x80
	#d8 0x80
	#d8 0x80
	#d8 0x70
	#d8 0x40
	#d8 0x60
	#d8 0x40
	#d8 0x50
	#d8 0x40
	#d8 0x40
	#d8 0x40
	#d8 0x30
	#d8 0x40
	#d8 0x20
	#d8 0x40
	#d8 0x20
	#d8 0x00
	#d8 0x50
	#d8 0x00
	#d8 0xc4
	#d8 0x00
	#d8 0x02
	#d8 0x80
	#d8 0x00
	#d8 0x80
	#d8 0xc0
	#d8 0x80
	#d8 0x60
	#d8 0x80
	#d8 0xe0
	#d8 0x00
	#d8 0x10
	#d8 0x00
	#d8 0x30
	#d8 0x00
	#d8 0x02
	#d8 0x00
	#d8 0x14
	#d8 0x80
	#d8 0x60
	#d8 0x80
	#d8 0x10
	#d8 0x80
	#d8 0x04
	#d8 0x80
	#d8 0x02
	#d8 0x80
	#d8 0x14
	#d8 0x40
	#d8 0x00
	#d8 0x40
	#d8 0xc0
	#d8 0x40
	#d8 0xa0
	#d8 0x40
	#d8 0x60
	#d8 0x40
	#d8 0xe0
	#d8 0x40
	#d8 0xe0
	#d8 0xd0
	#d8 0xc0
	#d8 0xb0
	#d8 0xa0
	#d8 0x90
	#d8 0x80
	#d8 0x70
	#d8 0x60
	#d8 0x50
	#d8 0x40
	#d8 0x20
	#d8 0x80
	#d8 0x70
	#d8 0x60
	#d8 0x40
	#d8 0x30
	#d8 0x20
	#d8 0x80
	#d8 0x70
	#d8 0x60
	#d8 0x50
	#d8 0x40
	#d8 0x30
	#d8 0x20
	#d8 0x20
	#d8 0xc0
	#d8 0xb0
	#d8 0xa0
	#d8 0x90
	#d8 0x80
	#d8 0x80
	#d8 0x70
	#d8 0x60
	#d8 0x50
	#d8 0x40
	#d8 0x30
	#d8 0x20
	#d8 0x20
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0xb0
	#d8 0xa0
	#d8 0x90
	#d8 0x90
	#d8 0x80
	#d8 0x70
	#d8 0x60
	#d8 0x50
	#d8 0x50
	#d8 0x40
	#d8 0x30
	#d8 0x20
	#d8 0x20
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x40
	#d8 0xc0
	#d8 0xc0
	#d8 0xa0
	#d8 0xe0
	#d8 0xe0
	#d8 0x50
	#d8 0x50
	#d8 0x04
	#d8 0xc0
	#d8 0xa0
	#d8 0xe0
	#d8 0x10
	#d8 0x50
	#d8 0xc4
	#d8 0x60
	#d8 0xe0
	#d8 0x90
	#d8 0xd0
	#d8 0x04
	#d8 0x70
	#d8 0x02
	#d8 0x02
	#d8 0x00
	#d8 0x40
	#d8 0xc0
	#d8 0x20
	#d8 0xa0
	#d8 0x60
	#d8 0xe0
	#d8 0x90
	#d8 0xd0
	#d8 0x04
	#d8 0x70
	#d8 0x02
	#d8 0x02
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x80
	#d8 0xc0
	#d8 0xa0
	#d8 0x60
	#d8 0xe0
	#d8 0xe0
	#d8 0x10
	#d8 0x50
	#d8 0x30
	#d8 0x84
	#d8 0xc4
	#d8 0xc4
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00
	#d8 0x00


F_8f66:
	tst [0x005a]
	bne .L_8f6c
	rts
.L_8f6c:
	lda A, 0x33
	sta.ext A, [0x0087]
	jsr F_8296
	std.ext [0x0062]
	lda.ext A, [0x0040]
	jsr F_a953
	bcc .L_8f88
	lda.ext A, [0x0040]
	ldx 0x0062
	jsr set_bit_double
.L_8f88:
	ldd.ext [0x0062]
	clr [0x0088]
	ldx 0x0010
.L_8f91:
	asld
	bcc .L_8f97
	inc [0x0088]
.L_8f97:
	dex
	bne .L_8f91
	lda.ext A, [0x0088]
	cmp A, 0x2
	bcc .L_8fa2
	rts
.L_8fa2:
	gpio_off BUSY_IND ;BUSY_IND=0
	oim bit2, [0x71]
	jsr F_98fc
	jsr F_9a57
	oim bit0, [0x6d]
	lda.ext A, [0x0041]
	jsr F_a961
	bcs .L_8fc4
.L_8fb9:
	cim bit0, [0x6f]
	oim bit2, [0x70]
	oim bit7, [0x70]
	bra .L_8fd8
.L_8fc4:
	lda.ext A, [0x0041]
	jsr F_a953
	bcc .L_8fb9
	lda.ext A, [0x0041]
	ldx 0x0062
	jsr clear_bit_double
	cim bit7, [0x70]
.L_8fd8:
	jsr F_94f2
.L_8fdb:
	cim bit6, [0x6f]
	cim bit7, [0x6f]
	cim bit3, [0x6f]
	cim bit3, [0x6e]
	cim bit6, [0x70]
	cim bit4, [0x70]
	cim bit7, [0x72]
	tim bit7, [0x70]
	beq .L_8ffd
	jsr lcd_seg_1_7_off
	oim bit6, [0x70]
	bra .L_9000
.L_8ffd:
	oim bit4, [0x70]
.L_9000:
	tim bit5, [0x6d]
	beq .L_9010
	jsr F_938a
	tim bit4, [0x6b]
	beq .L_8fdb
	jmp .L_915a
.L_9010:
	tim bit7, [0x70]
	bne .L_9025
	tim bit0, [0x6f]
	bne .L_9025
	oim bit0, [0x6f]
	cim bit2, [0x70]
	jsr F_857f
	bra .L_9031
.L_9025:
	oim bit2, [0x70]
	cim bit0, [0x6f]
	jsr F_9479
	jsr F_859b
.L_9031:
	jsr F_a26b
	jsr F_a257
	tst B
	beq .L_903f
	gpio_on BUSY_IND ;BUSY_IND=1
	bra .L_904d
.L_903f:
	gpio_off BUSY_IND ;BUSY_IND=0
	jsr F_944f
	tim bit4, [0x6b]
	beq .L_9000
	jmp .L_915a
.L_904d:
	tim bit1, [0x6e]
	bne .L_9054
	bra .L_9074
.L_9054:
	lda A, 0x6
	sta.ext A, [0x008a]
.L_9059:
	jsr F_9522
.L_905c:
	jsr delay_7000
	jsr update_busy_indicator
	tim bit2, [0x6f]
	bne .L_9074
	tim bit5, [TCSR2]
	beq .L_905c
	dec [0x008a]
	bne .L_9059
	jmp .L_9000
.L_9074:
	tim bit7, [0x70]
	bne .L_908f
	tim bit0, [0x6f]
	bne .L_909d
	cim bit4, [0x70]
	oim bit7, [0x72]
	jsr lcd_seg_4_7_on
	lda.ext A, [0x0042]
	jsr F_bc0b
	bra .L_90b4
.L_908f:
	cim bit6, [0x70]
	jsr lcd_seg_4_7_on
	lda.ext A, [0x0042]
	jsr F_bc0b
	bra .L_90b4
.L_909d:
	cim bit4, [0x70]
	jsr lcd_seg_4_7_on
	jsr lcd_seg_1_7_on
	lda.ext A, [0x0041]
	jsr F_bc0b
	cim bit6, [0x6f]
	cim bit3, [0x6f]
	bra .L_90b7
.L_90b4:
	jsr F_94d5
.L_90b7:
	jsr delay_7000
	jsr update_busy_indicator
	tim bit2, [0x6f]
	beq .L_90ca
	cim bit7, [0x6f]
	cim bit3, [0x6e]
	bra .L_90d2
.L_90ca:
	tim bit7, [0x6f]
	bne .L_90d2
	jsr F_94c2
.L_90d2:
	tim bit7, [0x6d]
	beq .L_90da
	jmp .L_9103
.L_90da:
	tim bit7, [0x6b]
	beq .L_90eb
	cim bit7, [0x6b]
	cim bit0, [0x6e]
	jsr F_98fc
	jmp .L_8fdb
.L_90eb:
	tim bit4, [0x6b]
	beq .L_90f3
	jmp .L_915a
.L_90f3:
	tim bit3, [0x6f]
	beq .L_90fb
	jmp .L_8fdb
.L_90fb:
	tim bit3, [0x6e]
	beq .L_90b7
	jmp .L_8fdb
.L_9103:
	cim bit6, [0x6f]
	cim bit7, [0x6f]
	cim bit3, [0x6f]
	cim bit3, [0x6e]
	tim bit7, [0x70]
	bne .L_9127
	tim bit0, [0x6f]
	bne .L_9127
	cim bit7, [0x72]
	jsr lcd_seg_1_7_off
	jsr F_85fe
	oim bit7, [0x72]
	bra .L_912a
.L_9127:
	jsr F_85fe
.L_912a:
	jsr delay_7000
	jsr update_busy_indicator
	tim bit2, [0x6f]
	beq .L_913d
	cim bit7, [0x6f]
	cim bit3, [0x6e]
	bra .L_9145
.L_913d:
	tim bit7, [0x6f]
	bne .L_9145
	jsr F_94c2
.L_9145:
	tim bit7, [0x6d]
	bne .L_9103
	oim bit6, [0x6d]
	tim bit4, [0x6b]
	bne .L_915a
	tim bit3, [0x6e]
	beq .L_912a
	jmp .L_8fdb
.L_915a:
	jsr F_a28e
	jsr F_98fc
	cim bit4, [0x6b]
	cim bit6, [0x6f]
	cim bit7, [0x6f]
	cim bit3, [0x6f]
	cim bit3, [0x6e]
	cim bit0, [0x6f]
	cim bit2, [0x70]
	cim bit3, [0x6c]
	cim bit0, [0x6d]
	cim bit6, [0x70]
	cim bit5, [0x70]
	cim bit4, [0x70]
	cim bit7, [0x72]
	jsr lcd_c5_off
	jsr lcd_c6_off
	jsr F_84c8
	rts


F_9191:
	lda.ext A, [0x0041]
	cmp A, 0x10
	bne .L_9199
	rts
.L_9199:
	cmp.ext A, [0x0040]
	bne .L_919f
	rts
.L_919f:
	lda.ext A, [0x0041]
	jsr F_a953
	bcs .L_91a8
	rts
.L_91a8:
	lda.ext A, [0x0040]
	jsr F_a953
	bcs .L_91b1
	rts
.L_91b1:
	gpio_off BUSY_IND
	oim bit2, [0x71]
	jsr F_98fc
	jsr F_9a57
	oim bit3, [0x6c]
	cim bit2, [0x70]
	jsr F_94f2
.L_91c6:
	cim bit7, [0x6f]
	cim bit3, [0x6e]
	cim bit6, [0x6f]
	cim bit3, [0x6f]
	cim bit7, [0x72]
	oim bit5, [0x70]
.L_91d8:
	tim bit5, [0x6d]
	beq .L_91e8
	jsr F_93ee
	tim bit4, [0x6b]
	beq .L_91e8
	jmp .L_9353
.L_91e8:
	tim bit0, [0x6f]
	bne .L_91f5
	oim bit0, [0x6f]
	jsr F_857f
	bra .L_91fb
.L_91f5:
	cim bit0, [0x6f]
	jsr F_8563
.L_91fb:
	jsr F_a26b
	jsr F_a257
	tst B
	beq .L_9209
	gpio_on BUSY_IND
	bra .L_9228
.L_9209:
	gpio_off BUSY_IND
	tim bit7, [0x6d]
	beq .L_9220
	cim bit0, [0x6f]
	cim bit5, [0x70]
	lda.ext A, [0x0040]
	jsr F_bc0b
	jmp .L_92dd
.L_9220:
	tim bit4, [0x6b]
	beq .L_91d8
	jmp .L_9353
.L_9228:
	tim bit1, [0x6e]
	bne .L_922f
	bra .L_924f
.L_922f:
	lda A, 0x6
	sta.ext A, [0x008a]
.L_9234:
	jsr F_9522
.L_9237:
	jsr delay_7000
	jsr update_busy_indicator
	tim bit2, [0x6f]
	bne .L_924f
	tim bit5, [TCSR2]
	beq .L_9237
	dec [0x008a]
	bne .L_9234
	jmp .L_91d8
.L_924f:
	cim bit5, [0x70]
	tim bit0, [0x6f]
	bne .L_926d
	oim bit7, [0x72]
	lda.ext A, [0x0040]
	jsr F_bc0b
	lda A, 0x26
	sta.ext A, [0x0077]
	cim bit3, [0x6f]
	oim bit6, [0x6f]
	bra .L_927c
.L_926d:
	jsr lcd_seg_1_7_on
	lda.ext A, [0x0041]
	jsr F_bc0b
	cim bit6, [0x6f]
	cim bit3, [0x6f]
.L_927c:
	jsr delay_7000
	jsr update_busy_indicator
	tim bit0, [0x6f]
	bne .L_92a2
	tim bit2, [0x6f]
	bne .L_9294
	cim bit7, [0x72]
	oim bit5, [0x70]
	bra .L_92b7
.L_9294:
	cim bit5, [0x70]
	oim bit7, [0x72]
	lda.ext A, [0x0040]
	jsr F_bc0b
	bra .L_92b7
.L_92a2:
	tim bit2, [0x6f]
	beq .L_92af
	cim bit7, [0x6f]
	cim bit3, [0x6e]
	bra .L_92b7
.L_92af:
	tim bit7, [0x6f]
	bne .L_92b7
	jsr F_94c2
.L_92b7:
	tim bit7, [0x6d]
	beq .L_92bf
	jmp .L_92dd
.L_92bf:
	jsr F_940b
	tim bit4, [0x6b]
	beq .L_92ca
	jmp .L_9353
.L_92ca:
	tim bit3, [0x6f]
	beq .L_92d2
	jmp .L_91c6
.L_92d2:
	tim bit3, [0x6e]
	beq .L_92da
	jmp .L_91c6
.L_92da:
	jmp .L_927c
.L_92dd:
	cim bit6, [0x6f]
	cim bit7, [0x6f]
	cim bit3, [0x6f]
	cim bit3, [0x6e]
	tim bit0, [0x6f]
	bne .L_9307
	cim bit7, [0x72]
	jsr lcd_seg_1_7_off
	jsr F_85fe
	oim bit7, [0x72]
	lda A, 0x26
	sta.ext A, [0x0077]
	cim bit3, [0x6f]
	oim bit6, [0x6f]
	bra .L_930a
.L_9307:
	jsr F_85fe
.L_930a:
	jsr delay_7000
	jsr update_busy_indicator
	tim bit0, [0x6f]
	beq .L_932a
	tim bit2, [0x6f]
	beq .L_9322
	cim bit7, [0x6f]
	cim bit3, [0x6e]
	bra .L_932a
.L_9322:
	tim bit7, [0x6f]
	bne .L_932a
	jsr F_94c2
.L_932a:
	tim bit7, [0x6d]
	beq .L_9332
	jmp .L_92dd
.L_9332:
	oim bit6, [0x6d]
	jsr F_940b
	tim bit4, [0x6b]
	beq .L_9340
	jmp .L_9353
.L_9340:
	tim bit3, [0x6f]
	beq .L_9348
	jmp .L_91c6
.L_9348:
	tim bit3, [0x6e]
	beq .L_9350
	jmp .L_91c6
.L_9350:
	jmp .L_930a
.L_9353:
	jsr F_a28e
	jsr F_98fc
	cim bit4, [0x6b]
	cim bit6, [0x6f]
	cim bit7, [0x6f]
	cim bit3, [0x6f]
	cim bit3, [0x6e]
	cim bit0, [0x6f]
	cim bit2, [0x70]
	cim bit3, [0x6c]
	cim bit0, [0x6d]
	cim bit6, [0x70]
	cim bit5, [0x70]
	cim bit4, [0x70]
	cim bit7, [0x72]
	jsr lcd_c5_off
	jsr lcd_c6_off
	jsr F_84c8
	rts


F_938a:
.L_938a:
	cim bit5, [0x6d]
	lda A, 0x33
	sta.ext A, [0x0087]
	jsr F_8296
	std.ext [0x0062]
	lda.ext A, [0x0040]
	jsr F_a953
	bcc .L_93a9
	lda.ext A, [0x0040]
	ldx 0x0062
	jsr set_bit_double
.L_93a9:
	ldd.ext [0x0062]
	clr [0x0088]
	ldx 0x0010
.L_93b2:
	asld
	bcc .L_93b8
	inc [0x0088]
.L_93b8:
	dex
	bne .L_93b2
	lda.ext A, [0x0088]
	cmp A, 0x2
	bcc .L_93cb
	jsr F_941e
	tim bit4, [0x6b]
	beq .L_938a
	rts
.L_93cb:
	lda.ext A, [0x0041]
	jsr F_a961
	bcs .L_93d5
	bra .L_93dd
.L_93d5:
	lda.ext A, [0x0041]
	jsr F_a953
	bcs .L_93e1
.L_93dd:
	oim bit7, [0x70]
	rts
.L_93e1:
	cim bit7, [0x70]
	lda.ext A, [0x0041]
	ldx 0x0062
	jsr clear_bit_double
	rts


F_93ee:
.L_93ee:
	cim bit5, [0x6d]
	lda.ext A, [0x0040]
	jsr F_a953
	bcc .L_9402
	lda.ext A, [0x0040]
	cmp.ext A, [0x0041]
	beq .L_9402
	rts
.L_9402:
	jsr F_941e
	tim bit4, [0x6b]
	beq .L_93ee
	rts


F_940b:
	tim bit5, [0x6d]
	bne .L_9411
	rts
.L_9411:
	tim bit0, [0x6f]
	beq .L_9417
	rts
.L_9417:
	oim bit3, [0x6f]
	jsr F_a28e
	rts


F_941e:
	jsr F_a28e
.L_9421:
	jsr F_9942
.L_9424:
	tim bit5, [0x6d]
	bne .L_9445
	tim bit4, [0x6b]
	bne .L_9445
	tim bit3, [0x71]
	bne .L_9424
	ldx 0x61a8
.L_9436:
	tim bit5, [0x6d]
	bne .L_9445
	tim bit4, [0x6b]
	bne .L_9445
	dex
	bne .L_9436
	bra .L_9421
.L_9445:
	clr [TCSR3]
	cim bit3, [0x71]
	jsr F_a28e
	rts


F_944f:
	tim bit7, [0x6d]
	bne .L_9455
	rts
.L_9455:
	jsr F_9942
.L_9458:
	tim bit7, [0x6d]
	beq .L_946f
	tim bit3, [0x71]
	bne .L_9458
	ldx 0x9fcc
.L_9465:
	tim bit7, [0x6d]
	beq .L_946f
	dex
	bne .L_9465
	bra .L_9455
.L_946f:
	clr [TCSR3]
	cim bit3, [0x71]
	jsr F_a28e
	rts


F_9479:
	lda.ext A, [0x0042]
	cmp A, 0xf
	bne .L_9497
.L_9480:
	clr [0x0088]
	ldd.ext [0x0062]
.L_9486:
	asld
	bcs .L_94bb
	inc [0x0088]
	xgdx
	lda.ext A, [0x0088]
	cmp A, 0x10
	xgdx
	bne .L_9486
	bra .L_9480
.L_9497:
	clr [0x0088]
	ldd.ext [0x0062]
.L_949d:
	asld
	xgdx
	lda.ext A, [0x0088]
	cmp.ext A, [0x0042]
	xgdx
	beq .L_94b6
	inc [0x0088]
	xgdx
	lda.ext A, [0x0088]
	cmp A, 0xf
	xgdx
	bne .L_949d
	bra .L_9480
.L_94b6:
	inc [0x0088]
	bra .L_9486
.L_94bb:
	lda.ext A, [0x0088]
	sta.ext A, [0x0042]
	rts


F_94c2:
	lda.ext A, [0x0059]
	and A, 0xf
	inc A
	lda B, 0x8
	mul
	sta.ext B, [0x0076]
	cim bit3, [0x6e]
	oim bit7, [0x6f]
	rts


F_94d5:
	lda.ext A, [0x005a]
	and A, 0xf
	cmp A, 0xf
	beq .L_94eb
	lda B, 0xf
	mul
	sta.ext B, [0x0077]
	cim bit3, [0x6f]
	oim bit6, [0x6f]
	rts
.L_94eb:
	cim bit3, [0x6f]
	cim bit6, [0x6f]
	rts


F_94f2:
	jsr lcd_c1_off
	jsr lcd_c2_off
	jsr lcd_c3_off
	jsr lcd_c4_off
	jsr lcd_c5_off
	jsr lcd_c6_off
	jsr lcd_seg_4_7_off
	jsr lcd_seg_1_7_off
	jsr lcd_seg_5_7_off
	lda A, 0x3
	sta.ext A, [0x007e]
	cim bit3, [0x70]
	cim bit6, [0x70]
	cim bit5, [0x70]
	cim bit4, [0x70]
	cim bit7, [0x72]
	rts


F_9522:
	ldd.ext [FRC]
	addd 0xea60
	std.ext [OCR2]
	lda.ext A, [TCSR2]
	ldd.ext [OCR2]
	std.ext [OCR2]
	rts


F_9535:
.L_9535:
	tim bit0, [0x6a]
	bne .L_9572
	tim bit1, [0x6a]
	bne .L_9576
	tim bit2, [0x6a]
	bne .L_957a
	tim bit3, [0x6a]
	bne .L_957e
	tim bit4, [0x6a]
	bne .L_9582
	tim bit5, [0x6a]
	bne .L_9586
	tim bit6, [0x6a]
	bne .L_958a
	tim bit7, [0x6a]
	bne .L_958e
	tim bit0, [0x6b]
	bne .L_9592
	tim bit1, [0x6b]
	bne .L_9596
	tim bit2, [0x6b]
	bne .L_959a
	tim bit3, [0x6b]
	bne .L_959e
	rts
.L_9572:
	lda A, 0x0
	bra .L_95a0
.L_9576:
	lda A, 0x2
	bra .L_95a0
.L_957a:
	lda A, 0x4
	bra .L_95a0
.L_957e:
	lda A, 0x6
	bra .L_95a0
.L_9582:
	lda A, 0x8
	bra .L_95a0
.L_9586:
	lda A, 0xa
	bra .L_95a0
.L_958a:
	lda A, 0xc
	bra .L_95a0
.L_958e:
	lda A, 0xe
	bra .L_95a0
.L_9592:
	lda A, 0x10
	bra .L_95a0
.L_9596:
	lda A, 0x12
	bra .L_95a0
.L_959a:
	lda A, 0x14
	bra .L_95a0
.L_959e:
	lda A, 0x16
.L_95a0:
	sta.ext A, [mul16_res]
	lda.ext A, [0x0040]
	jsr F_a945
	bcs .L_95ac
	rts
.L_95ac:
	ldx 0x9712
	lda.ext B, [mul16_res]
	abx
	ldd [X]
	std.ext [0x0051]
	ldx 0x972a
	lda.ext B, [mul16_res]
	abx
	ldd [X]
	std.ext [0x0053]
	ldx 0x9742
	lda.ext B, [mul16_res]
	abx
	ldd [X]
	std.ext [0x0055]
	clr [0x006a]
	aim 0xf0, [0x6b]
	cim bit4, [TCSR1]
	cim bit3, [TCSR1]
	jsr F_9a57
	oim bit2, [0x71]
	jsr lcd_seg_0_7_off
	gpio_off MIC_OFF
	tim bit0, [0x95]
	beq .L_95f0
	jsr F_9764
.L_95f0:
	jsr F_975a
	jsr F_975a
	jsr F_a2a6
	ldd.ext [FRC]
	addd.ext [0x0055]
	std.ext [OCR1]
	lda.ext A, [TCSR1]
	ldd.ext [OCR1]
	std.ext [OCR1]
	ldd.ext [FRC]
	addd.ext [0x0053]
	std.ext [OCR2]
	lda.ext A, [TCSR2]
	ldd.ext [OCR2]
	std.ext [OCR2]
	oim bit0, [0x72]
	cim bit0, [TCSR1]
	cim bit2, [TCSR2]
	oim bit0, [TCSR2]
	oim bit1, [TCSR2]
	oim bit3, [TCSR1]
	oim bit3, [TCSR2]
.L_9632:
	tim bit7, [0x71]
	beq .L_9632
	cim bit7, [0x71]
.L_963a:
	tim bit0, [0x6e]
	beq .L_963a
	cim bit3, [TCSR1]
	cim bit3, [TCSR2]
	cim bit0, [TCSR2]
	cim bit1, [TCSR2]
	gpio_off TONEH 
	gpio_off TONEL 
	cim bit0, [0x72]
	ldd 0x001e
	std.ext [0x0076]
	cim bit3, [0x72]
	oim bit4, [0x72]
	jsr F_a2b0
	lda.ext A, [TCSR1]
	lda.ext A, [FRCH]
	oim bit2, [TCSR1]
.L_966c:
	tst [0x006a]
	bne .L_967f
	lda.ext A, [0x006b]
	and A, 0xf
	bne .L_967f
	tim bit3, [0x72]
	beq .L_966c
	bra .L_9682
.L_967f:
	jmp .L_9535
.L_9682:
	cim bit1, [0x6f]
	clr [TCSR3]
	oim bit0, [0x95]
	lda.ext A, [0x0095]
	sta A, [PERIPH3.PORTA]
	jsr delay_10k
	cim bit7, [per2portb]
	lda.ext A, [per2portb]
	sta A, [PERIPH2.PORTB]
	jsr delay_10k
	cim bit1, [0x98]
	cim bit2, [0x98]
	oim bit4, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	jsr lcd_seg_3_7_off
	gpio_on MIC_OFF 
	cim bit3, [0x6e]
	cim bit7, [0x6f]
	jsr F_84c8
	ldd.ext [FRC]
	addd 0x2710
	std.ext [OCR1]
	lda.ext A, [TCSR1]
	ldd.ext [OCR1]
	std.ext [OCR1]
	oim bit3, [TCSR1]
	rts


F_96d4:
	tim bit6, [TCSR1]
	beq .L_96ef
	eim 0x1, [TCSR1]
	ldd.ext [OCR1]
	addd.ext [0x0055]
	std.ext [OCR1]
	lda.ext A, [TCSR1]
	ldd.ext [OCR1]
	std.ext [OCR1]
	rts
.L_96ef:
	eim 0x4, [TCSR2]
	ldd.ext [OCR2]
	addd.ext [0x0053]
	std.ext [OCR2]
	lda.ext A, [TCSR2]
	ldd.ext [OCR2]
	std.ext [OCR2]
	ldx.ext [0x0051]
	dex
	beq .L_970e
	stx.ext [0x0051]
	rts
.L_970e:
	oim bit7, [0x71]
	rts
D_9712:
	#d8 0x00
	#d8 0xbc
	#d8 0x00
	#d8 0x8c
	#d8 0x00
	#d8 0x8c
	#d8 0x00
	#d8 0x8c
	#d8 0x00
	#d8 0x9a
	#d8 0x00
	#d8 0x9a
	#d8 0x00
	#d8 0x9a
	#d8 0x00
	#d8 0xaa
	#d8 0x00
	#d8 0xaa
	#d8 0x00
	#d8 0xaa
	#d8 0x00
	#d8 0xbc
	#d8 0x00
	#d8 0xb4
	#d8 0x02
	#d8 0x13
	#d8 0x02
	#d8 0xcd
	#d8 0x02
	#d8 0xcd
	#d8 0x02
	#d8 0xcd
	#d8 0x02
	#d8 0x89
	#d8 0x02
	#d8 0x89
	#d8 0x02
	#d8 0x89
	#d8 0x02
	#d8 0x4b
	#d8 0x02
	#d8 0x4b
	#d8 0x02
	#d8 0x4b
	#d8 0x02
	#d8 0x13
	#d8 0x02
	#d8 0x13
	#d8 0x01
	#d8 0x76
	#d8 0x01
	#d8 0x9e
	#d8 0x01
	#d8 0x76
	#d8 0x01
	#d8 0x53
	#d8 0x01
	#d8 0x9e
	#d8 0x01
	#d8 0x76
	#d8 0x01
	#d8 0x53
	#d8 0x01
	#d8 0x9e
	#d8 0x01
	#d8 0x76
	#d8 0x01
	#d8 0x53
	#d8 0x01
	#d8 0x9e
	#d8 0x01
	#d8 0x53


F_975a:
	ldx 0x1be6
.L_975d:
	dex
	nop
	nop
	nop
	bne .L_975d
	rts


F_9764:
	jsr F_a28e
	gpio_off BUSY_IND
	oim bit1, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	tim bit0, [0x71]
	beq .L_9781
	oim bit2, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
.L_9781:
	jsr F_87cb
	jsr delay_10k
	oim bit7, [per2portb]
	lda.ext A, [per2portb]
	sta A, [PERIPH2.PORTB]
	ldx 0x35b6
.L_9793:
	dex
	bne .L_9793
	cim bit0, [0x95]
	lda.ext A, [0x0095]
	sta A, [PERIPH3.PORTA]
	jsr delay_3000
	oim bit5, [0x96]
	lda.ext A, [0x0096]
	sta A, [PERIPH3.PORTB]
	rts


F_97ac:
	ldx 0x98d6
	lda.ext B, [0x0058]
	abx
	lda A, [X]
	sta.ext A, [TCONR]
	clr [0x0094]
	lda A, 0x1
	sta.ext A, [0x007d]
	clr [T2CNT]
	clr [TCSR3]
	oim bit0, [TCSR3]
	oim bit4, [TCSR3]
	oim bit6, [TCSR3]
	rts


F_97d0:
	lda.ext A, [0x0094]
	sta.ext A, [P6]
	tim bit0, [0x7d]
	bne .L_97ff
	tim bit1, [0x7d]
	bne .L_9805
	tim bit2, [0x7d]
	bne .L_980e
	tim bit3, [0x7d]
	bne .L_9817
	tim bit4, [0x7d]
	bne .L_9820
	tim bit5, [0x7d]
	bne .L_9829
	tim bit6, [0x7d]
	bne .L_9832
	clr [0x0094]
	sec
	bra .L_9839
.L_97ff:
	clr [0x0094]
	clc
	bra .L_9839
.L_9805:
	oim bit5, [0x94]
	cim bit4, [0x94]
	clc
	bra .L_9839
.L_980e:
	cim bit5, [0x94]
	oim bit4, [0x94]
	clc
	bra .L_9839
.L_9817:
	oim bit5, [0x94]
	oim bit4, [0x94]
	clc
	bra .L_9839
.L_9820:
	oim bit5, [0x94]
	oim bit4, [0x94]
	clc
	bra .L_9839
.L_9829:
	cim bit5, [0x94]
	oim bit4, [0x94]
	clc
	bra .L_9839
.L_9832:
	oim bit5, [0x94]
	cim bit4, [0x94]
	clc
.L_9839:
	rol [0x007d]
	rts


F_983d:
	sei
	ldx 0x98b0
	lda.ext B, [0x0057]
	abx
	lda B, [X]
	asl B
	asl B
	lda A, 0x6
	sta.ext A, [0x0085]
	cim bit2, [0x96]
	lda.ext A, [0x0096]
	sta A, [PERIPH3.PORTB]
	oim bit2, [0x96]
	lda.ext A, [0x0096]
	sta A, [PERIPH3.PORTB]
.L_9860:
	cim bit0, [0x96]
	lda.ext A, [0x0096]
	sta A, [PERIPH3.PORTB]
	asl B
	bcc .L_9877
	oim bit1, [0x96]
	lda.ext A, [0x0096]
	sta A, [PERIPH3.PORTB]
	bra .L_9880
.L_9877:
	cim bit1, [0x96]
	lda.ext A, [0x0096]
	sta A, [PERIPH3.PORTB]
.L_9880:
	oim bit0, [0x96]
	lda.ext A, [0x0096]
	sta A, [PERIPH3.PORTB]
	dec [0x0085]
	bne .L_9860
	cim bit0, [0x96]
	cim bit1, [0x96]
	lda.ext A, [0x0096]
	sta A, [PERIPH3.PORTB]
	cli
	rts
D_989c:
	#d8 0xce
	#d8 0xc3
	#d8 0x50
	#d8 0x09
	#d8 0x01
	#d8 0x01
	#d8 0x01
	#d8 0x26
	#d8 0xfa
	#d8 0x39


F_98a6:
	ldx 0xfb1d
.L_98a9:
	dex
	nop
	nop
	nop
	bne .L_98a9
	rts
D_98b0:
	#d8 0x00
	#d8 0x1d
	#d8 0x1c
	#d8 0x1b
	#d8 0x1a
	#d8 0x19
	#d8 0x18
	#d8 0x17
	#d8 0x16
	#d8 0x15
	#d8 0x39
	#d8 0x38
	#d8 0x37
	#d8 0x36
	#d8 0x35
	#d8 0x34
	#d8 0x33
	#d8 0x32
	#d8 0x31
	#d8 0x30
	#d8 0x2f
	#d8 0x2e
	#d8 0x2d
	#d8 0x2c
	#d8 0x2b
	#d8 0x2a
	#d8 0x29
	#d8 0x28
	#d8 0x27
	#d8 0x26
	#d8 0x25
	#d8 0x24
	#d8 0x23
	#d8 0x22
	#d8 0x21
	#d8 0x20
	#d8 0x1f
	#d8 0x1e
	#d8 0x00
	#d8 0xe8
	#d8 0xd8
	#d8 0xd1
	#d8 0xca
	#d8 0xc3
	#d8 0xbc
	#d8 0xb6
	#d8 0xaf
	#d8 0xaa
	#d8 0xa4
	#d8 0x9b
	#d8 0x96
	#d8 0x91
	#d8 0x8c
	#d8 0x87
	#d8 0x83
	#d8 0x7e
	#d8 0x7a
	#d8 0x76
	#d8 0x71
	#d8 0x6e
	#d8 0x6a
	#d8 0x66
	#d8 0x63
	#d8 0x5f
	#d8 0x5c
	#d8 0x59
	#d8 0x56
	#d8 0x53
	#d8 0x50
	#d8 0x4c
	#d8 0x49
	#d8 0x47
	#d8 0x44
	#d8 0x42
	#d8 0x40
	#d8 0x3d


;weird flow control here
F_98fc:
	gpio_test PROG_CONT ;
	beq F_9910
	tim bit6, [standby_something]
	beq F_9941


F_9906:
	tim bit5, [0x6e]
	bne F_9941
	tim bit4, [0x6e]
	bne F_9941


F_9910:
.L_9910:
	oim bit3, [0x71]
	oim bit3, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	jsr F_a2a6
	cim bit4, [TCSR3]
	oim bit0, [TCSR3]
	cim bit1, [TCSR3]
	oim bit2, [TCSR3]
	cim bit3, [TCSR3]
	cim bit7, [TCSR3]
	lda A, 0x27
	sta.ext A, [TCONR]
	lda A, 0x60
	sta.ext A, [0x0079]
	oim bit6, [TCSR3]
	oim bit4, [TCSR3]
F_9941:
	rts


F_9942:
	gpio_test PROG_CONT ;
	beq .L_9956
	tim bit6, [standby_something]
	beq .L_9987
	tim bit5, [0x6e]
	bne .L_9987
	tim bit4, [0x6e]
	bne .L_9987
.L_9956:
	oim bit3, [0x71]
	oim bit3, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	jsr F_a2a6
	cim bit4, [TCSR3]
	oim bit0, [TCSR3]
	cim bit1, [TCSR3]
	oim bit2, [TCSR3]
	cim bit3, [TCSR3]
	cim bit7, [TCSR3]
	lda A, 0xd0
	sta.ext A, [TCONR]
	lda A, 0x5a
	sta.ext A, [0x0079]
	oim bit6, [TCSR3]
	oim bit4, [TCSR3]
.L_9987:
	rts


F_9988:
	jsr F_9a29
	jsr F_98fc
	jsr lcd_seg_1_7_off
	lda A, 0x33
	sta.ext A, [0x0087]
	jsr F_8296
	std.ext [0x0062]
.L_999c:
	tim bit5, [0x6d]
	bne .L_99b2
	tim bit4, [0x6b]
	bne .L_99dc
	tim bit5, [0x6b]
	bne .L_99fb
	tim bit7, [0x6b]
	bne .L_9a1c
	bra .L_999c
.L_99b2:
	cim bit5, [0x6d]
	jsr F_bb57
	lda.ext A, [0x0040]
	jsr F_a953
	bcc .L_99c5
	jsr lcd_seg_5_7_on
	bra .L_99ca
.L_99c5:
	jsr lcd_seg_5_7_off
	bra .L_99d7
.L_99ca:
	lda.ext A, [0x0040]
	jsr F_a961
	bcc .L_99d7
	jsr lcd_seg_4_7_on
	bra .L_999c
.L_99d7:
	jsr lcd_seg_4_7_off
	bra .L_999c
.L_99dc:
	cim bit4, [0x6b]
	jsr F_98fc
	jsr lcd_seg_4_7_off
	lda.ext A, [0x0040]
	ldx 0x0062
	jsr clear_bit_double
.L_99ee:
	lda A, 0x33
	sta.ext A, [0x0087]
	ldd.ext [0x0062]
	jsr F_8348
	bra .L_999c
.L_99fb:
	cim bit5, [0x6b]
	lda.ext A, [0x0040]
	jsr F_a953
	bcs .L_9a0b
	jsr F_9942
	bra .L_999c
.L_9a0b:
	jsr F_98fc
	jsr lcd_seg_4_7_on
	lda.ext A, [0x0040]
	ldx 0x0062
	jsr set_bit_double
	bra .L_99ee
.L_9a1c:
	cim bit7, [0x6b]
	jsr F_98fc
	jsr F_84c8
	jsr F_9a67
	rts


F_9a29:
	cim bit3, [TCSR1]
	cim bit4, [TCSR1]
	jsr F_a28e
	gpio_off BUSY_IND
	oim bit2, [0x71]
	oim bit3, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	jsr lcd_seg_5_5_on
	jsr lcd_c3_off
	jsr lcd_seg_1_0_off
	jsr lcd_seg_0_7_off
	jsr lcd_c4_off
	jsr lcd_c5_off
	jsr lcd_c6_off
	rts


F_9a57:
	cim bit6, [0x6c]
	cim bit3, [0x6d]
	oim bit3, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	rts


F_9a67:
	jsr lcd_seg_5_5_off
	tim bit0, [0x71]
	beq .L_9a72
	jsr lcd_seg_1_0_on
.L_9a72:
	ldd.ext [FRC]
	addd 0x2710
	std.ext [OCR1]
	lda.ext A, [TCSR1]
	ldd.ext [OCR1]
	std.ext [OCR1]
	oim bit3, [TCSR1]
	rts


set_bit_double:
	cmp A, 0x0
	beq .L_9ac9
	cmp A, 0x1
	beq .L_9acd
	cmp A, 0x2
	beq .L_9ad1
	cmp A, 0x3
	beq .L_9ad5
	cmp A, 0x4
	beq .L_9ad9
	cmp A, 0x5
	beq .L_9add
	cmp A, 0x6
	beq .L_9ae1
	cmp A, 0x7
	beq .L_9ae5
	cmp A, 0x8
	beq .L_9ae9
	cmp A, 0x9
	beq .L_9aed
	cmp A, 0xa
	beq .L_9af1
	cmp A, 0xb
	beq .L_9af5
	cmp A, 0xc
	beq .L_9af9
	cmp A, 0xd
	beq .L_9afd
	cmp A, 0xe
	beq .L_9b01
	cmp A, 0xf
	beq .L_9b05
	rts
.L_9ac9:
	oim bit7, [X]
	rts
.L_9acd:
	oim bit6, [X]
	rts
.L_9ad1:
	oim bit5, [X]
	rts
.L_9ad5:
	oim bit4, [X]
	rts
.L_9ad9:
	oim bit3, [X]
	rts
.L_9add:
	oim bit2, [X]
	rts
.L_9ae1:
	oim bit1, [X]
	rts
.L_9ae5:
	oim bit0, [X]
	rts
.L_9ae9:
	oim bit7, [X + 0x1]
	rts
.L_9aed:
	oim bit6, [X + 0x1]
	rts
.L_9af1:
	oim bit5, [X + 0x1]
	rts
.L_9af5:
	oim bit4, [X + 0x1]
	rts
.L_9af9:
	oim bit3, [X + 0x1]
	rts
.L_9afd:
	oim bit2, [X + 0x1]
	rts
.L_9b01:
	oim bit1, [X + 0x1]
	rts
.L_9b05:
	oim bit0, [X + 0x1]
	rts


;A has bit (out of 16)
;X addr
clear_bit_double:
	cmp A, 0x0
	beq .L_9b4a
	cmp A, 0x1
	beq .L_9b4e
	cmp A, 0x2
	beq .L_9b52
	cmp A, 0x3
	beq .L_9b56
	cmp A, 0x4
	beq .L_9b5a
	cmp A, 0x5
	beq .L_9b5e
	cmp A, 0x6
	beq .L_9b62
	cmp A, 0x7
	beq .L_9b66
	cmp A, 0x8
	beq .L_9b6a
	cmp A, 0x9
	beq .L_9b6e
	cmp A, 0xa
	beq .L_9b72
	cmp A, 0xb
	beq .L_9b76
	cmp A, 0xc
	beq .L_9b7a
	cmp A, 0xd
	beq .L_9b7e
	cmp A, 0xe
	beq .L_9b82
	cmp A, 0xf
	beq .L_9b86
	rts
.L_9b4a:
	cim bit7, [X]
	rts
.L_9b4e:
	cim bit6, [X]
	rts
.L_9b52:
	cim bit5, [X]
	rts
.L_9b56:
	cim bit4, [X]
	rts
.L_9b5a:
	cim bit3, [X]
	rts
.L_9b5e:
	cim bit2, [X]
	rts
.L_9b62:
	cim bit1, [X]
	rts
.L_9b66:
	cim bit0, [X]
	rts
.L_9b6a:
	cim bit7, [X + 0x1]
	rts
.L_9b6e:
	cim bit6, [X + 0x1]
	rts
.L_9b72:
	cim bit5, [X + 0x1]
	rts
.L_9b76:
	cim bit4, [X + 0x1]
	rts
.L_9b7a:
	cim bit3, [X + 0x1]
	rts
.L_9b7e:
	cim bit2, [X + 0x1]
	rts
.L_9b82:
	cim bit1, [X + 0x1]
	rts
.L_9b86:
	cim bit0, [X + 0x1]
	rts


F_9b8a:
	jsr F_9a29
	jsr F_98fc
	jsr lcd_seg_4_7_off
.L_9b93:
	tim bit5, [0x6d]
	bne .L_9b9f
	tim bit5, [0x6b]
	bne .L_9bc9
	bra .L_9b93
.L_9b9f:
	cim bit5, [0x6d]
	jsr F_bb57
	lda.ext A, [0x0040]
	jsr F_a953
	bcc .L_9bb2
	jsr lcd_seg_5_7_on
	bra .L_9bb7
.L_9bb2:
	jsr lcd_seg_5_7_off
	bra .L_9bc4
.L_9bb7:
	lda.ext A, [0x0040]
	jsr F_a96f
	bcc .L_9bc4
	jsr lcd_seg_1_7_on
	bra .L_9b93
.L_9bc4:
	jsr lcd_seg_1_7_off
	bra .L_9b93
.L_9bc9:
	cim bit5, [0x6b]
	lda.ext A, [0x0040]
	jsr F_a953
	bcs .L_9bd9
	jsr F_9942
	bra .L_9bf9
.L_9bd9:
	jsr F_98fc
	clr [0x0060]
	clr [0x0061]
	lda.ext A, [0x0040]
	sta.ext A, [0x0041]
	ldx 0x0060
	jsr set_bit_double
	lda A, 0x34
	sta.ext A, [0x0087]
	ldd.ext [0x0060]
	jsr F_8348
.L_9bf9:
	jsr F_84c8
	jsr F_9a67
	rts


F_9c00:
	jsr F_98fc
	eim 0x1, [0x71]
	tim bit0, [0x71]
	bne .L_9c0f
	jsr lcd_seg_1_0_off
	rts
.L_9c0f:
	jsr lcd_seg_1_0_on
	rts


F_9c13:
	jsr F_98fc
	oim bit0, [0x69]
	rts


F_9c1a:
	jsr F_98fc
	cim bit0, [0x69]
	rts


F_9c21:
	jsr F_9a57
	jsr F_98fc
	lda.ext A, [0x0040]
	jsr F_a97d
	bcs .L_9c3a
	lda.ext A, [0x0040]
	ldx 0x0049
	jsr set_bit_double
	bra .L_9c43
.L_9c3a:
	lda.ext A, [0x0040]
	ldx 0x0049
	jsr clear_bit_double
.L_9c43:
	lda A, 0x0
	sta.ext A, [0x0087]
	ldd.ext [0x0049]
	jsr F_8348
	lda.ext A, [0x0040]
	jsr F_85e7
	oim bit6, [0x6c]
	rts


toi: ;timer interrupt
	cim bit2, [TCSR1] ;disable interrupt
	lda.ext A, [TCSR1] ;dummy read?
	lda.ext A, [FRCH] ;clear TOF
	cli ;disable interrupts
	jsr kbd_update
    gpio_test PROG_CONT
	bne .L_9c70
	jsr F_9ddb
	jmp .L_9cd1
.L_9c70:
	tim bit4, [0x72]
	beq .L_9c84
	ldx.ext [0x0076]
	dex
	bne .L_9c81
	oim bit3, [0x72]
	cim bit4, [0x72]
.L_9c81:
	stx.ext [0x0076]
.L_9c84:
	lda.ext A, [P5]
	com A
	clr B
	asl A
	bcc .L_9c8e
	ora B, 0x1
.L_9c8e:
	asl A
	bcc .L_9c93
	ora B, 0x2
.L_9c93:
	asl A
	bcc .L_9c98
	ora B, 0x4
.L_9c98:
	asl A
	bcc .L_9c9d
	ora B, 0x8
.L_9c9d:
	cmp.ext B, [0x0040]
	beq .L_9cad
	dec [0x008b]
	bne .L_9cb2
	sta.ext B, [0x0040]
	oim bit5, [0x6d]
.L_9cad:
	lda A, 0x3
	sta.ext A, [0x008b]
.L_9cb2:
	tim bit4, [0x6d]
	beq .L_9cba
	jsr check_lcd_timeout
.L_9cba:
	tim bit1, [0x6d]
	beq .L_9cc4
	jsr F_9da0
	bra .L_9cd4
.L_9cc4:
	tim bit0, [0x6d]
	bne .L_9cce
	tim bit3, [0x6c]
	beq .L_9cd1
.L_9cce:
	jsr F_9cd8
.L_9cd1:
	jsr F_9ea7
.L_9cd4:
	oim bit2, [TCSR1]
	rti


F_9cd8:
	tim bit7, [0x6f]
	beq .L_9ce5
	dec [0x0076]
	bne .L_9ce5
	oim bit3, [0x6e]
.L_9ce5:
	tim bit6, [0x6f]
	beq .L_9cf2
	dec [0x0077]
	bne .L_9cf2
	oim bit3, [0x6f]
.L_9cf2:
	tim bit6, [0x70]
	beq .L_9d1c
	dec [0x007e]
	beq .L_9cfd
	rts
.L_9cfd:
	tim bit3, [0x70]
	beq .L_9d0d
	jsr lcd_seg_4_7_off
	jsr lcd_num_off
	cim bit3, [0x70]
	bra .L_9d16
.L_9d0d:
	jsr lcd_seg_4_7_on
	jsr lcd_num_dash_dash
	oim bit3, [0x70]
.L_9d16:
	lda A, 0x3
	sta.ext A, [0x007e]
	rts
.L_9d1c:
	tim bit5, [0x70]
	beq .L_9d4c
	dec [0x007e]
	beq .L_9d27
	rts
.L_9d27:
	tim bit3, [0x70]
	beq .L_9d3a
	jsr lcd_seg_1_7_off
	jsr lcd_c5_off
	jsr lcd_c6_off
	cim bit3, [0x70]
	bra .L_9d46
.L_9d3a:
	jsr lcd_seg_1_7_on
	lda.ext A, [0x0040]
	jsr F_bc0b
	oim bit3, [0x70]
.L_9d46:
	lda A, 0x3
	sta.ext A, [0x007e]
	rts
.L_9d4c:
	tim bit4, [0x70]
	beq .L_9d7c
	dec [0x007e]
	beq .L_9d57
	rts
.L_9d57:
	tim bit3, [0x70]
	beq .L_9d6a
	jsr lcd_seg_4_7_off
	jsr lcd_seg_1_7_off
	jsr lcd_num_off
	cim bit3, [0x70]
	bra .L_9d76
.L_9d6a:
	jsr lcd_seg_4_7_on
	jsr lcd_seg_1_7_on
	jsr lcd_num_dash_dash
	oim bit3, [0x70]
.L_9d76:
	lda A, 0x3
	sta.ext A, [0x007e]
	rts
.L_9d7c:
	tim bit7, [0x72]
	beq .L_9d9f
	dec [0x007e]
	beq .L_9d87
	rts
.L_9d87:
	tim bit3, [0x70]
	beq .L_9d94
	jsr lcd_seg_1_7_off
	cim bit3, [0x70]
	bra .L_9d9a
.L_9d94:
	jsr lcd_seg_1_7_on
	oim bit3, [0x70]
.L_9d9a:
	lda A, 0x3
	sta.ext A, [0x007e]
.L_9d9f:
	rts


F_9da0:
	tim bit4, [0x6d]
	bne .L_9dbf
	tim bit2, [P5] ;BAT_CHECK
	beq .L_9dba
	dec [0x0073]
	bne .L_9dbf
	oim bit4, [0x6d]
	lda A, 0x7
	sta.ext A, [lcd_timeout]
	oim bit2, [0x6d]
.L_9dba:
	lda A, 0xa
	sta.ext A, [0x0073]
.L_9dbf:
	tim bit4, [0x6c]
	beq .L_9dda
	dec [0x0074]
	bne .L_9dda
	dec [0x0075]
	bne .L_9dd5
	cim bit6, [0x6d]
	cim bit4, [0x6c]
	rts
.L_9dd5:
	lda A, 0xe6
	sta.ext A, [0x0074]
.L_9dda:
	rts


F_9ddb:
	tim bit6, [0x71]
	beq .L_9e10
	dec [0x0056]
	bne .L_9e3a
	tim bit3, [0x70]
	beq .L_9dfb
	jsr lcd_c3_off
	jsr lcd_c4_off
	jsr lcd_c5_off
	jsr lcd_c6_off
	cim bit3, [0x70]
	bra .L_9e0a
.L_9dfb:
	jsr lcd_c3_P
	jsr lcd_c4_unk
	jsr lcd_c5_deg
	jsr lcd_c6_9
	oim bit3, [0x70]
.L_9e0a:
	lda A, 0x4
	sta.ext A, [0x0056]
	rts
.L_9e10:
	tim bit5, [0x71]
	beq .L_9e3a
	dec [0x0055]
	bne .L_9e1d
	oim bit4, [0x71]
.L_9e1d:
	dec [0x0056]
	bne .L_9e3a
	tim bit3, [0x70]
	beq .L_9e2f
	jsr lcd_c6_off
	cim bit3, [0x70]
	bra .L_9e35
.L_9e2f:
	jsr lcd_c6_dash
	oim bit3, [0x70]
.L_9e35:
	lda A, 0x4
	sta.ext A, [0x0056]
.L_9e3a:
	rts


kbd_update:
	clr [kbd_data0]
	clr [kbd_data1]
	clr [kbd_data2]

	oim 0x1f, [per2portb]
	cim bit4, [per2portb]
	jsr kbd_sample
	com A
	and A, 0xc
	sta.ext A, [kbd_data0] ;??? *should* be aut lmp scn??

	oim 0x1f, [per2portb]
	cim bit3, [per2portb]
	jsr kbd_sample
	asl A ;(~(A<<4))&0xf0
	asl A
	asl A
	asl A
	com A
	and A, 0xf0
	sta.ext A, [kbd_data1] ;upper 4 (NR|CHG|FCN|+?)

	oim 0x1f, [per2portb]
	cim bit2, [per2portb]
	jsr kbd_sample
	com A
	and A, 0xf
	ora.ext A, [kbd_data1] ;lower 4 = 3 6 9 #
	sta.ext A, [kbd_data1]

	oim 0x1f, [per2portb] 
	cim bit1, [per2portb]
	jsr kbd_sample
	asl A
	asl A
	asl A
	asl A
	com A
	and A, 0xf0
	sta.ext A, [kbd_data2] ;upper 4 = 2 5 8 0

	oim 0x1f, [per2portb]
	cim bit0, [per2portb]
	jsr kbd_sample
	com A
	and A, 0xf
	ora.ext A, [kbd_data2]
	sta.ext A, [kbd_data2] ;lower 4 = 1 4 7 *

	aim 0xe0, [per2portb]
	lda.ext A, [per2portb]
	sta A, [PERIPH2.PORTB]
	rts


F_9ea7:
	tim bit0, [0x6e]
	bne .L_9ebf
	tst [kbd_data0]
	bne .L_9ebe
	tst [kbd_data1]
	bne .L_9ebe
	tst [kbd_data2]
	bne .L_9ebe
	oim bit0, [0x6e]
.L_9ebe:
	rts
.L_9ebf:
	aim 0x81, [0x69]
	clr [0x006a]
	clr [0x006b]
	aim 0xf9, [0x6c]
	cim bit0, [0x6c]
	gpio_test PROG_CONT ;
	bne .L_9f02
	tim bit7, [0x69]
	beq .L_9ee5
	tim bit3, [kbd_data1]
	beq .L_9eff
	oim bit7, [0x6b]
	cim bit0, [0x6e]
	bra .L_9eff
.L_9ee5:
	tim bit3, [kbd_data1]
	beq .L_9efa
	oim bit7, [0x6b]
	dec [0x0080]
	bne .L_9eff
	oim bit7, [0x69]
	cim bit0, [0x6e]
	bra .L_9eff
.L_9efa:
	lda A, 0x2e
	sta.ext A, [0x0080]
.L_9eff:
	jmp .L_9fc3
.L_9f02:
	tim bit3, [kbd_data1]
	beq .L_9f4d
	oim bit7, [0x6b]
	tim bit3, [kbd_data0]
	bne .L_9f29
	tim bit2, [kbd_data0]
	bne .L_9f2f
	tim bit1, [kbd_data2]
	bne .L_9f35
	lda A, 0x2e
	sta.ext A, [0x007c]
	tim bit4, [kbd_data1]
	bne .L_9f41
	lda A, 0x2e
	sta.ext A, [0x007b]
	rts
.L_9f29:
	oim bit6, [0x69]
	jmp .L_a077
.L_9f2f:
	oim bit5, [0x69]
	jmp .L_a077
.L_9f35:
	dec [0x007c]
	beq .L_9f3b
	rts
.L_9f3b:
	oim bit2, [0x69]
	jmp .L_a077
.L_9f41:
	dec [0x007b]
	beq .L_9f47
	rts
.L_9f47:
	oim bit1, [0x69]
	jmp .L_a077
.L_9f4d:
	lda A, 0x2e
	sta.ext A, [0x007c]
	sta.ext A, [0x007b]
	tim bit0, [0x95]
	beq .L_9fc3
	tim bit7, [kbd_data1]
	bne .L_9f72
	cim bit2, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	lda A, 0x2e
	sta.ext A, [0x009b]
	sta.ext A, [0x009a]
	bra .L_9fc3
.L_9f72:
	tim bit0, [kbd_data2]
	bne .L_9fa4
	lda A, 0x2e
	sta.ext A, [0x009a]
	tim bit0, [0x71]
	bne .L_9f8c
	cim bit2, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	bra .L_9f95
.L_9f8c:
	oim bit2, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
.L_9f95:
	dec [0x009b]
	beq .L_9f9b
	rts
.L_9f9b:
	oim bit6, [0x6b]
	lda A, 0x2e
	sta.ext A, [0x009b]
	rts
.L_9fa4:
	lda A, 0x2e
	sta.ext A, [0x009b]
	cim bit2, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	dec [0x009a]
	beq .L_9fb8
	rts
.L_9fb8:
	oim bit0, [0x6c]
	lda A, 0x2e
	sta.ext A, [0x009a]
	jmp .L_a077
.L_9fc3:
	tim bit3, [kbd_data0]
	bne .L_9fcf
	tim bit2, [kbd_data0]
	bne .L_9fd5
	bra .L_9fdb
.L_9fcf:
	oim bit2, [0x6c]
	jmp .L_a077
.L_9fd5:
	oim bit1, [0x6c]
	jmp .L_a077
.L_9fdb:
	tst [kbd_data1]
	beq .L_a023
	tim bit6, [kbd_data1]
	bne .L_9fff
	tim bit5, [kbd_data1]
	bne .L_a005
	tim bit4, [kbd_data1]
	bne .L_a00b
	tim bit2, [kbd_data1]
	bne .L_a011
	tim bit1, [kbd_data1]
	bne .L_a017
	tim bit0, [kbd_data1]
	bne .L_a01d
	rts
.L_9fff:
	oim bit3, [0x6a]
	jmp .L_a077
.L_a005:
	oim bit2, [0x6a]
	jmp .L_a077
.L_a00b:
	oim bit1, [0x6a]
	jmp .L_a077
.L_a011:
	oim bit6, [0x6a]
	jmp .L_a077
.L_a017:
	oim bit5, [0x6a]
	jmp .L_a077
.L_a01d:
	oim bit4, [0x6a]
	jmp .L_a077
.L_a023:
	tst [kbd_data2]
	beq .L_a07a
	tim bit7, [kbd_data2]
	bne .L_a051
	tim bit6, [kbd_data2]
	bne .L_a056
	tim bit5, [kbd_data2]
	bne .L_a05b
	tim bit4, [kbd_data2]
	bne .L_a060
	tim bit3, [kbd_data2]
	bne .L_a065
	tim bit2, [kbd_data2]
	bne .L_a06a
	tim bit1, [kbd_data2]
	bne .L_a06f
	tim bit0, [kbd_data2]
	bne .L_a074
	rts
.L_a051:
	oim bit5, [0x6b]
	bra .L_a077
.L_a056:
	oim bit1, [0x6b]
	bra .L_a077
.L_a05b:
	oim bit0, [0x6b]
	bra .L_a077
.L_a060:
	oim bit7, [0x6a]
	bra .L_a077
.L_a065:
	oim bit4, [0x6b]
	bra .L_a077
.L_a06a:
	oim bit3, [0x6b]
	bra .L_a077
.L_a06f:
	oim bit0, [0x6a]
	bra .L_a077
.L_a074:
	oim bit2, [0x6b]
.L_a077:
	cim bit0, [0x6e]
.L_a07a:
	rts


kbd_sample:
.L_a07b:
	lda.ext A, [per2portb]
	sta A, [PERIPH2.PORTB] ;column
	brn .L_a07b
	lda A, [PERIPH2.PORTC] ;row
	rts


oci:
	tim bit0, [0x72]
	beq .L_a090
	jsr F_96d4
	rti
.L_a090:
	cim bit3, [TCSR1]
	cim bit2, [TCSR1]
	ldd.ext [OCR1]
	addd 0x2710
	std.ext [OCR1]
	lda.ext A, [TCSR1]
	ldd.ext [OCR1]
	std.ext [OCR1]
	cli
	tim bit3, [P5] ;CHSEL3
	bne .L_a0b3
	oim bit7, [0x6d]
	bra .L_a0b6
.L_a0b3:
	cim bit7, [0x6d]
.L_a0b6:
	tim bit1, [0x6d]
	beq .L_a0be
.L_a0bb:
	jmp .L_a22d
.L_a0be:
	tim bit0, [0x6d]
	bne .L_a0bb
	tim bit3, [0x6c]
	bne .L_a0bb
	tim bit3, [0x71]
	bne .L_a0bb
	tim bit2, [0x71]
	beq .L_a0bb
	tim bit1, [P5]
	bne .L_a0da
	jmp .L_a1c1
.L_a0da:
	tim bit6, [0x6c]
	bne .L_a0e2
	jmp .L_a14e
.L_a0e2:
	dec [0x0078]
	beq .L_a0ea
	jmp .L_a22d
.L_a0ea:
	oim bit3, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	jsr delay_7000
	jsr F_8d25
	jsr F_a26b
	jsr F_a257
	tst B
	beq .L_a118
	jsr update_busy_indicator
	oim bit3, [0x6d]
	lda A, 0xf
	sta.ext A, [0x009d]
	lda A, 0xfa
	sta.ext A, [0x0089]
	cim bit6, [0x6c]
	jmp .L_a21b
.L_a118:
	jsr F_a28e
	gpio_off BUSY_IND
	lda.ext A, [standby_something]
	and A, 0x30
	cmp A, 0x0
	beq .L_a131
	cmp A, 0x10
	beq .L_a135
	cmp A, 0x20
	beq .L_a139
	bra .L_a13d
.L_a131:
	lda A, 0xe
	bra .L_a13f
.L_a135:
	lda A, 0x1c
	bra .L_a13f
.L_a139:
	lda A, 0x32
	bra .L_a13f
.L_a13d:
	lda A, 0x5a
.L_a13f:
	sta.ext A, [0x0078]
	cim bit3, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	jmp .L_a21b
.L_a14e:
	tim bit3, [0x6d]
	bne .L_a156
	jmp .L_a22d
.L_a156:
	tst [0x009d]
	beq .L_a15e
	dec [0x009d]
.L_a15e:
	gpio_test BUSY
	beq .L_a16e
	jsr update_busy_indicator
	lda A, 0xfa
	sta.ext A, [0x0089]
	jmp .L_a22d
.L_a16e:
	gpio_off BUSY_IND
	jsr F_a28e
	tst [0x009d]
	bne .L_a183
	lda A, [PERIPH2.PORTC]
	and A, 0x10
	beq .L_a183
	jmp .L_a20d
.L_a183:
	dec [0x0089]
	beq .L_a18b
	jmp .L_a22d
.L_a18b:
	oim bit6, [0x6c]
	cim bit3, [0x6d]
	lda.ext A, [standby_something]
	and A, 0x30
	cmp A, 0x0
	beq .L_a1a4
	cmp A, 0x10
	beq .L_a1a8
	cmp A, 0x20
	beq .L_a1ac
	bra .L_a1b0
.L_a1a4:
	lda A, 0xe
	bra .L_a1b2
.L_a1a8:
	lda A, 0x1c
	bra .L_a1b2
.L_a1ac:
	lda A, 0x32
	bra .L_a1b2
.L_a1b0:
	lda A, 0x5a
.L_a1b2:
	sta.ext A, [0x0078]
	cim bit3, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	jmp .L_a22d
.L_a1c1:
	oim bit3, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	cim bit6, [0x6c]
	oim bit3, [0x6d]
	lda A, 0xfa
	sta.ext A, [0x0089]
	gpio_test BUSY
	beq .L_a1e3
	gpio_on BUSY_IND
.L_a1dd:
	jsr F_a27b
	jmp .L_a22d
.L_a1e3:
	gpio_off BUSY_IND
	lda A, [PERIPH2.PORTC]
	and A, 0x10
	beq .L_a1dd
	jsr delay_7000
	jsr F_8d25
	jsr F_a26b
	jsr F_a257
	ldd.ext [FRC]
	addd 0x2710
	std.ext [OCR1]
	lda.ext A, [TCSR1]
	ldd.ext [OCR1]
	std.ext [OCR1]
	bra .L_a1dd
.L_a20d:
	jsr F_8d25
	jsr F_a26b
	jsr F_a257
	lda A, 0xfa
	sta.ext A, [0x0089]
.L_a21b:
	ldd.ext [FRC]
	addd 0x2710
	std.ext [OCR1]
	lda.ext A, [TCSR1]
	ldd.ext [OCR1]
	std.ext [OCR1]
.L_a22d:
	oim bit3, [TCSR1]
	oim bit2, [TCSR1]
	rti


update_busy_indicator:
    gpio_test BUSY
	beq .off
	gpio_on BUSY_IND
	tim bit1, [0x6e]
	beq .L_a246
	gpio_test TSQ
	beq .L_a250
.L_a246:
	oim bit2, [0x6f]
	jsr F_a27b
	rts
.off:
	gpio_off BUSY_IND
.L_a250:
	cim bit2, [0x6f]
	jsr F_a28e
	rts


F_a257:
	jsr delay_10k
	ldx 0x0221
.L_a25d:
	gpio_test BUSY
	bne .L_a268
	dex
	bne .L_a25d
	lda B, 0x0
	rts
.L_a268:
	lda B, 0xff
	rts


F_a26b:
	ldx 0x0ea6
.L_a26e:
	dex
	bne .L_a26e
	oim bit5, [0x96]
	lda.ext A, [0x0096]
	sta A, [PERIPH3.PORTB]
	rts


F_a27b:
	cim bit7, [0x98]
	cim bit6, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	oim bit1, [0x71]
	jsr lcd_seg_0_7_on
	rts


F_a28e:
	oim bit7, [0x98]
	tim bit3, [0x71]
	bne .L_a299
	oim bit6, [0x98]
.L_a299:
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	cim bit1, [0x71]
	jsr lcd_seg_0_7_off
	rts


F_a2a6:
	cim bit6, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	rts


F_a2b0:
	oim bit6, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
	rts


cmi:
	cim bit6, [TCSR3]
	cim bit2, [TCSR1]
	cim bit7, [TCSR3]
	cli
	tim bit1, [0x6f]
	beq .L_a2d3
	jsr F_97d0
	oim bit2, [TCSR1]
	oim bit6, [TCSR3]
	rti
.L_a2d3:
	tim bit3, [0x71]
	beq .L_a2db
	jsr F_a2df
.L_a2db:
	oim bit2, [TCSR1]
	rti


F_a2df:
	dec [0x0079]
	bne .L_a304
	clr [TCSR3]
	cim bit3, [0x71]
	gpio_on ALARM 
	tim bit1, [0x71]
	bne .L_a303
	jsr F_a2b0
	tim bit2, [0x71]
	bne .L_a303
	cim bit3, [0x98]
	lda.ext A, [0x0098]
	sta A, [PERIPH2.PORTA]
.L_a303:
	rts
.L_a304:
	oim bit6, [TCSR3]
	rts


F_a308:
	cim bit3, [TCSR1]
	jsr lcd_seg_0_7_off
	gpio_off BUSY_IND
	jsr F_a28e
	jsr F_a98b
.L_a317:
	tim bit7, [SCI_TRCSR]
	beq .L_a321
	jsr F_ab00
	bra .L_a317
.L_a321:
	tim bit7, [0x69]
	beq .L_a317
	cim bit7, [0x6b]
.L_a329:
	jsr F_98fc
	jsr lcd_seg_5_5_on
	jsr lcd_c0_C
	jsr lcd_c1_0
	jsr lcd_c2_0
	lda A, 0x10
	sta.ext A, [0x0040]
	clr [0x0078]
.L_a340:
	tim bit3, [0x6b]
	bne .L_a360
	tim bit7, [0x6b]
	bne .L_a36b
	tim bit1, [0x6c]
	bne .L_a382
	tst [0x006a]
	bne .L_a38a
	tim bit0, [0x6b]
	bne .L_a38a
	tim bit1, [0x6b]
	bne .L_a38a
	bra .L_a340
.L_a360:
	cim bit3, [0x6b]
	jsr F_98fc
	jsr F_a9ab
	bra .L_a329
.L_a36b:
	cim bit7, [0x6b]
	jsr F_8243
	lda A, 0x10
	cmp.ext A, [0x0040]
	beq .L_a37d
	jsr F_abc1
	bra .L_a340
.L_a37d:
	jsr F_a435
	bra .L_a340
.L_a382:
	cim bit1, [0x6c]
	jsr F_a38f
	bra .L_a340
.L_a38a:
	jsr F_a3b7
	bra .L_a340


F_a38f:
	jsr F_98fc
	inc [0x0040]
	lda A, 0x11
	cmp.ext A, [0x0040]
	beq .L_a3a8
	lda A, 0x10
	cmp.ext A, [0x0040]
	beq .L_a3b0
	jsr F_bb57
	bra .L_a3b6
.L_a3a8:
	clr [0x0040]
	jsr F_bb57
	bra .L_a3b6
.L_a3b0:
	jsr lcd_c1_0
	jsr lcd_c2_0
.L_a3b6:
	rts


F_a3b7:
	inc [0x0078]
	lda.ext A, [0x0078]
	cmp A, 0x1
	beq .L_a3ca
	cmp A, 0x2
	beq .L_a3ea
	lda A, 0x1
	sta.ext A, [0x0078]
.L_a3ca:
	tim bit0, [0x6a]
	bne .L_a3dc
	tim bit1, [0x6a]
	bne .L_a3dc
	clr [0x0078]
	jsr F_9942
	bra .L_a42b
.L_a3dc:
	jsr F_98fc
	jsr F_b8bd
	sta.ext A, [0x0041]
	jsr lcd_c2_off
	bra .L_a42b
.L_a3ea:
	tst [0x0041]
	beq .L_a3fe
	tim bit1, [0x6b]
	bne .L_a409
	tim bit0, [0x6b]
	bne .L_a409
	tim bit7, [0x6a]
	bne .L_a409
.L_a3fe:
	jsr F_98fc
	jsr F_b92c
	clr [0x0078]
	bra .L_a411
.L_a409:
	jsr F_9942
	dec [0x0078]
	bra .L_a42b
.L_a411:
	tst [0x0041]
	bne .L_a426
	tst A
	bne .L_a420
	lda B, 0x10
	sta.ext B, [0x0040]
	bra .L_a42b
.L_a420:
	dec A
	sta.ext A, [0x0040]
	bra .L_a42b
.L_a426:
	add A, 0x9
	sta.ext A, [0x0040]
.L_a42b:
	clr [0x006a]
	cim bit0, [0x6b]
	cim bit1, [0x6b]
	rts


F_a435:
	jsr F_98fc
	jsr F_a47b
	jsr F_a522
	jsr F_a59c
	jsr F_a628
	tst [0x005a]
	bne .L_a450
	ldd.ext [0x0060]
	bne .L_a450
	bra .L_a463
.L_a450:
	jsr F_a6e6
	tst [0x005a]
	beq .L_a45b
	jsr F_a751
.L_a45b:
	ldd.ext [0x0060]
	beq .L_a463
	jsr F_a7b5
.L_a463:
	jsr F_a819
	jsr standby_screen
	lda A, 0x10
	sta.ext A, [0x0040]
	jsr init_lcd
	jsr lcd_c0_C
	jsr lcd_c1_0
	jsr lcd_c2_0
	rts


F_a47b:
	jsr init_lcd
	jsr lcd_seg_3_7_on
	lda.ext A, [0x005b]
	and A, 0xf
	sta.ext A, [0x005b]
	cmp A, 0x0
	bne .L_a49e
	jsr lcd_c0_off
	jsr lcd_c1_off
	jsr lcd_c2_off
	jsr lcd_c3_off
	jsr lcd_nOFF
	bra .L_a4a4
.L_a49e:
	jsr lcd_nSEC
	jsr F_bcbc
.L_a4a4:
	tim bit4, [0x6b]
	bne .L_a4b5
	tim bit1, [0x6c]
	bne .L_a4b5
	tim bit7, [0x6b]
	bne .L_a51b
	bra .L_a4a4
.L_a4b5:
	tim bit4, [0x6b]
	bne .L_a4c6
.L_a4ba:
	tim bit1, [0x6c]
	bne .L_a4e0
.L_a4bf:
	tim bit5, [0x6b]
	bne .L_a50c
	bra .L_a4b5
.L_a4c6:
	cim bit4, [0x6b]
	jsr F_98fc
	clr [0x005b]
	jsr lcd_c0_off
	jsr lcd_c1_off
	jsr lcd_c2_off
	jsr lcd_c3_off
	jsr lcd_nOFF
	bra .L_a4ba
.L_a4e0:
	cim bit1, [0x6c]
	jsr F_98fc
	inc [0x005b]
	aim 0xf, [0x5b]
	lda.ext A, [0x005b]
	cmp A, 0x0
	bne .L_a504
	jsr lcd_c0_off
	jsr lcd_c1_off
	jsr lcd_c2_off
	jsr lcd_c3_off
	jsr lcd_nOFF
	bra .L_a4bf
.L_a504:
	jsr lcd_nSEC
	jsr F_bcbc
	bra .L_a4bf
.L_a50c:
	cim bit5, [0x6b]
	lda A, 0x3f
	sta.ext A, [0x0087]
	lda.ext A, [0x005b]
	clr B
	jsr F_8348
.L_a51b:
	cim bit7, [0x6b]
	jsr F_98fc
	rts


F_a522:
	jsr init_lcd
	jsr lcd_c0_t
	jsr lcd_c1_C
	jsr lcd_c2_5
	tim bit3, [0x64]
	beq .L_a538
	jsr lcd_nON
	bra .L_a53b
.L_a538:
	jsr lcd_nOFF
.L_a53b:
	tim bit1, [0x6c]
	bne .L_a547
	tim bit7, [0x6b]
	bne .L_a579
	bra .L_a53b
.L_a547:
	tim bit1, [0x6c]
	bne .L_a553
.L_a54c:
	tim bit5, [0x6b]
	bne .L_a56b
	bra .L_a547
.L_a553:
	cim bit1, [0x6c]
	jsr F_98fc
	eim 0x8, [0x64]
	tim bit3, [0x64]
	beq .L_a566
	jsr lcd_nON
	bra .L_a54c
.L_a566:
	jsr lcd_nOFF
	bra .L_a54c
.L_a56b:
	cim bit5, [0x6b]
	lda A, 0x3e
	sta.ext A, [0x0087]
	ldd.ext [0x0064]
	jsr F_8348
.L_a579:
	cim bit7, [0x6b]
	jsr F_98fc
	tim bit3, [0x64]
	bne .L_a59b
	lda A, 0x20
	sta.ext A, [0x0087]
	lda A, 0x10
	sta.ext A, [0x007f]
.L_a58e:
	clr A
	clr B
	inc [0x0087]
	jsr F_8348
	dec [0x007f]
	bne .L_a58e
.L_a59b:
	rts


F_a59c:
	jsr init_lcd
	jsr lcd_seg_4_7_on
	jsr lcd_c0_n
	jsr lcd_c1_n
	aim 0xf, [0x5a]
	jsr F_bd75
.L_a5ae:
	tim bit4, [0x6b]
	bne .L_a5bf
	tim bit1, [0x6c]
	bne .L_a5bf
	tim bit7, [0x6b]
	bne .L_a5fd
	bra .L_a5ae
.L_a5bf:
	tim bit4, [0x6b]
	bne .L_a5d0
.L_a5c4:
	tim bit1, [0x6c]
	bne .L_a5de
.L_a5c9:
	tim bit5, [0x6b]
	bne .L_a5ef
	bra .L_a5bf
.L_a5d0:
	cim bit4, [0x6b]
	jsr F_98fc
	clr [0x005a]
	jsr F_bd75
	bra .L_a5c4
.L_a5de:
	cim bit1, [0x6c]
	jsr F_98fc
	inc [0x005a]
	aim 0xf, [0x5a]
	jsr F_bd75
	bra .L_a5c9
.L_a5ef:
	cim bit5, [0x6b]
	lda A, 0x3d
	sta.ext A, [0x0087]
	ldd.ext [0x0059]
	jsr F_8348
.L_a5fd:
	cim bit7, [0x6b]
	jsr F_98fc
	tst [0x005a]
	bne .L_a627
	clr [0x0062]
	clr [0x0063]
	lda A, 0x33
	sta.ext A, [0x0087]
	ldd.ext [0x0062]
	jsr F_8348
	cim bit0, [0x64]
	lda A, 0x3e
	sta.ext A, [0x0087]
	ldd.ext [0x0064]
	jsr F_8348
.L_a627:
	rts


F_a628:
	jsr init_lcd
	jsr lcd_seg_1_7_on
	ldd.ext [0x0060]
	ldx 0x0010
	clr [0x0088]
.L_a637:
	asld
	bcc .L_a63d
	inc [0x0088]
.L_a63d:
	dex
	bne .L_a637
	lda.ext A, [0x0088]
	cmp A, 0x0
	beq .L_a651
	cmp A, 0x1
	beq .L_a664
	clr [0x0060]
	clr [0x0061]
.L_a651:
	jsr lcd_c1_0
	jsr lcd_c2_0
	lda A, 0x34
	sta.ext A, [0x0087]
	ldd.ext [0x0060]
	jsr F_8348
	bra .L_a67b
.L_a664:
	clr [0x0040]
	ldd.ext [0x0060]
	ldx 0x0010
.L_a66d:
	asld
	bcs .L_a678
	inc [0x0040]
	dex
	bne .L_a66d
	bra .L_a651
.L_a678:
	jsr F_bb57
.L_a67b:
	clr [0x007a]
.L_a67e:
	tst [0x006a]
	bne .L_a694
	tim bit0, [0x6b]
	bne .L_a694
	tim bit1, [0x6b]
	bne .L_a694
	tim bit7, [0x6b]
	bne .L_a6cc
	bra .L_a67e
.L_a694:
	tst [0x006a]
	bne .L_a6aa
	tim bit0, [0x6b]
	bne .L_a6aa
	tim bit1, [0x6b]
	bne .L_a6aa
.L_a6a3:
	tim bit5, [0x6b]
	bne .L_a6af
	bra .L_a694
.L_a6aa:
	jsr F_a3b7
	bra .L_a6a3
.L_a6af:
	cim bit5, [0x6b]
	clr [0x0060]
	clr [0x0061]
	lda.ext A, [0x0040]
	ldx 0x0060
	jsr set_bit_double
	lda A, 0x34
	sta.ext A, [0x0087]
	ldd.ext [0x0060]
	jsr F_8348
.L_a6cc:
	cim bit7, [0x6b]
	jsr F_98fc
	ldd.ext [0x0060]
	bne .L_a6e5
	cim bit7, [standby_something]
	lda A, 0x3e
	sta.ext A, [0x0087]
	ldd.ext [0x0064]
	jsr F_8348
.L_a6e5:
	rts


F_a6e6:
	jsr init_lcd
	jsr lcd_seg_1_0_on
	jsr lcd_seg_4_7_on
	jsr lcd_c0_n
	jsr lcd_nSEC
	aim 0xf, [0x59]
	jsr F_be3d
.L_a6fb:
	tim bit4, [0x6b]
	bne .L_a70c
	tim bit1, [0x6c]
	bne .L_a70c
	tim bit7, [0x6b]
	bne .L_a74a
	bra .L_a6fb
.L_a70c:
	tim bit4, [0x6b]
	bne .L_a71d
.L_a711:
	tim bit1, [0x6c]
	bne .L_a72b
.L_a716:
	tim bit5, [0x6b]
	bne .L_a73c
	bra .L_a70c
.L_a71d:
	cim bit4, [0x6b]
	jsr F_98fc
	clr [0x0059]
	jsr F_be3d
	bra .L_a711
.L_a72b:
	cim bit1, [0x6c]
	jsr F_98fc
	inc [0x0059]
	aim 0xf, [0x59]
	jsr F_be3d
	bra .L_a716
.L_a73c:
	cim bit5, [0x6b]
	lda A, 0x3d
	sta.ext A, [0x0087]
	ldd.ext [0x0059]
	jsr F_8348
.L_a74a:
	cim bit7, [0x6b]
	jsr F_98fc
	rts


F_a751:
	jsr init_lcd
	jsr lcd_c0_C
	jsr lcd_c1_h
	jsr lcd_c2_n
	jsr lcd_c3_G
	jsr lcd_seg_4_7_on
	tim bit0, [0x64]
	beq .L_a76d
	jsr lcd_nON
	bra .L_a770
.L_a76d:
	jsr lcd_nOFF
.L_a770:
	tim bit1, [0x6c]
	bne .L_a77c
	tim bit7, [0x6b]
	bne .L_a7ae
	bra .L_a770
.L_a77c:
	tim bit1, [0x6c]
	bne .L_a788
.L_a781:
	tim bit5, [0x6b]
	bne .L_a7a0
	bra .L_a77c
.L_a788:
	cim bit1, [0x6c]
	jsr F_98fc
	eim 0x1, [0x64]
	tim bit0, [0x64]
	beq .L_a79b
	jsr lcd_nON
	bra .L_a781
.L_a79b:
	jsr lcd_nOFF
	bra .L_a781
.L_a7a0:
	cim bit5, [0x6b]
	lda A, 0x3e
	sta.ext A, [0x0087]
	ldd.ext [0x0064]
	jsr F_8348
.L_a7ae:
	cim bit7, [0x6b]
	jsr F_98fc
	rts


F_a7b5:
	jsr init_lcd
	jsr lcd_c0_C
	jsr lcd_c1_h
	jsr lcd_c2_n
	jsr lcd_c3_G
	jsr lcd_seg_1_7_on
	tim bit7, [standby_something]
	beq .L_a7d1
	jsr lcd_nON
	bra .L_a7d4
.L_a7d1:
	jsr lcd_nOFF
.L_a7d4:
	tim bit1, [0x6c]
	bne .L_a7e0
	tim bit7, [0x6b]
	bne .L_a812
	bra .L_a7d4
.L_a7e0:
	tim bit1, [0x6c]
	bne .L_a7ec
.L_a7e5:
	tim bit5, [0x6b]
	bne .L_a804
	bra .L_a7e0
.L_a7ec:
	cim bit1, [0x6c]
	jsr F_98fc
	eim 0x80, [standby_something]
	tim bit7, [standby_something]
	beq .L_a7ff
	jsr lcd_nON
	bra .L_a7e5
.L_a7ff:
	jsr lcd_nOFF
	bra .L_a7e5
.L_a804:
	cim bit5, [0x6b]
	lda A, 0x3e
	sta.ext A, [0x0087]
	ldd.ext [0x0064]
	jsr F_8348
.L_a812:
	cim bit7, [0x6b]
	jsr F_98fc
	rts


F_a819:
	jsr init_lcd
	jsr lcd_c0_b
	jsr lcd_c1_E
	jsr lcd_c2_E
	jsr lcd_c3_P
	tim bit6, [standby_something]
	beq .L_a832
	jsr lcd_nON
	bra .L_a835
.L_a832:
	jsr lcd_nOFF
.L_a835:
	tim bit1, [0x6c]
	bne .L_a841
	tim bit7, [0x6b]
	bne .L_a873
	bra .L_a835
.L_a841:
	tim bit1, [0x6c]
	bne .L_a84d
.L_a846:
	tim bit5, [0x6b]
	bne .L_a865
	bra .L_a841
.L_a84d:
	cim bit1, [0x6c]
	jsr F_98fc
	eim 0x40, [standby_something]
	tim bit6, [standby_something]
	beq .L_a860
	jsr lcd_nON
	bra .L_a846
.L_a860:
	jsr lcd_nOFF
	bra .L_a846
.L_a865:
	cim bit5, [0x6b]
	lda A, 0x3e
	sta.ext A, [0x0087]
	ldd.ext [0x0064]
	jsr F_8348
.L_a873:
	cim bit7, [0x6b]
	jsr F_98fc
	rts


standby_screen: ;
	jsr init_lcd
	jsr lcd_c0_5
	jsr lcd_c1_t
	lda.ext A, [standby_something]
	and A, 0x30
	cmp A, 0x0
	beq .set140
	cmp A, 0x10
	beq .set280
	cmp A, 0x20
	beq .set500
	bra .set900
.set140:
	jsr lcd_c4_1
	jsr lcd_c5_4
	jsr lcd_c6_0
	bra .cont
.set280:
	jsr lcd_c4_2
	jsr lcd_c5_8
	jsr lcd_c6_0
	bra .cont
.set500:
	jsr lcd_c4_5
	jsr lcd_c5_0
	jsr lcd_c6_0
	bra .cont
.set900:
	jsr lcd_c4_9
	jsr lcd_c5_0
	jsr lcd_c6_0
.cont:
	tim bit1, [0x6c]
	bne .L_a8cc
	tim bit7, [0x6b]
	bne .L_a93e
	bra .cont

.L_a8cc:
	tim bit1, [0x6c]
	bne .L_a8d8
.L_a8d1:
	tim bit5, [0x6b]
	bne .L_a930
	bra .L_a8cc
.L_a8d8:
	cim bit1, [0x6c]
	jsr F_98fc
	lda.ext A, [standby_something]
	add A, 0x10
	and A, 0x30
	cim bit5, [standby_something]
	cim bit4, [standby_something]
	ora.ext A, [standby_something]
	sta.ext A, [standby_something]
	lda.ext A, [standby_something]
	and A, 0x30
	cmp A, 0x0
	beq .L_a904
	cmp A, 0x10
	beq .L_a90f
	cmp A, 0x20
	beq .L_a91a
	bra .L_a925
.L_a904:
	jsr lcd_c4_1
	jsr lcd_c5_4
	jsr lcd_c6_0
	bra .L_a8d1
.L_a90f:
	jsr lcd_c4_2
	jsr lcd_c5_8
	jsr lcd_c6_0
	bra .L_a8d1
.L_a91a:
	jsr lcd_c4_5
	jsr lcd_c5_0
	jsr lcd_c6_0
	bra .L_a8d1
.L_a925:
	jsr lcd_c4_9
	jsr lcd_c5_0
	jsr lcd_c6_0
	bra .L_a8d1
.L_a930:
	cim bit5, [0x6b]
	lda A, 0x3e
	sta.ext A, [0x0087]
	ldd.ext [0x0064]
	jsr F_8348
.L_a93e:
	cim bit7, [0x6b]
	jsr F_98fc
	rts


F_a945:
	inc A
	sta.ext A, [0x0088]
	ldd.ext [0x005e]
.L_a94c:
	asld
	dec [0x0088]
	bne .L_a94c
	rts


F_a953:
	inc A
	sta.ext A, [0x0088]
	ldd.ext [0x005c]
.L_a95a:
	asld
	dec [0x0088]
	bne .L_a95a
	rts


F_a961:
	inc A
	sta.ext A, [0x0088]
	ldd.ext [0x0062]
.L_a968:
	asld
	dec [0x0088]
	bne .L_a968
	rts


F_a96f:
	inc A
	sta.ext A, [0x0088]
	ldd.ext [0x0060]
.L_a976:
	asld
	dec [0x0088]
	bne .L_a976
	rts


F_a97d:
	inc A
	sta.ext A, [0x0088]
	ldd.ext [0x0049]
.L_a984:
	asld
	dec [0x0088]
	bne .L_a984
	rts


F_a98b:
    gpio_off TDATA
	clr [SCI_TRCSR]
	clr [SCI_RMCR]
	oim 0x7, [SCI_RMCR]
	jsr delay_100k
	oim bit3, [SCI_TRCSR]
	oim bit0, [SCI_TRCSR]
	oim bit1, [SCI_TRCSR]
	rts


delay_100k:
	ldx 100*1000/4
.loop:
	dex
	bne .loop
	rts


F_a9ab:
	jsr lcd_c0_off
	jsr lcd_c1_off
	jsr lcd_c2_off
	jsr lcd_c3_P
	jsr lcd_c4_unk
	jsr lcd_c5_deg
	jsr lcd_c6_9
	lda A, 0x4
	sta.ext A, [0x0056]
	oim bit3, [0x70]
	oim bit6, [0x71]
	oim bit0, [SCI_TRCSR]
	lda.ext A, [SCI_TRCSR]
	lda.ext A, [SCI_RDR]
.L_a9d4:
	tim bit4, [0x6b]
	bne .L_a9e0
	tim bit7, [0x6b]
	beq .L_a9d4
	bra .L_a9e6
.L_a9e0:
	cim bit6, [0x71]
	jmp .L_aaed
.L_a9e6:
	jsr F_98fc
	cim bit6, [0x71]
	jsr lcd_c3_off
	jsr lcd_c4_off
	jsr lcd_c5_off
	jsr lcd_c6_dash
	lda A, 0xff
	sta.ext A, [0x0055]
	cim bit4, [0x71]
	lda A, 0x4
	sta.ext A, [0x0056]
	oim bit3, [0x70]
	oim bit5, [0x71]
	cim bit7, [0x6d]
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	beq .L_aa19
	lda A, 0xff
	bra .L_aa1b
.L_aa19:
	lda A, 0x0
.L_aa1b:
	tim bit4, [0x71]
	bne .L_aa27
	tim bit5, [SCI_TRCSR]
	beq .L_aa1b
	bra .L_aa2a
.L_aa27:
	jmp .L_aab3
.L_aa2a:
	sta.ext A, [SCI_TDR]
.L_aa2d:
	tim bit4, [0x71]
	bne .L_aa39
	tim bit7, [SCI_TRCSR]
	beq .L_aa2d
	bra .L_aa3c
.L_aa39:
	jmp .L_aab3
.L_aa3c:
	lda.ext A, [SCI_RDR]
	cmp A, 0x0
	beq .L_aa46
	jmp .L_aab3
.L_aa46:
	lda A, 0xff
	sta.ext A, [0x0087]
.L_aa4b:
	inc [0x0087]
	jsr F_8296
.L_aa51:
	tim bit4, [0x71]
	bne .L_aab3
	tim bit5, [SCI_TRCSR]
	beq .L_aa51
	sta.ext A, [SCI_TDR]
.L_aa5e:
	tim bit4, [0x71]
	bne .L_aab3
	tim bit5, [SCI_TRCSR]
	beq .L_aa5e
	sta.ext B, [SCI_TDR]
	lda.ext A, [0x0087]
	and A, 0x3f
	cmp A, 0x3f
	bne .L_aa4b
	lda A, 0xff
	sta.ext A, [0x0087]
.L_aa79:
	inc [0x0087]
	jsr F_8296
	std.ext [mul16_res]
.L_aa82:
	tim bit4, [0x71]
	bne .L_aab3
	tim bit7, [SCI_TRCSR]
	beq .L_aa82
	lda.ext A, [SCI_RDR]
.L_aa8f:
	tim bit4, [0x71]
	bne .L_aab3
	tim bit7, [SCI_TRCSR]
	beq .L_aa8f
	lda.ext B, [SCI_RDR]
	xgdx
	cpx.ext [mul16_res]
	beq .L_aaa5
	oim bit7, [0x6d]
.L_aaa5:
	lda.ext A, [0x0087]
	and A, 0x3f
	cmp A, 0x3f
	bne .L_aa79
	tim bit7, [0x6d]
	beq .L_aaca
.L_aab3:
	cim bit5, [0x71]
	jsr lcd_c2_E
	jsr lcd_c3_r
	jsr lcd_c4_r
	jsr lcd_c5_o
	jsr lcd_c6_r
	jsr F_9942
	bra .L_aae8
.L_aaca:
	cim bit5, [0x71]
	jsr lcd_c3_P
	jsr lcd_c4_unk
	jsr lcd_c5_deg
	jsr lcd_c6_9
	jsr F_98fc
	jsr delay_100k
	jsr F_98fc
	jsr delay_100k
	jsr F_98fc
.L_aae8:
	tim bit4, [0x6b]
	beq .L_aae8
.L_aaed:
	cim bit4, [0x6b]
	jsr lcd_c2_off
	jsr lcd_c3_off
	jsr lcd_c4_off
	jsr lcd_c5_off
	jsr lcd_c6_off
	rts


F_ab00:
	lda.ext A, [SCI_RDR]
	sta.ext A, [mul16_res]
	cmp A, 0x33
	bne .L_ab0c
	bra .L_ab38
.L_ab0c:
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	beq .L_ab17
	lda A, 0xff
	bra .L_ab19
.L_ab17:
	lda A, 0x0
.L_ab19:
	cmp.ext A, [mul16_res]
	bne .L_ab22
	lda A, 0x0
	bra .L_ab24
.L_ab22:
	lda A, 0xff
.L_ab24:
	tim bit5, [SCI_TRCSR]
	beq .L_ab24
	sta.ext A, [SCI_TDR]
	cmp A, 0x0
	beq .L_ab31
	rts
.L_ab31:
	jsr F_ab77
	jsr F_ab9c
	rts
.L_ab38:
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	beq .L_ab43
	lda A, 0xff
	bra .L_ab45
.L_ab43:
	lda A, 0x0
.L_ab45:
	tim bit5, [SCI_TRCSR]
	beq .L_ab45
	sta.ext A, [SCI_TDR]
.L_ab4d:
	tim bit7, [SCI_TRCSR]
	beq .L_ab4d
	lda.ext A, [SCI_RDR]
	cmp A, 0xf
	beq .L_ab62
	cmp A, 0xf0
	beq .L_ab6a
	cmp A, 0xaa
	beq .L_ab6f
	rts
.L_ab62:
	jsr F_ab9c
	jsr F_ab9c
	bra .L_ab4d
.L_ab6a:
	jsr F_ab9c
	bra .L_ab4d
.L_ab6f:
	jsr F_ab77
	jsr F_ab9c
	bra .L_ab4d


F_ab77:
	lda A, 0xff
	sta.ext A, [0x0087]
.L_ab7c:
	inc [0x0087]
.L_ab7f:
	tim bit7, [SCI_TRCSR]
	beq .L_ab7f
	lda.ext A, [SCI_RDR]
.L_ab87:
	tim bit7, [SCI_TRCSR]
	beq .L_ab87
	lda.ext B, [SCI_RDR]
	jsr F_8348
	lda.ext A, [0x0087]
	and A, 0x3f
	cmp A, 0x3f
	bne .L_ab7c
	rts


F_ab9c:
	lda A, 0xff
	sta.ext A, [0x0087]
.L_aba1:
	inc [0x0087]
	jsr F_8296
.L_aba7:
	tim bit5, [SCI_TRCSR]
	beq .L_aba7
	sta.ext A, [SCI_TDR]
.L_abaf:
	tim bit5, [SCI_TRCSR]
	beq .L_abaf
	sta.ext B, [SCI_TDR]
	lda.ext A, [0x0087]
	and A, 0x3f
	cmp A, 0x3f
	bne .L_aba1
	rts


F_abc1:
	jsr F_98fc
	jsr F_ac72
	jsr F_acc9
	tim bit3, [0x64]
	beq .L_ac35
	lda.ext A, [0x0040]
	jsr F_a953
	bcc .L_abd9
	bra .L_ac00
.L_abd9:
	lda.ext A, [0x0040]
	add A, 0x21
	sta.ext A, [0x0087]
	jsr F_8296
	sta.ext A, [0x0057]
	sta.ext B, [0x0058]
	clr [0x0057]
	lda.ext A, [0x0040]
	add A, 0x21
	sta.ext A, [0x0087]
	lda.ext A, [0x0057]
	lda.ext B, [0x0058]
	jsr F_8348
	bra .L_ac03
.L_ac00:
	jsr F_ad21
.L_ac03:
	lda.ext A, [0x0040]
	jsr F_a945
	bcc .L_ac10
	jsr F_ad6c
	bra .L_ac35
.L_ac10:
	lda.ext A, [0x0040]
	add A, 0x21
	sta.ext A, [0x0087]
	jsr F_8296
	sta.ext A, [0x0058]
	sta.ext B, [0x0057]
	clr [0x0057]
	lda.ext A, [0x0040]
	add A, 0x21
	sta.ext A, [0x0087]
	lda.ext A, [0x0058]
	lda.ext B, [0x0057]
	jsr F_8348
.L_ac35:
	tst [0x005a]
	beq .L_ac5d
	lda.ext A, [0x0040]
	jsr F_a953
	bcc .L_ac44
	bra .L_ac5a
.L_ac44:
	lda.ext A, [0x0040]
	ldx 0x0062
	jsr clear_bit_double
	lda A, 0x33
	sta.ext A, [0x0087]
	ldd.ext [0x0062]
	jsr F_8348
	bra .L_ac5d
.L_ac5a:
	jsr F_adb7
.L_ac5d:
	lda.ext A, [0x0040]
	jsr F_a953
	bcc .L_ac68
	jsr F_ae24
.L_ac68:
	jsr init_lcd
	jsr lcd_c0_C
	jsr F_bb57
	rts


F_ac72:
	jsr init_lcd
	cim bit1, [0x6d]
	lda.ext A, [0x0040]
	inc A
	sta.ext A, [0x0087]
	jsr F_8296
	std.ext [mul16_a]
	tim bit7, [mul16_a]
	beq .L_ac92
	oim bit7, [0x43]
	cim bit7, [mul16_a]
	bra .L_ac95
.L_ac92:
	cim bit7, [0x43]
.L_ac95:
	jsr lcd_seg_0_7_on
	jsr lcd_seg_1_0_on
	jsr F_b2a4
	lda A, 0x31
	sta.ext A, [0x0087]
	ldd.ext [0x005c]
	jsr F_8348
.L_aca9:
	tim bit4, [0x6b]
	bne .L_acbc
	tim bit7, [0x6b]
	bne .L_acb5
	bra .L_aca9
.L_acb5:
	cim bit7, [0x6b]
	jsr F_98fc
	rts
.L_acbc:
	lda.ext A, [0x0040]
	ldx 0x005c
	jsr clear_bit_double
	jsr F_b0aa
	rts


F_acc9:
	jsr init_lcd
	oim bit1, [0x6d]
	lda.ext A, [0x0040]
	add A, 0x11
	sta.ext A, [0x0087]
	jsr F_8296
	std.ext [mul16_a]
	tim bit7, [mul16_a]
	beq .L_acea
	oim bit7, [0x43]
	cim bit7, [mul16_a]
	bra .L_aced
.L_acea:
	cim bit7, [0x43]
.L_aced:
	jsr lcd_seg_1_0_on
	jsr lcd_seg_3_7_on
	jsr F_b2a4
	lda A, 0x32
	sta.ext A, [0x0087]
	ldd.ext [0x005e]
	jsr F_8348
.L_ad01:
	tim bit4, [0x6b]
	bne .L_ad14
	tim bit7, [0x6b]
	bne .L_ad0d
	bra .L_ad01
.L_ad0d:
	cim bit7, [0x6b]
	jsr F_98fc
	rts
.L_ad14:
	lda.ext A, [0x0040]
	ldx 0x005e
	jsr clear_bit_double
	jsr F_b0aa
	rts


F_ad21:
	jsr init_lcd
	cim bit1, [0x6d]
	lda.ext A, [0x0040]
	add A, 0x21
	sta.ext A, [0x0087]
	jsr F_8296
	sta.ext A, [0x0057]
	sta.ext B, [0x0058]
	jsr lcd_seg_1_0_on
	jsr lcd_seg_0_7_on
	jsr lcd_nTCS
	jsr F_af72
	lda.ext A, [0x0040]
	add A, 0x21
	sta.ext A, [0x0087]
	lda.ext A, [0x0057]
	lda.ext B, [0x0058]
	jsr F_8348
.L_ad55:
	tim bit4, [0x6b]
	bne .L_ad68
	tim bit7, [0x6b]
	bne .L_ad61
	bra .L_ad55
.L_ad61:
	cim bit7, [0x6b]
	jsr F_98fc
	rts
.L_ad68:
	jsr F_ae97
	rts


F_ad6c:
	jsr init_lcd
	oim bit1, [0x6d]
	lda.ext A, [0x0040]
	add A, 0x21
	sta.ext A, [0x0087]
	jsr F_8296
	sta.ext B, [0x0057]
	sta.ext A, [0x0058]
	jsr lcd_seg_1_0_on
	jsr lcd_seg_3_7_on
	jsr lcd_nTCS
	jsr F_af72
	lda.ext A, [0x0040]
	add A, 0x21
	sta.ext A, [0x0087]
	lda.ext A, [0x0058]
	lda.ext B, [0x0057]
	jsr F_8348
.L_ada0:
	tim bit4, [0x6b]
	bne .L_adb3
	tim bit7, [0x6b]
	bne .L_adac
	bra .L_ada0
.L_adac:
	cim bit7, [0x6b]
	jsr F_98fc
	rts
.L_adb3:
	jsr F_ae97
	rts


F_adb7:
	jsr init_lcd
	jsr lcd_seg_4_7_on
	lda.ext A, [0x0040]
	jsr F_a961
	bcc .L_adca
	jsr lcd_nON
	bra .L_adcd
.L_adca:
	jsr lcd_nOFF
.L_adcd:
	tim bit1, [0x6c]
	bne .L_add9
	tim bit7, [0x6b]
	bne .L_ae1d
	bra .L_adcd
.L_add9:
	tim bit1, [0x6c]
	bne .L_ade5
.L_adde:
	tim bit5, [0x6b]
	bne .L_ae0f
	bra .L_add9
.L_ade5:
	cim bit1, [0x6c]
	jsr F_98fc
	lda.ext A, [0x0040]
	jsr F_a961
	bcc .L_ae01
	jsr lcd_nOFF
	lda.ext A, [0x0040]
	ldx 0x0062
	jsr clear_bit_double
	bra .L_adde
.L_ae01:
	jsr lcd_nON
	lda.ext A, [0x0040]
	ldx 0x0062
	jsr set_bit_double
	bra .L_adde
.L_ae0f:
	cim bit5, [0x6b]
	lda A, 0x33
	sta.ext A, [0x0087]
	ldd.ext [0x0062]
	jsr F_8348
.L_ae1d:
	cim bit7, [0x6b]
	jsr F_98fc
	rts


F_ae24:
	jsr init_lcd
	jsr lcd_seg_0_7_on
	jsr lcd_c0_C
	jsr lcd_c1_5
	lda.ext A, [0x0040]
	jsr F_a97d
	bcc .L_ae3d
	jsr lcd_nON
	bra .L_ae40
.L_ae3d:
	jsr lcd_nOFF
.L_ae40:
	tim bit1, [0x6c]
	bne .L_ae4c
	tim bit7, [0x6b]
	bne .L_ae90
	bra .L_ae40
.L_ae4c:
	tim bit1, [0x6c]
	bne .L_ae58
.L_ae51:
	tim bit5, [0x6b]
	bne .L_ae82
	bra .L_ae4c
.L_ae58:
	cim bit1, [0x6c]
	jsr F_98fc
	lda.ext A, [0x0040]
	jsr F_a97d
	bcc .L_ae74
	jsr lcd_nOFF
	lda.ext A, [0x0040]
	ldx 0x0049
	jsr clear_bit_double
	bra .L_ae51
.L_ae74:
	jsr lcd_nON
	lda.ext A, [0x0040]
	ldx 0x0049
	jsr set_bit_double
	bra .L_ae51
.L_ae82:
	cim bit5, [0x6b]
	lda A, 0x0
	sta.ext A, [0x0087]
	ldd.ext [0x0049]
	jsr F_8348
.L_ae90:
	cim bit7, [0x6b]
	jsr F_98fc
	rts


F_ae97:
.L_ae97:
	cim bit4, [0x6b]
	jsr F_98fc
	cim bit7, [0x6d]
	clr [mul16_res]
	clr [mul16_res+1]
	clr [mul16_res+2]
	clr [mul16_res+3]
	clr [0x0057]
	clr [0x007a]
	jsr lcd_c0_0
	jsr lcd_c1_0
	jsr lcd_c2_0
	jsr lcd_c3_0
.L_aebe:
	tim bit5, [0x6b]
	bne .L_aed9
	tim bit4, [0x6b]
	bne .L_ae97
	tst [0x006a]
	bne .L_af16
	tim bit0, [0x6b]
	bne .L_af16
	tim bit1, [0x6b]
	bne .L_af16
	bra .L_aebe
.L_aed9:
	cim bit5, [0x6b]
	lda.ext A, [0x007a]
	cmp A, 0x0
	beq .L_aef4
	cmp A, 0x3
	bcs .L_aeef
	jsr F_afb3
	tim bit7, [0x6d]
	beq .L_aef4
.L_aeef:
	jsr F_9942
	bra .L_aebe
.L_aef4:
	jsr F_98fc
	lda.ext A, [0x0040]
	add A, 0x21
	sta.ext A, [0x0087]
	tim bit1, [0x6d]
	bne .L_af0c
	lda.ext A, [0x0057]
	lda.ext B, [0x0058]
	bra .L_af12
.L_af0c:
	lda.ext A, [0x0058]
	lda.ext B, [0x0057]
.L_af12:
	jsr F_8348
	rts
.L_af16:
	lda.ext A, [0x007a]
	cmp A, 0x4
	bcc .L_aebe
	inc [0x007a]
	jsr F_98fc
	lda.ext A, [0x007a]
	cmp A, 0x1
	beq .L_af34
	cmp A, 0x2
	beq .L_af50
	cmp A, 0x3
	beq .L_af58
	bra .L_af60
.L_af34:
	tim bit2, [0x6a]
	bne .L_af48
	tim bit1, [0x6a]
	bne .L_af48
	tim bit0, [0x6a]
	bne .L_af48
	inc [0x007a]
	bra .L_af50
.L_af48:
	jsr F_b84e
	sta.ext A, [mul16_res]
	bra .L_af66
.L_af50:
	jsr F_b8bd
	sta.ext A, [mul16_res+1]
	bra .L_af66
.L_af58:
	jsr F_b92c
	sta.ext A, [mul16_res+2]
	bra .L_af66
.L_af60:
	jsr F_b99b
	sta.ext A, [mul16_res+3]
.L_af66:
	clr [0x006a]
	cim bit0, [0x6b]
	cim bit1, [0x6b]
	jmp .L_aebe


F_af72:
	ldx 0xb001
	clr A
.L_af76:
	cmp.ext A, [0x0057]
	beq .L_af89
	inc A
	inx
	inx
	cpx 0xb04d
	bne .L_af76
	ldx 0xb001
	clr [0x0057]
.L_af89:
	ldd [X]
	std.ext [mul16_res]
	lda.ext A, [mul16_res]
	lsr A
	lsr A
	lsr A
	lsr A
	jsr F_b617
	lda.ext A, [mul16_res]
	and A, 0xf
	jsr F_b668
	lda.ext A, [mul16_res+1]
	lsr A
	lsr A
	lsr A
	lsr A
	jsr F_b6b9
	lda.ext A, [mul16_res+1]
	and A, 0xf
	jsr F_b70a
	rts


F_afb3:
	cim bit7, [0x6d]
	lda.ext A, [mul16_res]
	asl A
	asl A
	asl A
	asl A
	add.ext A, [mul16_res+1]
	sta.ext A, [mul16_res]
	lda.ext A, [mul16_res+2]
	asl A
	asl A
	asl A
	asl A
	add.ext A, [mul16_res+3]
	sta.ext A, [mul16_res+1]
	clr [0x0057]
	ldx 0xb001
.L_afd6:
	ldd [X]
	xgdx
	cpx.ext [mul16_res]
	xgdx
	beq .L_b000
	inc [0x0057]
	inx
	inx
	cpx 0xb04d
	bne .L_afd6
	oim bit7, [0x6d]
	lda.ext A, [mul16_res]
	lsr [mul16_res]
	lsr [mul16_res]
	lsr [mul16_res]
	lsr [mul16_res]
	and A, 0xf
	sta.ext A, [mul16_res+1]
.L_b000:
	rts
D_b001:
	#d8 0x00
	#d8 0x00
	#d8 0x06
	#d8 0x70
	#d8 0x07
	#d8 0x19
	#d8 0x07
	#d8 0x44
	#d8 0x07
	#d8 0x70
	#d8 0x07
	#d8 0x97
	#d8 0x08
	#d8 0x25
	#d8 0x08
	#d8 0x54
	#d8 0x08
	#d8 0x85
	#d8 0x09
	#d8 0x15
	#d8 0x09
	#d8 0x48
	#d8 0x10
	#d8 0x00
	#d8 0x10
	#d8 0x35
	#d8 0x10
	#d8 0x72
	#d8 0x11
	#d8 0x09
	#d8 0x11
	#d8 0x48
	#d8 0x11
	#d8 0x88
	#d8 0x12
	#d8 0x30
	#d8 0x12
	#d8 0x73
	#d8 0x13
	#d8 0x18
	#d8 0x13
	#d8 0x65
	#d8 0x14
	#d8 0x13
	#d8 0x14
	#d8 0x62
	#d8 0x15
	#d8 0x14
	#d8 0x15
	#d8 0x67
	#d8 0x16
	#d8 0x22
	#d8 0x16
	#d8 0x79
	#d8 0x17
	#d8 0x38
	#d8 0x17
	#d8 0x99
	#d8 0x18
	#d8 0x62
	#d8 0x19
	#d8 0x28
	#d8 0x20
	#d8 0x35
	#d8 0x21
	#d8 0x07
	#d8 0x21
	#d8 0x81
	#d8 0x22
	#d8 0x57
	#d8 0x23
	#d8 0x36
	#d8 0x24
	#d8 0x18
	#d8 0x25
	#d8 0x03


init_lcd:
	clr [lcd_data+0]
	clr [lcd_data+1]
	clr [lcd_data+2]
	clr [lcd_data+3]
	clr [lcd_data+4]
	clr [lcd_data+5]
	clr [lcd_data+6]
	clr [lcd_data+7]
	clr B
	jsr lcd_wait
	lda A, 0x0
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x1
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x2
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x3
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x4
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x5
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x6
	jsr send_lcd_data
	jsr lcd_wait
	lda A, 0x7
	jsr send_lcd_data
	jsr lcd_seg_5_5_on
	rts


F_b0aa:
.L_b0aa:
	cim bit4, [0x6b]
	jsr F_98fc
	cim bit7, [0x6d]
	jsr lcd_c01_dashdash
	jsr lcd_dashes
	ldd 0xffff
	std.ext [mul16_a]
	clr [0x007a]
	clr [mul16_res]
	clr [mul16_res+1]
	clr [mul16_res+2]
	clr [mul16_res+3]
	clr [mul16_b]
	clr [mul16_b+1]
	clr [0x0051]
	clr [0x0052]
.L_b0da:
	tim bit5, [0x6b]
	beq .L_b0e2
	jmp .L_b158
.L_b0e2:
	tim bit4, [0x6b]
	bne .L_b0aa
	tst [0x006a]
	bne .L_b0f8
	tim bit0, [0x6b]
	bne .L_b0f8
	tim bit1, [0x6b]
	bne .L_b0f8
	bra .L_b0da
.L_b0f8:
	lda.ext A, [0x007a]
	cmp A, 0x8
	bcc .L_b0da
	jsr F_98fc
	inc [0x007a]
	lda.ext A, [0x007a]
	cmp A, 0x1
	beq .L_b126
	cmp A, 0x2
	beq .L_b12b
	cmp A, 0x3
	beq .L_b130
	cmp A, 0x4
	beq .L_b135
	cmp A, 0x5
	beq .L_b13a
	cmp A, 0x6
	beq .L_b13f
	cmp A, 0x7
	beq .L_b144
	bra .L_b149
.L_b126:
	jsr F_b1c7
	bra .L_b14c
.L_b12b:
	jsr F_b1f7
	bra .L_b14c
.L_b130:
	jsr F_b20e
	bra .L_b14c
.L_b135:
	jsr F_b225
	bra .L_b14c
.L_b13a:
	jsr F_b23c
	bra .L_b14c
.L_b13f:
	jsr F_b253
	bra .L_b14c
.L_b144:
	jsr F_b26a
	bra .L_b14c
.L_b149:
	jsr F_b281
.L_b14c:
	clr [0x006a]
	cim bit0, [0x6b]
	cim bit1, [0x6b]
	jmp .L_b0da
.L_b158:
	cim bit5, [0x6b]
	lda.ext A, [0x007a]
	cmp A, 0x0
	beq .L_b18c
	cmp A, 0x3
	bcs .L_b173
	tim bit7, [0x6d]
	bne .L_b173
	jsr F_b448
	tim bit7, [0x6d]
	beq .L_b179
.L_b173:
	jsr F_9942
	jmp .L_b0da
.L_b179:
	lda.ext A, [0x0040]
	tim bit1, [0x6d]
	bne .L_b186
	ldx 0x005c
	bra .L_b189
.L_b186:
	ldx 0x005e
.L_b189:
	jsr set_bit_double
.L_b18c:
	jsr F_98fc
	tim bit1, [0x6d]
	bne .L_b1ad
	lda.ext A, [0x0040]
	inc A
	sta.ext A, [0x0087]
	ldd.ext [mul16_a]
	jsr F_8348
	lda A, 0x31
	sta.ext A, [0x0087]
	ldd.ext [0x005c]
	jsr F_8348
	rts
.L_b1ad:
	lda.ext A, [0x0040]
	add A, 0x11
	sta.ext A, [0x0087]
	ldd.ext [mul16_a]
	jsr F_8348
	lda A, 0x32
	sta.ext A, [0x0087]
	ldd.ext [0x005e]
	jsr F_8348
	rts


F_b1c7:
	jsr F_b84e
	lda B, [PERIPH2.PORTC]
	and B, 0x40
	beq .L_b1d7
	cmp A, 0x1
	beq .L_b1e3
	bra .L_b1df
.L_b1d7:
	cmp A, 0x3
	beq .L_b1e3
	cmp A, 0x4
	beq .L_b1e3
.L_b1df:
	oim bit7, [0x6d]
	rts
.L_b1e3:
	inc A
	sta.ext A, [0x007d]
	ldd 0x0098
	std.ext [mul16_b]
	ldd 0x9680
	std.ext [0x0051]
	jsr F_b59a
	rts


F_b1f7:
	jsr F_b8bd
	inc A
	sta.ext A, [0x007d]
	ldd 0x000f
	std.ext [mul16_b]
	ldd 0x4240
	std.ext [0x0051]
	jsr F_b59a
	rts


F_b20e:
	jsr F_b92c
	inc A
	sta.ext A, [0x007d]
	ldd 0x0001
	std.ext [mul16_b]
	ldd 0x86a0
	std.ext [0x0051]
	jsr F_b59a
	rts


F_b225:
	jsr F_b99b
	inc A
	sta.ext A, [0x007d]
	ldd 0x0000
	std.ext [mul16_b]
	ldd 0x2710
	std.ext [0x0051]
	jsr F_b59a
	rts


F_b23c:
	jsr F_ba0a
	inc A
	sta.ext A, [0x007d]
	ldd 0x0000
	std.ext [mul16_b]
	ldd 0x03e8
	std.ext [0x0051]
	jsr F_b59a
	rts


F_b253:
	jsr F_ba79
	inc A
	sta.ext A, [0x007d]
	ldd 0x0000
	std.ext [mul16_b]
	ldd 0x0064
	std.ext [0x0051]
	jsr F_b59a
	rts


F_b26a:
	jsr F_bae8
	inc A
	sta.ext A, [0x007d]
	ldd 0x0000
	std.ext [mul16_b]
	ldd 0x000a
	std.ext [0x0051]
	jsr F_b59a
	rts


F_b281:
	tim bit0, [0x6a]
	bne .L_b28e
	tim bit5, [0x6a]
	bne .L_b28f
	oim bit7, [0x6d]
.L_b28e:
	rts
.L_b28f:
	lda A, 0x2
	sta.ext A, [0x007d]
	ldd 0x0000
	std.ext [mul16_b]
	ldd 0x0005
	std.ext [0x0051]
	jsr F_b59a
	rts


F_b2a4:
	clr [mul16_res]
	clr [mul16_res+1]
	clr [mul16_res+2]
	clr [mul16_res+3]
	clr [mul16_b]
	clr [mul16_b+1]
	clr [0x0051]
	clr [0x0052]
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	beq .L_b2f0
	tim bit7, [0x43]
	bne .L_b2dc

	ldx 0x1e78 ;7800
	cpx.ext [mul16_a]
	bcs .L_b34d
	ldd 0x01f4 ;500
	std.ext [mul16_b]
	jsr mul_16
	jmp .cont
.L_b2dc:
	ldx 0x1860 ;6240
	cpx.ext [mul16_a]
	bcs .L_b34d
	ldd 0x0271 ;625
	std.ext [mul16_b]
	jsr mul_16
	jmp .cont
.L_b2f0:
	lda A, [PERIPH2.PORTC]
	and A, 0x80
	bne .L_b322
	tim bit7, [0x43]
	bne .L_b30f
	ldx 0x7530 ;30000
	cpx.ext [mul16_a]
	bcs .L_b34d
	ldd 0x01f4 ;500
	std.ext [mul16_b]
	jsr mul_16
	bra .cont
.L_b30f:
	ldx 0x5dc0 ;24000
	cpx.ext [mul16_a]
	bcs .L_b34d
	ldd 0x0271 ;625
	std.ext [mul16_b]
	jsr mul_16
	bra .cont
.L_b322:
	tim bit7, [0x43]
	bne .L_b33a
	ldx 0x3a98 ;15000
	cpx.ext [mul16_a]
	bcs .L_b34d
	ldd 0x03e8 ;1000
	std.ext [mul16_b]
	jsr mul_16
	bra .cont
.L_b33a:
	ldx 0x2ee0 ;12000
	cpx.ext [mul16_a]
	bcs .L_b34d
	ldd 0x04e2 ;1250
	std.ext [mul16_b]
	jsr mul_16
	bra .cont
.L_b34d:
	tim bit1, [0x6d]
	bne .L_b357
	ldx 0x005c ;92
	bra .L_b35a
.L_b357:
	ldx 0x005e ;94
.L_b35a:
	lda.ext A, [0x0040]
	jsr clear_bit_double
	jsr lcd_c01_dashdash
	jsr lcd_dashes
	rts
.cont:
	tim bit1, [0x6d]
	bne .L_b371
	ldx 0x005c ;92
	bra .L_b374
.L_b371:
	ldx 0x005e ;94
.L_b374:
	lda.ext A, [0x0040]
	jsr set_bit_double
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	beq .L_b38f
	ldd 0x00cd
	std.ext [mul16_b]
	ldd 0xfe60
	std.ext [0x0051]
	bra .L_b39b
.L_b38f:
	ldd 0x01f7
	std.ext [mul16_b]
	ldd 0x8a40
	std.ext [0x0051]
.L_b39b:
	lda A, 0x2
	sta.ext A, [0x007d]
	jsr F_b59a
	ldd 0x0098
	std.ext [mul16_b]
	ldd 0x9680
	std.ext [0x0051]
	jsr F_b437
	lda.ext A, [0x007e]
	jsr F_b617
	ldd 0x000f
	std.ext [mul16_b]
	ldd 0x4240
	std.ext [0x0051]
	jsr F_b437
	lda.ext A, [0x007e]
	jsr F_b668
	ldd 0x0001
	std.ext [mul16_b]
	ldd 0x86a0
	std.ext [0x0051]
	jsr F_b437
	lda.ext A, [0x007e]
	jsr F_b6b9
	ldd 0x0000
	std.ext [mul16_b]
	ldd 0x2710
	std.ext [0x0051]
	jsr F_b437
	lda.ext A, [0x007e]
	jsr F_b70a
	ldd 0x0000
	std.ext [mul16_b]
	ldd 0x03e8
	std.ext [0x0051]
	jsr F_b437
	lda.ext A, [0x007e]
	jsr F_b75b
	ldd 0x0000
	std.ext [mul16_b]
	ldd 0x0064
	std.ext [0x0051]
	jsr F_b437
	lda.ext A, [0x007e]
	jsr F_b7ac
	ldd 0x0000
	std.ext [mul16_b]
	ldd 0x000a
	std.ext [0x0051]
	jsr F_b437
	lda.ext A, [0x007e]
	jsr F_b7fd
	rts


F_b437:
	clr [0x007e]
.L_b43a:
	jsr F_b5d1
	bcs .L_b447
	jsr F_b5b9
	inc [0x007e]
	bra .L_b43a
.L_b447:
	rts


F_b448:
	lda A, [PERIPH2.PORTC]
	and A, 0x40
	bne .L_b452
	jmp .L_b4cf
.L_b452:
	ldd 0x0109
	std.ext [mul16_b]
	ldd 0x80c0
	std.ext [0x0051]
	jsr F_b5d1
	bhi .L_b482
	ldd 0x00cd
	std.ext [mul16_b]
	ldd 0xfe60
	std.ext [0x0051]
	jsr F_b5d1
	bcs .L_b482
	ldd 0x00cd
	std.ext [mul16_b]
	ldd 0xfe60
	std.ext [0x0051]
	bra .L_b486
.L_b482:
	oim bit7, [0x6d]
	rts
.L_b486:
	jsr F_b5b9
	ldd.ext [mul16_res]
	std.ext [0x0053]
	ldd.ext [mul16_res+2]
	std.ext [0x0055]
	ldd 0x0271
	std.ext [0x007d]
	jsr F_b56a
	tst A
	bne .L_b4a6
	tst B
	bne .L_b4a6
	bra .L_b4c3
.L_b4a6:
	ldd.ext [0x0053]
	std.ext [mul16_res]
	ldd.ext [0x0055]
	std.ext [mul16_res+2]
	ldd 0x01f4
	std.ext [0x007d]
	jsr F_b56a
	tst A
	bne .L_b482
	tst B
	bne .L_b482
	bra .L_b4c8
.L_b4c3:
	oim bit7, [mul16_a]
	bra .L_b4cb
.L_b4c8:
	cim bit7, [mul16_a]
.L_b4cb:
	cim bit7, [0x6d]
	rts
.L_b4cf:
	ldd 0x02dc
	std.ext [mul16_b]
	ldd 0x6c00
	std.ext [0x0051]
	jsr F_b5d1
	bhi .L_b4ff
	ldd 0x01f7
	std.ext [mul16_b]
	ldd 0x8a40
	std.ext [0x0051]
	jsr F_b5d1
	bcs .L_b4ff
	ldd 0x01f7
	std.ext [mul16_b]
	ldd 0x8a40
	std.ext [0x0051]
	bra .L_b503
.L_b4ff:
	oim bit7, [0x6d]
	rts
.L_b503:
	jsr F_b5b9
	ldd.ext [mul16_res]
	std.ext [0x0053]
	ldd.ext [mul16_res+2]
	std.ext [0x0055]
	lda A, [PERIPH2.PORTC]
	and A, 0x80
	bne .L_b521
	ldd 0x0271
	std.ext [0x007d]
	bra .L_b527
.L_b521:
	ldd 0x04e2
	std.ext [0x007d]
.L_b527:
	jsr F_b56a
	tst A
	bne .L_b532
	tst B
	bne .L_b532
	bra .L_b55e
.L_b532:
	ldd.ext [0x0053]
	std.ext [mul16_res]
	ldd.ext [0x0055]
	std.ext [mul16_res+2]
	lda A, [PERIPH2.PORTC]
	and A, 0x80
	bne .L_b54d
	ldd 0x01f4
	std.ext [0x007d]
	bra .L_b553
.L_b54d:
	ldd 0x03e8
	std.ext [0x007d]
.L_b553:
	jsr F_b56a
	tst A
	bne .L_b4ff
	tst B
	bne .L_b4ff
	bra .L_b563
.L_b55e:
	oim bit7, [mul16_a]
	bra .L_b566
.L_b563:
	cim bit7, [mul16_a]
.L_b566:
	cim bit7, [0x6d]
	rts


F_b56a:
	lda A, 0x10
	sta.ext A, [0x0088]
	ldx.ext [mul16_res]
.L_b572:
	xgdx
	asld
	xgdx
	ldd.ext [mul16_res+2]
	asld
	std.ext [mul16_res+2]
	bcc .L_b57f
	inx
.L_b57f:
	ldd.ext [mul16_a]
	asld
	std.ext [mul16_a]
	cpx.ext [0x007d]
	bcs .L_b593
	oim bit0, [mul16_a+1]
	xgdx
	subd.ext [0x007d]
	xgdx
.L_b593:
	dec [0x0088]
	bne .L_b572
	xgdx
	rts


F_b59a:
	ldx.ext [mul16_res]
	ldd.ext [mul16_res+2]
.L_b5a0:
	dec [0x007d]
	beq .L_b5b2
	addd.ext [0x0051]
	xgdx
	adc.ext B, [mul16_b+1]
	adc.ext A, [mul16_b]
	xgdx
	bra .L_b5a0
.L_b5b2:
	stx.ext [mul16_res]
	std.ext [mul16_res+2]
	rts


F_b5b9:
	ldx.ext [mul16_res]
	ldd.ext [mul16_res+2]
	subd.ext [0x0051]
	xgdx
	sbc.ext B, [mul16_b+1]
	sbc.ext A, [mul16_b]
	xgdx
	stx.ext [mul16_res]
	std.ext [mul16_res+2]
	rts


F_b5d1:
	ldx.ext [mul16_res]
	ldd.ext [mul16_res+2]
	cpx.ext [mul16_b]
	bne .L_b5e1
	xgdx
	cpx.ext [0x0051]
	xgdx
.L_b5e1:
	rts


mul_16:
	lda.ext A, [mul16_a+1]
	lda.ext B, [mul16_b+1]
	mul
	std.ext [mul16_res+2]
	lda.ext A, [mul16_a]
	lda.ext B, [mul16_b+1]
	mul
	addd.ext [mul16_res+1]
	std.ext [mul16_res+1]
	lda.ext A, [mul16_a+1]
	lda.ext B, [mul16_b]
	mul
	addd.ext [mul16_res+1]
	std.ext [mul16_res+1]
	rol [mul16_res]
	lda.ext A, [mul16_a]
	lda.ext B, [mul16_b]
	mul
	addd.ext [mul16_res]
	std.ext [mul16_res]
	rts


F_b617:
	cmp A, 0x0
	beq .L_b640
	cmp A, 0x1
	beq .L_b644
	cmp A, 0x2
	beq .L_b648
	cmp A, 0x3
	beq .L_b64c
	cmp A, 0x4
	beq .L_b650
	cmp A, 0x5
	beq .L_b654
	cmp A, 0x6
	beq .L_b658
	cmp A, 0x7
	beq .L_b65c
	cmp A, 0x8
	beq .L_b660
	cmp A, 0x9
	beq .L_b664
	rts
.L_b640:
	jsr lcd_c0_0
	rts
.L_b644:
	jsr lcd_c0_1
	rts
.L_b648:
	jsr lcd_c0_2
	rts
.L_b64c:
	jsr lcd_c0_3
	rts
.L_b650:
	jsr lcd_c0_4
	rts
.L_b654:
	jsr lcd_c0_5
	rts
.L_b658:
	jsr lcd_c0_6
	rts
.L_b65c:
	jsr lcd_c0_7
	rts
.L_b660:
	jsr lcd_c0_8
	rts
.L_b664:
	jsr lcd_c0_9
	rts


F_b668:
	cmp A, 0x0
	beq .L_b691
	cmp A, 0x1
	beq .L_b695
	cmp A, 0x2
	beq .L_b699
	cmp A, 0x3
	beq .L_b69d
	cmp A, 0x4
	beq .L_b6a1
	cmp A, 0x5
	beq .L_b6a5
	cmp A, 0x6
	beq .L_b6a9
	cmp A, 0x7
	beq .L_b6ad
	cmp A, 0x8
	beq .L_b6b1
	cmp A, 0x9
	beq .L_b6b5
	rts
.L_b691:
	jsr lcd_c1_0
	rts
.L_b695:
	jsr lcd_c1_1
	rts
.L_b699:
	jsr lcd_c1_2
	rts
.L_b69d:
	jsr lcd_c1_3
	rts
.L_b6a1:
	jsr lcd_c1_4
	rts
.L_b6a5:
	jsr lcd_c1_5
	rts
.L_b6a9:
	jsr lcd_c1_6
	rts
.L_b6ad:
	jsr lcd_c1_7
	rts
.L_b6b1:
	jsr lcd_c1_8
	rts
.L_b6b5:
	jsr lcd_c1_9
	rts


F_b6b9:
	cmp A, 0x0
	beq .L_b6e2
	cmp A, 0x1
	beq .L_b6e6
	cmp A, 0x2
	beq .L_b6ea
	cmp A, 0x3
	beq .L_b6ee
	cmp A, 0x4
	beq .L_b6f2
	cmp A, 0x5
	beq .L_b6f6
	cmp A, 0x6
	beq .L_b6fa
	cmp A, 0x7
	beq .L_b6fe
	cmp A, 0x8
	beq .L_b702
	cmp A, 0x9
	beq .L_b706
	rts
.L_b6e2:
	jsr lcd_c2_0
	rts
.L_b6e6:
	jsr lcd_c2_1
	rts
.L_b6ea:
	jsr lcd_c2_2
	rts
.L_b6ee:
	jsr lcd_c2_3
	rts
.L_b6f2:
	jsr lcd_c2_4
	rts
.L_b6f6:
	jsr lcd_c2_5
	rts
.L_b6fa:
	jsr lcd_c2_6
	rts
.L_b6fe:
	jsr lcd_c2_7
	rts
.L_b702:
	jsr lcd_c2_8
	rts
.L_b706:
	jsr lcd_c2_9
	rts


F_b70a:
	cmp A, 0x0
	beq .L_b733
	cmp A, 0x1
	beq .L_b737
	cmp A, 0x2
	beq .L_b73b
	cmp A, 0x3
	beq .L_b73f
	cmp A, 0x4
	beq .L_b743
	cmp A, 0x5
	beq .L_b747
	cmp A, 0x6
	beq .L_b74b
	cmp A, 0x7
	beq .L_b74f
	cmp A, 0x8
	beq .L_b753
	cmp A, 0x9
	beq .L_b757
	rts
.L_b733:
	jsr lcd_c3_0
	rts
.L_b737:
	jsr lcd_c3_1
	rts
.L_b73b:
	jsr lcd_c3_2
	rts
.L_b73f:
	jsr lcd_c3_3
	rts
.L_b743:
	jsr lcd_c3_4
	rts
.L_b747:
	jsr lcd_c3_5
	rts
.L_b74b:
	jsr lcd_c3_6
	rts
.L_b74f:
	jsr lcd_c3_7
	rts
.L_b753:
	jsr lcd_c3_8
	rts
.L_b757:
	jsr lcd_c3_9
	rts


F_b75b:
	cmp A, 0x0
	beq .L_b784
	cmp A, 0x1
	beq .L_b788
	cmp A, 0x2
	beq .L_b78c
	cmp A, 0x3
	beq .L_b790
	cmp A, 0x4
	beq .L_b794
	cmp A, 0x5
	beq .L_b798
	cmp A, 0x6
	beq .L_b79c
	cmp A, 0x7
	beq .L_b7a0
	cmp A, 0x8
	beq .L_b7a4
	cmp A, 0x9
	beq .L_b7a8
	rts
.L_b784:
	jsr lcd_c4_0
	rts
.L_b788:
	jsr lcd_c4_1
	rts
.L_b78c:
	jsr lcd_c4_2
	rts
.L_b790:
	jsr lcd_c4_3
	rts
.L_b794:
	jsr lcd_c4_4
	rts
.L_b798:
	jsr lcd_c4_5
	rts
.L_b79c:
	jsr lcd_c4_6
	rts
.L_b7a0:
	jsr lcd_c4_7
	rts
.L_b7a4:
	jsr lcd_c4_8
	rts
.L_b7a8:
	jsr lcd_c4_9
	rts


F_b7ac:
	cmp A, 0x0
	beq .L_b7d5
	cmp A, 0x1
	beq .L_b7d9
	cmp A, 0x2
	beq .L_b7dd
	cmp A, 0x3
	beq .L_b7e1
	cmp A, 0x4
	beq .L_b7e5
	cmp A, 0x5
	beq .L_b7e9
	cmp A, 0x6
	beq .L_b7ed
	cmp A, 0x7
	beq .L_b7f1
	cmp A, 0x8
	beq .L_b7f5
	cmp A, 0x9
	beq .L_b7f9
	rts
.L_b7d5:
	jsr lcd_c5_0
	rts
.L_b7d9:
	jsr lcd_c5_1
	rts
.L_b7dd:
	jsr lcd_c5_2
	rts
.L_b7e1:
	jsr lcd_c5_3
	rts
.L_b7e5:
	jsr lcd_c5_4
	rts
.L_b7e9:
	jsr lcd_c5_5
	rts
.L_b7ed:
	jsr lcd_c5_6
	rts
.L_b7f1:
	jsr lcd_c5_7
	rts
.L_b7f5:
	jsr lcd_c5_8
	rts
.L_b7f9:
	jsr lcd_c5_9
	rts


F_b7fd:
	cmp A, 0x0
	beq .L_b826
	cmp A, 0x1
	beq .L_b82a
	cmp A, 0x2
	beq .L_b82e
	cmp A, 0x3
	beq .L_b832
	cmp A, 0x4
	beq .L_b836
	cmp A, 0x5
	beq .L_b83a
	cmp A, 0x6
	beq .L_b83e
	cmp A, 0x7
	beq .L_b842
	cmp A, 0x8
	beq .L_b846
	cmp A, 0x9
	beq .L_b84a
	rts
.L_b826:
	jsr lcd_c6_0
	rts
.L_b82a:
	jsr lcd_c6_1
	rts
.L_b82e:
	jsr lcd_c6_2
	rts
.L_b832:
	jsr lcd_c6_3
	rts
.L_b836:
	jsr lcd_c6_4
	rts
.L_b83a:
	jsr lcd_c6_5
	rts
.L_b83e:
	jsr lcd_c6_6
	rts
.L_b842:
	jsr lcd_c6_7
	rts
.L_b846:
	jsr lcd_c6_8
	rts
.L_b84a:
	jsr lcd_c6_9
	rts


F_b84e:
	tim bit0, [0x6a]
	bne .L_b881
	tim bit1, [0x6a]
	bne .L_b887
	tim bit2, [0x6a]
	bne .L_b88d
	tim bit3, [0x6a]
	bne .L_b893
	tim bit4, [0x6a]
	bne .L_b899
	tim bit5, [0x6a]
	bne .L_b89f
	tim bit6, [0x6a]
	bne .L_b8a5
	tim bit7, [0x6a]
	bne .L_b8ab
	tim bit0, [0x6b]
	bne .L_b8b1
	tim bit1, [0x6b]
	bne .L_b8b7
	rts
.L_b881:
	jsr lcd_c0_0
	lda A, 0x0
	rts
.L_b887:
	jsr lcd_c0_1
	lda A, 0x1
	rts
.L_b88d:
	jsr lcd_c0_2
	lda A, 0x2
	rts
.L_b893:
	jsr lcd_c0_3
	lda A, 0x3
	rts
.L_b899:
	jsr lcd_c0_4
	lda A, 0x4
	rts
.L_b89f:
	jsr lcd_c0_5
	lda A, 0x5
	rts
.L_b8a5:
	jsr lcd_c0_6
	lda A, 0x6
	rts
.L_b8ab:
	jsr lcd_c0_7
	lda A, 0x7
	rts
.L_b8b1:
	jsr lcd_c0_8
	lda A, 0x8
	rts
.L_b8b7:
	jsr lcd_c0_9
	lda A, 0x9
	rts


F_b8bd:
	tim bit0, [0x6a]
	bne .L_b8f0
	tim bit1, [0x6a]
	bne .L_b8f6
	tim bit2, [0x6a]
	bne .L_b8fc
	tim bit3, [0x6a]
	bne .L_b902
	tim bit4, [0x6a]
	bne .L_b908
	tim bit5, [0x6a]
	bne .L_b90e
	tim bit6, [0x6a]
	bne .L_b914
	tim bit7, [0x6a]
	bne .L_b91a
	tim bit0, [0x6b]
	bne .L_b920
	tim bit1, [0x6b]
	bne .L_b926
	rts
.L_b8f0:
	jsr lcd_c1_0
	lda A, 0x0
	rts
.L_b8f6:
	jsr lcd_c1_1
	lda A, 0x1
	rts
.L_b8fc:
	jsr lcd_c1_2
	lda A, 0x2
	rts
.L_b902:
	jsr lcd_c1_3
	lda A, 0x3
	rts
.L_b908:
	jsr lcd_c1_4
	lda A, 0x4
	rts
.L_b90e:
	jsr lcd_c1_5
	lda A, 0x5
	rts
.L_b914:
	jsr lcd_c1_6
	lda A, 0x6
	rts
.L_b91a:
	jsr lcd_c1_7
	lda A, 0x7
	rts
.L_b920:
	jsr lcd_c1_8
	lda A, 0x8
	rts
.L_b926:
	jsr lcd_c1_9
	lda A, 0x9
	rts


F_b92c:
	tim bit0, [0x6a]
	bne .L_b95f
	tim bit1, [0x6a]
	bne .L_b965
	tim bit2, [0x6a]
	bne .L_b96b
	tim bit3, [0x6a]
	bne .L_b971
	tim bit4, [0x6a]
	bne .L_b977
	tim bit5, [0x6a]
	bne .L_b97d
	tim bit6, [0x6a]
	bne .L_b983
	tim bit7, [0x6a]
	bne .L_b989
	tim bit0, [0x6b]
	bne .L_b98f
	tim bit1, [0x6b]
	bne .L_b995
	rts
.L_b95f:
	jsr lcd_c2_0
	lda A, 0x0
	rts
.L_b965:
	jsr lcd_c2_1
	lda A, 0x1
	rts
.L_b96b:
	jsr lcd_c2_2
	lda A, 0x2
	rts
.L_b971:
	jsr lcd_c2_3
	lda A, 0x3
	rts
.L_b977:
	jsr lcd_c2_4
	lda A, 0x4
	rts
.L_b97d:
	jsr lcd_c2_5
	lda A, 0x5
	rts
.L_b983:
	jsr lcd_c2_6
	lda A, 0x6
	rts
.L_b989:
	jsr lcd_c2_7
	lda A, 0x7
	rts
.L_b98f:
	jsr lcd_c2_8
	lda A, 0x8
	rts
.L_b995:
	jsr lcd_c2_9
	lda A, 0x9
	rts


F_b99b:
	tim bit0, [0x6a]
	bne .L_b9ce
	tim bit1, [0x6a]
	bne .L_b9d4
	tim bit2, [0x6a]
	bne .L_b9da
	tim bit3, [0x6a]
	bne .L_b9e0
	tim bit4, [0x6a]
	bne .L_b9e6
	tim bit5, [0x6a]
	bne .L_b9ec
	tim bit6, [0x6a]
	bne .L_b9f2
	tim bit7, [0x6a]
	bne .L_b9f8
	tim bit0, [0x6b]
	bne .L_b9fe
	tim bit1, [0x6b]
	bne .L_ba04
	rts
.L_b9ce:
	jsr lcd_c3_0
	lda A, 0x0
	rts
.L_b9d4:
	jsr lcd_c3_1
	lda A, 0x1
	rts
.L_b9da:
	jsr lcd_c3_2
	lda A, 0x2
	rts
.L_b9e0:
	jsr lcd_c3_3
	lda A, 0x3
	rts
.L_b9e6:
	jsr lcd_c3_4
	lda A, 0x4
	rts
.L_b9ec:
	jsr lcd_c3_5
	lda A, 0x5
	rts
.L_b9f2:
	jsr lcd_c3_6
	lda A, 0x6
	rts
.L_b9f8:
	jsr lcd_c3_7
	lda A, 0x7
	rts
.L_b9fe:
	jsr lcd_c3_8
	lda A, 0x8
	rts
.L_ba04:
	jsr lcd_c3_9
	lda A, 0x9
	rts


F_ba0a:
	tim bit0, [0x6a]
	bne .L_ba3d
	tim bit1, [0x6a]
	bne .L_ba43
	tim bit2, [0x6a]
	bne .L_ba49
	tim bit3, [0x6a]
	bne .L_ba4f
	tim bit4, [0x6a]
	bne .L_ba55
	tim bit5, [0x6a]
	bne .L_ba5b
	tim bit6, [0x6a]
	bne .L_ba61
	tim bit7, [0x6a]
	bne .L_ba67
	tim bit0, [0x6b]
	bne .L_ba6d
	tim bit1, [0x6b]
	bne .L_ba73
	rts
.L_ba3d:
	jsr lcd_c4_0
	lda A, 0x0
	rts
.L_ba43:
	jsr lcd_c4_1
	lda A, 0x1
	rts
.L_ba49:
	jsr lcd_c4_2
	lda A, 0x2
	rts
.L_ba4f:
	jsr lcd_c4_3
	lda A, 0x3
	rts
.L_ba55:
	jsr lcd_c4_4
	lda A, 0x4
	rts
.L_ba5b:
	jsr lcd_c4_5
	lda A, 0x5
	rts
.L_ba61:
	jsr lcd_c4_6
	lda A, 0x6
	rts
.L_ba67:
	jsr lcd_c4_7
	lda A, 0x7
	rts
.L_ba6d:
	jsr lcd_c4_8
	lda A, 0x8
	rts
.L_ba73:
	jsr lcd_c4_9
	lda A, 0x9
	rts


F_ba79:
	tim bit0, [0x6a]
	bne .L_baac
	tim bit1, [0x6a]
	bne .L_bab2
	tim bit2, [0x6a]
	bne .L_bab8
	tim bit3, [0x6a]
	bne .L_babe
	tim bit4, [0x6a]
	bne .L_bac4
	tim bit5, [0x6a]
	bne .L_baca
	tim bit6, [0x6a]
	bne .L_bad0
	tim bit7, [0x6a]
	bne .L_bad6
	tim bit0, [0x6b]
	bne .L_badc
	tim bit1, [0x6b]
	bne .L_bae2
	rts
.L_baac:
	jsr lcd_c5_0
	lda A, 0x0
	rts
.L_bab2:
	jsr lcd_c5_1
	lda A, 0x1
	rts
.L_bab8:
	jsr lcd_c5_2
	lda A, 0x2
	rts
.L_babe:
	jsr lcd_c5_3
	lda A, 0x3
	rts
.L_bac4:
	jsr lcd_c5_4
	lda A, 0x4
	rts
.L_baca:
	jsr lcd_c5_5
	lda A, 0x5
	rts
.L_bad0:
	jsr lcd_c5_6
	lda A, 0x6
	rts
.L_bad6:
	jsr lcd_c5_7
	lda A, 0x7
	rts
.L_badc:
	jsr lcd_c5_8
	lda A, 0x8
	rts
.L_bae2:
	jsr lcd_c5_9
	lda A, 0x9
	rts


F_bae8:
	tim bit0, [0x6a]
	bne .L_bb1b
	tim bit1, [0x6a]
	bne .L_bb21
	tim bit2, [0x6a]
	bne .L_bb27
	tim bit3, [0x6a]
	bne .L_bb2d
	tim bit4, [0x6a]
	bne .L_bb33
	tim bit5, [0x6a]
	bne .L_bb39
	tim bit6, [0x6a]
	bne .L_bb3f
	tim bit7, [0x6a]
	bne .L_bb45
	tim bit0, [0x6b]
	bne .L_bb4b
	tim bit1, [0x6b]
	bne .L_bb51
	rts
.L_bb1b:
	jsr lcd_c6_0
	lda A, 0x0
	rts
.L_bb21:
	jsr lcd_c6_1
	lda A, 0x1
	rts
.L_bb27:
	jsr lcd_c6_2
	lda A, 0x2
	rts
.L_bb2d:
	jsr lcd_c6_3
	lda A, 0x3
	rts
.L_bb33:
	jsr lcd_c6_4
	lda A, 0x4
	rts
.L_bb39:
	jsr lcd_c6_5
	lda A, 0x5
	rts
.L_bb3f:
	jsr lcd_c6_6
	lda A, 0x6
	rts
.L_bb45:
	jsr lcd_c6_7
	lda A, 0x7
	rts
.L_bb4b:
	jsr lcd_c6_8
	lda A, 0x8
	rts
.L_bb51:
	jsr lcd_c6_9
	lda A, 0x9
	rts


F_bb57:
	lda.ext A, [0x0040]
	cmp A, 0x0
	beq .L_bb9b
	cmp A, 0x1
	beq .L_bba2
	cmp A, 0x2
	beq .L_bba9
	cmp A, 0x3
	beq .L_bbb0
	cmp A, 0x4
	beq .L_bbb7
	cmp A, 0x5
	beq .L_bbbe
	cmp A, 0x6
	beq .L_bbc5
	cmp A, 0x7
	beq .L_bbcc
	cmp A, 0x8
	beq .L_bbd3
	cmp A, 0x9
	beq .L_bbda
	cmp A, 0xa
	beq .L_bbe1
	cmp A, 0xb
	beq .L_bbe8
	cmp A, 0xc
	beq .L_bbef
	cmp A, 0xd
	beq .L_bbf6
	cmp A, 0xe
	beq .L_bbfd
	cmp A, 0xf
	beq .L_bc04
	rts
.L_bb9b:
	jsr lcd_c1_0
	jsr lcd_c2_1
	rts
.L_bba2:
	jsr lcd_c1_0
	jsr lcd_c2_2
	rts
.L_bba9:
	jsr lcd_c1_0
	jsr lcd_c2_3
	rts
.L_bbb0:
	jsr lcd_c1_0
	jsr lcd_c2_4
	rts
.L_bbb7:
	jsr lcd_c1_0
	jsr lcd_c2_5
	rts
.L_bbbe:
	jsr lcd_c1_0
	jsr lcd_c2_6
	rts
.L_bbc5:
	jsr lcd_c1_0
	jsr lcd_c2_7
	rts
.L_bbcc:
	jsr lcd_c1_0
	jsr lcd_c2_8
	rts
.L_bbd3:
	jsr lcd_c1_0
	jsr lcd_c2_9
	rts
.L_bbda:
	jsr lcd_c1_1
	jsr lcd_c2_0
	rts
.L_bbe1:
	jsr lcd_c1_1
	jsr lcd_c2_1
	rts
.L_bbe8:
	jsr lcd_c1_1
	jsr lcd_c2_2
	rts
.L_bbef:
	jsr lcd_c1_1
	jsr lcd_c2_3
	rts
.L_bbf6:
	jsr lcd_c1_1
	jsr lcd_c2_4
	rts
.L_bbfd:
	jsr lcd_c1_1
	jsr lcd_c2_5
	rts
.L_bc04:
	jsr lcd_c1_1
	jsr lcd_c2_6
	rts


F_bc0b:
	cmp A, 0x0
	beq .L_bc4c
	cmp A, 0x1
	beq .L_bc53
	cmp A, 0x2
	beq .L_bc5a
	cmp A, 0x3
	beq .L_bc61
	cmp A, 0x4
	beq .L_bc68
	cmp A, 0x5
	beq .L_bc6f
	cmp A, 0x6
	beq .L_bc76
	cmp A, 0x7
	beq .L_bc7d
	cmp A, 0x8
	beq .L_bc84
	cmp A, 0x9
	beq .L_bc8b
	cmp A, 0xa
	beq .L_bc92
	cmp A, 0xb
	beq .L_bc99
	cmp A, 0xc
	beq .L_bca0
	cmp A, 0xd
	beq .L_bca7
	cmp A, 0xe
	beq .L_bcae
	cmp A, 0xf
	beq .L_bcb5
	rts
.L_bc4c:
	jsr lcd_c5_0
	jsr lcd_c6_1
	rts
.L_bc53:
	jsr lcd_c5_0
	jsr lcd_c6_2
	rts
.L_bc5a:
	jsr lcd_c5_0
	jsr lcd_c6_3
	rts
.L_bc61:
	jsr lcd_c5_0
	jsr lcd_c6_4
	rts
.L_bc68:
	jsr lcd_c5_0
	jsr lcd_c6_5
	rts
.L_bc6f:
	jsr lcd_c5_0
	jsr lcd_c6_6
	rts
.L_bc76:
	jsr lcd_c5_0
	jsr lcd_c6_7
	rts
.L_bc7d:
	jsr lcd_c5_0
	jsr lcd_c6_8
	rts
.L_bc84:
	jsr lcd_c5_0
	jsr lcd_c6_9
	rts
.L_bc8b:
	jsr lcd_c5_1
	jsr lcd_c6_0
	rts
.L_bc92:
	jsr lcd_c5_1
	jsr lcd_c6_1
	rts
.L_bc99:
	jsr lcd_c5_1
	jsr lcd_c6_2
	rts
.L_bca0:
	jsr lcd_c5_1
	jsr lcd_c6_3
	rts
.L_bca7:
	jsr lcd_c5_1
	jsr lcd_c6_4
	rts
.L_bcae:
	jsr lcd_c5_1
	jsr lcd_c6_5
	rts
.L_bcb5:
	jsr lcd_c5_1
	jsr lcd_c6_6
	rts


F_bcbc:
	ldx 0xbcd5
	clr A
	lda B, 0x10
.L_bcc2:
	cmp.ext A, [0x005b]
	bne .L_bcc9
	jmp [X]
.L_bcc9:
	inc A
	xgdx
	addd 0x000a
	xgdx
	dec B
	bne .L_bcc2
	clr [0x005b]


jtb_L_bcd5_0_bcd5:
	jsr lcd_c0_off
	jsr lcd_c1_off
	jsr lcd_c2_off
	rts


jtb_L_bcd5_1_bcdf:
	jsr lcd_c0_off
	jsr lcd_c1_1
	jsr lcd_c2_5
	rts


jtb_L_bcd5_2_bce9:
	jsr lcd_c0_off
	jsr lcd_c1_3
	jsr lcd_c2_0
	rts


jtb_L_bcd5_3_bcf3:
	jsr lcd_c0_off
	jsr lcd_c1_4
	jsr lcd_c2_5
	rts


jtb_L_bcd5_4_bcfd:
	jsr lcd_c0_off
	jsr lcd_c1_6
	jsr lcd_c2_0
	rts


jtb_L_bcd5_5_bd07:
	jsr lcd_c0_off
	jsr lcd_c1_7
	jsr lcd_c2_5
	rts


jtb_L_bcd5_6_bd11:
	jsr lcd_c0_off
	jsr lcd_c1_9
	jsr lcd_c2_0
	rts


jtb_L_bcd5_7_bd1b:
	jsr lcd_c0_1
	jsr lcd_c1_0
	jsr lcd_c2_5
	rts


jtb_L_bcd5_8_bd25:
	jsr lcd_c0_1
	jsr lcd_c1_2
	jsr lcd_c2_0
	rts


jtb_L_bcd5_9_bd2f:
	jsr lcd_c0_1
	jsr lcd_c1_3
	jsr lcd_c2_5
	rts


jtb_L_bcd5_10_bd39:
	jsr lcd_c0_1
	jsr lcd_c1_5
	jsr lcd_c2_0
	rts


jtb_L_bcd5_11_bd43:
	jsr lcd_c0_1
	jsr lcd_c1_6
	jsr lcd_c2_5
	rts


jtb_L_bcd5_12_bd4d:
	jsr lcd_c0_1
	jsr lcd_c1_8
	jsr lcd_c2_0
	rts


jtb_L_bcd5_13_bd57:
	jsr lcd_c0_1
	jsr lcd_c1_9
	jsr lcd_c2_5
	rts


jtb_L_bcd5_14_bd61:
	jsr lcd_c0_2
	jsr lcd_c1_1
	jsr lcd_c2_0
	rts


jtb_L_bcd5_15_bd6b:
	jsr lcd_c0_2
	jsr lcd_c1_2
	jsr lcd_c2_5
	rts


F_bd75:
	lda.ext A, [0x005a]
	cmp A, 0x0
	bne .L_bd86
	jsr lcd_c2_off
	jsr lcd_c3_off
	jsr lcd_nOFF
	rts
.L_bd86:
	lda.ext A, [0x005a]
	cmp A, 0xf
	bne .L_bd9d
	jsr lcd_c2_off
	jsr lcd_c3_off
	jsr lcd_c4_i
	jsr lcd_c5_n
	jsr lcd_c6_F
	rts

.L_bd9d:
	jsr lcd_nSEC
	lda.ext A, [0x005a]
	cmp A, 0x1
	beq .L_bddc
	cmp A, 0x2
	beq .L_bde3
	cmp A, 0x3
	beq .L_bdea
	cmp A, 0x4
	beq .L_bdf1
	cmp A, 0x5
	beq .L_bdf8
	cmp A, 0x6
	beq .L_bdff
	cmp A, 0x7
	beq .L_be06
	cmp A, 0x8
	beq .L_be0d
	cmp A, 0x9
	beq .L_be14
	cmp A, 0xa
	beq .L_be1b
	cmp A, 0xb
	beq .L_be22
	cmp A, 0xc
	beq .L_be29
	cmp A, 0xd
	beq .L_be30
	cmp A, 0xe
	beq .L_be37
	rts
.L_bddc:
	jsr lcd_c2_0
	jsr lcd_c3_1
	rts
.L_bde3:
	jsr lcd_c2_0
	jsr lcd_c3_2
	rts
.L_bdea:
	jsr lcd_c2_0
	jsr lcd_c3_3
	rts
.L_bdf1:
	jsr lcd_c2_0
	jsr lcd_c3_4
	rts
.L_bdf8:
	jsr lcd_c2_0
	jsr lcd_c3_5
	rts
.L_bdff:
	jsr lcd_c2_0
	jsr lcd_c3_6
	rts
.L_be06:
	jsr lcd_c2_0
	jsr lcd_c3_7
	rts
.L_be0d:
	jsr lcd_c2_0
	jsr lcd_c3_8
	rts
.L_be14:
	jsr lcd_c2_0
	jsr lcd_c3_9
	rts
.L_be1b:
	jsr lcd_c2_1
	jsr lcd_c3_0
	rts
.L_be22:
	jsr lcd_c2_1
	jsr lcd_c3_1
	rts
.L_be29:
	jsr lcd_c2_1
	jsr lcd_c3_2
	rts
.L_be30:
	jsr lcd_c2_1
	jsr lcd_c3_3
	rts
.L_be37:
	jsr lcd_c2_1
	jsr lcd_c3_4


F_be3d:
	lda.ext A, [0x0059]
	cmp A, 0x0
	beq .L_be81
	cmp A, 0x1
	beq .L_be88
	cmp A, 0x2
	beq .L_be8f
	cmp A, 0x3
	beq .L_be96
	cmp A, 0x4
	beq .L_be9d
	cmp A, 0x5
	beq .L_bea4
	cmp A, 0x6
	beq .L_beab
	cmp A, 0x7
	beq .L_beb2
	cmp A, 0x8
	beq .L_beb9
	cmp A, 0x9
	beq .L_bec0
	cmp A, 0xa
	beq .L_bec7
	cmp A, 0xb
	beq .L_bece
	cmp A, 0xc
	beq .L_bed5
	cmp A, 0xd
	beq .L_bedc
	cmp A, 0xe
	beq .L_bee3
	cmp A, 0xf
	beq .L_beea
	rts
.L_be81:
	jsr lcd_c2_0
	jsr lcd_c3_5
	rts
.L_be88:
	jsr lcd_c2_1
	jsr lcd_c3_0
	rts
.L_be8f:
	jsr lcd_c2_1
	jsr lcd_c3_5
	rts
.L_be96:
	jsr lcd_c2_2
	jsr lcd_c3_0
	rts
.L_be9d:
	jsr lcd_c2_2
	jsr lcd_c3_5
	rts
.L_bea4:
	jsr lcd_c2_3
	jsr lcd_c3_0
	rts
.L_beab:
	jsr lcd_c2_3
	jsr lcd_c3_5
	rts
.L_beb2:
	jsr lcd_c2_4
	jsr lcd_c3_0
	rts
.L_beb9:
	jsr lcd_c2_4
	jsr lcd_c3_5
	rts
.L_bec0:
	jsr lcd_c2_5
	jsr lcd_c3_0
	rts
.L_bec7:
	jsr lcd_c2_5
	jsr lcd_c3_5
	rts
.L_bece:
	jsr lcd_c2_6
	jsr lcd_c3_0
	rts
.L_bed5:
	jsr lcd_c2_6
	jsr lcd_c3_5
	rts
.L_bedc:
	jsr lcd_c2_7
	jsr lcd_c3_0
	rts
.L_bee3:
	jsr lcd_c2_7
	jsr lcd_c3_5
	rts
.L_beea:
	jsr lcd_c2_8
	jsr lcd_c3_0
	rts


lcd_nSEC:
	jsr lcd_c3_off
	jsr lcd_c4_5
	jsr lcd_c5_E
	jsr lcd_c6_C
	rts


lcd_nTCS:
	jsr lcd_c4_t
	jsr lcd_c5_C
	jsr lcd_c6_5
	rts


lcd_c01_dashdash:
	jsr lcd_c0_dash
	jsr lcd_c1_dash
	rts


lcd_dashes:
	jsr lcd_c2_dash
	jsr lcd_c3_dash
	jsr lcd_c4_dash
	jsr lcd_c5_dash
	jsr lcd_c6_dash
	rts


lcd_nON:
	jsr lcd_c4_off
	jsr lcd_c5_0
	jsr lcd_c6_n
	rts


lcd_nOFF:
	jsr lcd_c4_0
	jsr lcd_c5_F
	jsr lcd_c6_F
	rts

lcd_seg_3_7_on:
    lcd_seg_on 0, 3*4
	oim bit7, [lcd_data+3]
	rts


lcd_seg_3_7_off:
    lcd_seg_off 0, 3*4
	cim bit7, [lcd_data+3]
	rts


lcd_seg_0_7_on:
    lcd_seg_on 0,0
	oim bit7, [lcd_data+0]
	rts


lcd_seg_0_7_off:
    lcd_seg_off 0,0
	cim bit7, [lcd_data+0]
	rts


lcd_seg_1_7_on:
    lcd_seg_on 0,4
	oim bit7, [lcd_data+1]
	rts


lcd_seg_1_7_off:
    lcd_seg_off 0,4
	cim bit7, [lcd_data+1]
	rts


lcd_seg_4_7_on:
	lcd_seg_on 0, 4*4
	oim bit7, [lcd_data+4]
	rts


lcd_seg_4_7_off:
    lcd_seg_off 0,4*4
	cim bit7, [lcd_data+4]
	rts


lcd_seg_5_7_on:
    lcd_seg_on 0, 5*4
	oim bit7, [lcd_data+5]
	rts


lcd_seg_5_7_off:
    lcd_seg_off 0,5*4
	cim bit7, [lcd_data+5]
	rts


lcd_seg_5_5_on:
    lcd_seg_on 0, 5*4+1
	oim bit5, [lcd_data+5]
	rts


lcd_seg_5_5_off:
    lcd_seg_off 0,5*4+1
	cim bit5, [lcd_data+5]
	rts


lcd_seg_1_0_on:
    lcd_seg_on 1, 1*4+3
	oim bit0, [lcd_data+1]
	rts


lcd_seg_1_0_off:
    lcd_seg_off 1,1*4+3
	cim bit0, [lcd_data+1]
	rts


lcd_num_dash_dash:
	jsr lcd_c5_dash
	jsr lcd_c6_dash
	rts


lcd_num_off:
	jsr lcd_c5_off
	jsr lcd_c6_off
	rts


lcd_c0_0:
	oim bit6, [lcd_data+3]
	oim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	cim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_1:
	cim bit6, [lcd_data+3]
	oim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	cim bit5, [lcd_data+1]
	cim bit1, [lcd_data+0]
	cim bit5, [lcd_data+0]
	cim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_2:
	oim bit6, [lcd_data+3]
	oim bit4, [lcd_data+0]
	cim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	cim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_3:
	oim bit6, [lcd_data+3]
	oim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	cim bit1, [lcd_data+0]
	cim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_4:
	cim bit6, [lcd_data+3]
	oim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	cim bit5, [lcd_data+1]
	cim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_5:
	oim bit6, [lcd_data+3]
	cim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	cim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_6:
	oim bit6, [lcd_data+3]
	cim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_7:
	oim bit6, [lcd_data+3]
	oim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	cim bit5, [lcd_data+1]
	cim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	cim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_8:
	oim bit6, [lcd_data+3]
	oim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_9:
	oim bit6, [lcd_data+3]
	oim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	cim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_r:
	cim bit6, [lcd_data+3]
	cim bit4, [lcd_data+0]
	cim bit4, [lcd_data+1]
	cim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	cim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_d:
	cim bit6, [lcd_data+3]
	oim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	cim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_E:
	oim bit6, [lcd_data+3]
	cim bit4, [lcd_data+0]
	cim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_t:
	cim bit6, [lcd_data+3]
	cim bit4, [lcd_data+0]
	cim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_n:
	cim bit6, [lcd_data+3]
	cim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	cim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	cim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_C:
	oim bit6, [lcd_data+3]
	cim bit4, [lcd_data+0]
	cim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	cim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_b:
	cim bit6, [lcd_data+3]
	cim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	oim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_A:
	oim bit6, [lcd_data+3]
	oim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	cim bit5, [lcd_data+1]
	oim bit1, [lcd_data+0]
	oim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_i:
	cim bit6, [lcd_data+3]
	cim bit4, [lcd_data+0]
	oim bit4, [lcd_data+1]
	cim bit5, [lcd_data+1]
	cim bit1, [lcd_data+0]
	cim bit5, [lcd_data+0]
	cim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_dash:
	cim bit6, [lcd_data+3]
	cim bit4, [lcd_data+0]
	cim bit4, [lcd_data+1]
	cim bit5, [lcd_data+1]
	cim bit1, [lcd_data+0]
	cim bit5, [lcd_data+0]
	oim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c0_off:
	cim bit6, [lcd_data+3]
	cim bit4, [lcd_data+0]
	cim bit4, [lcd_data+1]
	cim bit5, [lcd_data+1]
	cim bit1, [lcd_data+0]
	cim bit5, [lcd_data+0]
	cim bit0, [lcd_data+0]
	jsr update_lcd_c0
	rts


lcd_c1_0:
	oim bit6, [lcd_data+1]
	oim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	cim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_1:
	cim bit6, [lcd_data+1]
	oim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	cim bit3, [lcd_data+1]
	cim bit7, [lcd_data+2]
	cim bit3, [lcd_data+2]
	cim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_2:
	oim bit6, [lcd_data+1]
	oim bit2, [lcd_data+2]
	cim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	cim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_3:
	oim bit6, [lcd_data+1]
	oim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	cim bit7, [lcd_data+2]
	cim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_4:
	cim bit6, [lcd_data+1]
	oim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	cim bit3, [lcd_data+1]
	cim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_5:
	oim bit6, [lcd_data+1]
	cim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	cim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_6:
	oim bit6, [lcd_data+1]
	cim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_7:
	oim bit6, [lcd_data+1]
	oim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	cim bit3, [lcd_data+1]
	cim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	cim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_8:
	oim bit6, [lcd_data+1]
	oim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_9:
	oim bit6, [lcd_data+1]
	oim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	cim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_A:
	oim bit6, [lcd_data+1]
	oim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	cim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_G:
	oim bit6, [lcd_data+1]
	cim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	cim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_r:
	cim bit6, [lcd_data+1]
	cim bit2, [lcd_data+2]
	cim bit2, [lcd_data+1]
	cim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	cim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_C:
	oim bit6, [lcd_data+1]
	cim bit2, [lcd_data+2]
	cim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	cim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_E:
	oim bit6, [lcd_data+1]
	cim bit2, [lcd_data+2]
	cim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_n:
	cim bit6, [lcd_data+1]
	cim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	cim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	cim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_h:
	cim bit6, [lcd_data+1]
	cim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	cim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_d:
	cim bit6, [lcd_data+1]
	oim bit2, [lcd_data+2]
	oim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	cim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_t:
	cim bit6, [lcd_data+1]
	cim bit2, [lcd_data+2]
	cim bit2, [lcd_data+1]
	oim bit3, [lcd_data+1]
	oim bit7, [lcd_data+2]
	oim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_dash:
	cim bit6, [lcd_data+1]
	cim bit2, [lcd_data+2]
	cim bit2, [lcd_data+1]
	cim bit3, [lcd_data+1]
	cim bit7, [lcd_data+2]
	cim bit3, [lcd_data+2]
	oim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c1_off:
	cim bit6, [lcd_data+1]
	cim bit2, [lcd_data+2]
	cim bit2, [lcd_data+1]
	cim bit3, [lcd_data+1]
	cim bit7, [lcd_data+2]
	cim bit3, [lcd_data+2]
	cim bit6, [lcd_data+2]
	jsr update_lcd_c1
	rts


lcd_c2_0:
	oim bit1, [lcd_data+1]
	oim bit2, [lcd_data+0]
	oim bit4, [lcd_data+2]
	oim bit5, [lcd_data+2]
	oim bit1, [lcd_data+2]
	oim bit3, [lcd_data+0]
	cim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_1:
	cim bit1, [lcd_data+1]
	oim bit2, [lcd_data+0]
	oim bit4, [lcd_data+2]
	cim bit5, [lcd_data+2]
	cim bit1, [lcd_data+2]
	cim bit3, [lcd_data+0]
	cim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_2:
	oim bit1, [lcd_data+1]
	oim bit2, [lcd_data+0]
	cim bit4, [lcd_data+2]
	oim bit5, [lcd_data+2]
	oim bit1, [lcd_data+2]
	cim bit3, [lcd_data+0]
	oim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_3:
	oim bit1, [lcd_data+1]
	oim bit2, [lcd_data+0]
	oim bit4, [lcd_data+2]
	oim bit5, [lcd_data+2]
	cim bit1, [lcd_data+2]
	cim bit3, [lcd_data+0]
	oim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_4:
	cim bit1, [lcd_data+1]
	oim bit2, [lcd_data+0]
	oim bit4, [lcd_data+2]
	cim bit5, [lcd_data+2]
	cim bit1, [lcd_data+2]
	oim bit3, [lcd_data+0]
	oim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_5:
	oim bit1, [lcd_data+1]
	cim bit2, [lcd_data+0]
	oim bit4, [lcd_data+2]
	oim bit5, [lcd_data+2]
	cim bit1, [lcd_data+2]
	oim bit3, [lcd_data+0]
	oim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_6:
	oim bit1, [lcd_data+1]
	cim bit2, [lcd_data+0]
	oim bit4, [lcd_data+2]
	oim bit5, [lcd_data+2]
	oim bit1, [lcd_data+2]
	oim bit3, [lcd_data+0]
	oim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_7:
	oim bit1, [lcd_data+1]
	oim bit2, [lcd_data+0]
	oim bit4, [lcd_data+2]
	cim bit5, [lcd_data+2]
	cim bit1, [lcd_data+2]
	oim bit3, [lcd_data+0]
	cim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_8:
	oim bit1, [lcd_data+1]
	oim bit2, [lcd_data+0]
	oim bit4, [lcd_data+2]
	oim bit5, [lcd_data+2]
	oim bit1, [lcd_data+2]
	oim bit3, [lcd_data+0]
	oim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_9:
	oim bit1, [lcd_data+1]
	oim bit2, [lcd_data+0]
	oim bit4, [lcd_data+2]
	oim bit5, [lcd_data+2]
	cim bit1, [lcd_data+2]
	oim bit3, [lcd_data+0]
	oim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_P:
	oim bit1, [lcd_data+1]
	oim bit2, [lcd_data+0]
	cim bit4, [lcd_data+2]
	cim bit5, [lcd_data+2]
	oim bit1, [lcd_data+2]
	oim bit3, [lcd_data+0]
	oim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_C:
	oim bit1, [lcd_data+1]
	cim bit2, [lcd_data+0]
	cim bit4, [lcd_data+2]
	oim bit5, [lcd_data+2]
	oim bit1, [lcd_data+2]
	oim bit3, [lcd_data+0]
	cim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_n:
	cim bit1, [lcd_data+1]
	cim bit2, [lcd_data+0]
	oim bit4, [lcd_data+2]
	cim bit5, [lcd_data+2]
	oim bit1, [lcd_data+2]
	cim bit3, [lcd_data+0]
	oim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_E:
	oim bit1, [lcd_data+1]
	cim bit2, [lcd_data+0]
	cim bit4, [lcd_data+2]
	oim bit5, [lcd_data+2]
	oim bit1, [lcd_data+2]
	oim bit3, [lcd_data+0]
	oim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_dash:
	cim bit1, [lcd_data+1]
	cim bit2, [lcd_data+0]
	cim bit4, [lcd_data+2]
	cim bit5, [lcd_data+2]
	cim bit1, [lcd_data+2]
	cim bit3, [lcd_data+0]
	oim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c2_off:
	cim bit1, [lcd_data+1]
	cim bit2, [lcd_data+0]
	cim bit4, [lcd_data+2]
	cim bit5, [lcd_data+2]
	cim bit1, [lcd_data+2]
	cim bit3, [lcd_data+0]
	cim bit0, [lcd_data+2]
	jsr update_lcd_c2
	rts


lcd_c3_0:
	oim bit6, [lcd_data+4]
	oim bit4, [lcd_data+3]
	oim bit0, [lcd_data+3]
	oim bit1, [lcd_data+3]
	oim bit3, [lcd_data+3]
	oim bit5, [lcd_data+3]
	cim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_1:
	cim bit6, [lcd_data+4]
	oim bit4, [lcd_data+3]
	oim bit0, [lcd_data+3]
	cim bit1, [lcd_data+3]
	cim bit3, [lcd_data+3]
	cim bit5, [lcd_data+3]
	cim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_2:
	oim bit6, [lcd_data+4]
	oim bit4, [lcd_data+3]
	cim bit0, [lcd_data+3]
	oim bit1, [lcd_data+3]
	oim bit3, [lcd_data+3]
	cim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_3:
	oim bit6, [lcd_data+4]
	oim bit4, [lcd_data+3]
	oim bit0, [lcd_data+3]
	oim bit1, [lcd_data+3]
	cim bit3, [lcd_data+3]
	cim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_4:
	cim bit6, [lcd_data+4]
	oim bit4, [lcd_data+3]
	oim bit0, [lcd_data+3]
	cim bit1, [lcd_data+3]
	cim bit3, [lcd_data+3]
	oim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_5:
	oim bit6, [lcd_data+4]
	cim bit4, [lcd_data+3]
	oim bit0, [lcd_data+3]
	oim bit1, [lcd_data+3]
	cim bit3, [lcd_data+3]
	oim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_6:
	oim bit6, [lcd_data+4]
	cim bit4, [lcd_data+3]
	oim bit0, [lcd_data+3]
	oim bit1, [lcd_data+3]
	oim bit3, [lcd_data+3]
	oim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_7:
	oim bit6, [lcd_data+4]
	oim bit4, [lcd_data+3]
	oim bit0, [lcd_data+3]
	cim bit1, [lcd_data+3]
	cim bit3, [lcd_data+3]
	oim bit5, [lcd_data+3]
	cim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_8:
	oim bit6, [lcd_data+4]
	oim bit4, [lcd_data+3]
	oim bit0, [lcd_data+3]
	oim bit1, [lcd_data+3]
	oim bit3, [lcd_data+3]
	oim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_9:
	oim bit6, [lcd_data+4]
	oim bit4, [lcd_data+3]
	oim bit0, [lcd_data+3]
	oim bit1, [lcd_data+3]
	cim bit3, [lcd_data+3]
	oim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_P:
	oim bit6, [lcd_data+4]
	oim bit4, [lcd_data+3]
	cim bit0, [lcd_data+3]
	cim bit1, [lcd_data+3]
	oim bit3, [lcd_data+3]
	oim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_F:
	oim bit6, [lcd_data+4]
	cim bit4, [lcd_data+3]
	cim bit0, [lcd_data+3]
	cim bit1, [lcd_data+3]
	oim bit3, [lcd_data+3]
	oim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_n:
	cim bit6, [lcd_data+4]
	cim bit4, [lcd_data+3]
	oim bit0, [lcd_data+3]
	cim bit1, [lcd_data+3]
	oim bit3, [lcd_data+3]
	cim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_G:
	oim bit6, [lcd_data+4]
	cim bit4, [lcd_data+3]
	oim bit0, [lcd_data+3]
	oim bit1, [lcd_data+3]
	oim bit3, [lcd_data+3]
	oim bit5, [lcd_data+3]
	cim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_r:
	cim bit6, [lcd_data+4]
	cim bit4, [lcd_data+3]
	cim bit0, [lcd_data+3]
	cim bit1, [lcd_data+3]
	oim bit3, [lcd_data+3]
	cim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_C:
	oim bit6, [lcd_data+4]
	cim bit4, [lcd_data+3]
	cim bit0, [lcd_data+3]
	oim bit1, [lcd_data+3]
	oim bit3, [lcd_data+3]
	oim bit5, [lcd_data+3]
	cim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_dash:
	cim bit6, [lcd_data+4]
	cim bit4, [lcd_data+3]
	cim bit0, [lcd_data+3]
	cim bit1, [lcd_data+3]
	cim bit3, [lcd_data+3]
	cim bit5, [lcd_data+3]
	oim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c3_off:
	cim bit6, [lcd_data+4]
	cim bit4, [lcd_data+3]
	cim bit0, [lcd_data+3]
	cim bit1, [lcd_data+3]
	cim bit3, [lcd_data+3]
	cim bit5, [lcd_data+3]
	cim bit2, [lcd_data+3]
	jsr update_lcd_c3
	rts


lcd_c4_0:
	oim bit6, [lcd_data+5]
	oim bit4, [lcd_data+4]
	oim bit0, [lcd_data+4]
	oim bit1, [lcd_data+4]
	oim bit3, [lcd_data+4]
	oim bit5, [lcd_data+4]
	cim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_1:
	cim bit6, [lcd_data+5]
	oim bit4, [lcd_data+4]
	oim bit0, [lcd_data+4]
	cim bit1, [lcd_data+4]
	cim bit3, [lcd_data+4]
	cim bit5, [lcd_data+4]
	cim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_2:
	oim bit6, [lcd_data+5]
	oim bit4, [lcd_data+4]
	cim bit0, [lcd_data+4]
	oim bit1, [lcd_data+4]
	oim bit3, [lcd_data+4]
	cim bit5, [lcd_data+4]
	oim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_3:
	oim bit6, [lcd_data+5]
	oim bit4, [lcd_data+4]
	oim bit0, [lcd_data+4]
	oim bit1, [lcd_data+4]
	cim bit3, [lcd_data+4]
	cim bit5, [lcd_data+4]
	oim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_4:
	cim bit6, [lcd_data+5]
	oim bit4, [lcd_data+4]
	oim bit0, [lcd_data+4]
	cim bit1, [lcd_data+4]
	cim bit3, [lcd_data+4]
	oim bit5, [lcd_data+4]
	oim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_5:
	oim bit6, [lcd_data+5]
	cim bit4, [lcd_data+4]
	oim bit0, [lcd_data+4]
	oim bit1, [lcd_data+4]
	cim bit3, [lcd_data+4]
	oim bit5, [lcd_data+4]
	oim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_6:
	oim bit6, [lcd_data+5]
	cim bit4, [lcd_data+4]
	oim bit0, [lcd_data+4]
	oim bit1, [lcd_data+4]
	oim bit3, [lcd_data+4]
	oim bit5, [lcd_data+4]
	oim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_7:
	oim bit6, [lcd_data+5]
	oim bit4, [lcd_data+4]
	oim bit0, [lcd_data+4]
	cim bit1, [lcd_data+4]
	cim bit3, [lcd_data+4]
	oim bit5, [lcd_data+4]
	cim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_8:
	oim bit6, [lcd_data+5]
	oim bit4, [lcd_data+4]
	oim bit0, [lcd_data+4]
	oim bit1, [lcd_data+4]
	oim bit3, [lcd_data+4]
	oim bit5, [lcd_data+4]
	oim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_9:
	oim bit6, [lcd_data+5]
	oim bit4, [lcd_data+4]
	oim bit0, [lcd_data+4]
	oim bit1, [lcd_data+4]
	cim bit3, [lcd_data+4]
	oim bit5, [lcd_data+4]
	oim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_C:
	oim bit6, [lcd_data+5]
	cim bit4, [lcd_data+4]
	cim bit0, [lcd_data+4]
	oim bit1, [lcd_data+4]
	oim bit3, [lcd_data+4]
	oim bit5, [lcd_data+4]
	cim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_i:
	cim bit6, [lcd_data+5]
	cim bit4, [lcd_data+4]
	oim bit0, [lcd_data+4]
	cim bit1, [lcd_data+4]
	cim bit3, [lcd_data+4]
	cim bit5, [lcd_data+4]
	cim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_t:
	cim bit6, [lcd_data+5]
	cim bit4, [lcd_data+4]
	cim bit0, [lcd_data+4]
	oim bit1, [lcd_data+4]
	oim bit3, [lcd_data+4]
	oim bit5, [lcd_data+4]
	oim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_unk:
	oim bit6, [lcd_data+5]
	cim bit4, [lcd_data+4]
	cim bit0, [lcd_data+4]
	cim bit1, [lcd_data+4]
	cim bit3, [lcd_data+4]
	oim bit5, [lcd_data+4]
	cim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_r:
	cim bit6, [lcd_data+5]
	cim bit4, [lcd_data+4]
	cim bit0, [lcd_data+4]
	cim bit1, [lcd_data+4]
	oim bit3, [lcd_data+4]
	cim bit5, [lcd_data+4]
	oim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_dash:
	cim bit6, [lcd_data+5]
	cim bit4, [lcd_data+4]
	cim bit0, [lcd_data+4]
	cim bit1, [lcd_data+4]
	cim bit3, [lcd_data+4]
	cim bit5, [lcd_data+4]
	oim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c4_off:
	cim bit6, [lcd_data+5]
	cim bit4, [lcd_data+4]
	cim bit0, [lcd_data+4]
	cim bit1, [lcd_data+4]
	cim bit3, [lcd_data+4]
	cim bit5, [lcd_data+4]
	cim bit2, [lcd_data+4]
	jsr update_lcd_c4
	rts


lcd_c5_0:
	oim bit4, [lcd_data+6]
	oim bit6, [lcd_data+7]
	oim bit2, [lcd_data+6]
	oim bit3, [lcd_data+6]
	oim bit1, [lcd_data+6]
	oim bit7, [lcd_data+7]
	cim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_1:
	cim bit4, [lcd_data+6]
	oim bit6, [lcd_data+7]
	oim bit2, [lcd_data+6]
	cim bit3, [lcd_data+6]
	cim bit1, [lcd_data+6]
	cim bit7, [lcd_data+7]
	cim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_2:
	oim bit4, [lcd_data+6]
	oim bit6, [lcd_data+7]
	cim bit2, [lcd_data+6]
	oim bit3, [lcd_data+6]
	oim bit1, [lcd_data+6]
	cim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_3:
	oim bit4, [lcd_data+6]
	oim bit6, [lcd_data+7]
	oim bit2, [lcd_data+6]
	oim bit3, [lcd_data+6]
	cim bit1, [lcd_data+6]
	cim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_4:
	cim bit4, [lcd_data+6]
	oim bit6, [lcd_data+7]
	oim bit2, [lcd_data+6]
	cim bit3, [lcd_data+6]
	cim bit1, [lcd_data+6]
	oim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_5:
	oim bit4, [lcd_data+6]
	cim bit6, [lcd_data+7]
	oim bit2, [lcd_data+6]
	oim bit3, [lcd_data+6]
	cim bit1, [lcd_data+6]
	oim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_6:
	oim bit4, [lcd_data+6]
	cim bit6, [lcd_data+7]
	oim bit2, [lcd_data+6]
	oim bit3, [lcd_data+6]
	oim bit1, [lcd_data+6]
	oim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_7:
	oim bit4, [lcd_data+6]
	oim bit6, [lcd_data+7]
	oim bit2, [lcd_data+6]
	cim bit3, [lcd_data+6]
	cim bit1, [lcd_data+6]
	oim bit7, [lcd_data+7]
	cim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_8:
	oim bit4, [lcd_data+6]
	oim bit6, [lcd_data+7]
	oim bit2, [lcd_data+6]
	oim bit3, [lcd_data+6]
	oim bit1, [lcd_data+6]
	oim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_9:
	oim bit4, [lcd_data+6]
	oim bit6, [lcd_data+7]
	oim bit2, [lcd_data+6]
	oim bit3, [lcd_data+6]
	cim bit1, [lcd_data+6]
	oim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_E:
	oim bit4, [lcd_data+6]
	cim bit6, [lcd_data+7]
	cim bit2, [lcd_data+6]
	oim bit3, [lcd_data+6]
	oim bit1, [lcd_data+6]
	oim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_o:
	cim bit4, [lcd_data+6]
	cim bit6, [lcd_data+7]
	oim bit2, [lcd_data+6]
	oim bit3, [lcd_data+6]
	oim bit1, [lcd_data+6]
	cim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_n:
	cim bit4, [lcd_data+6]
	cim bit6, [lcd_data+7]
	oim bit2, [lcd_data+6]
	cim bit3, [lcd_data+6]
	oim bit1, [lcd_data+6]
	cim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_F:
	oim bit4, [lcd_data+6]
	cim bit6, [lcd_data+7]
	cim bit2, [lcd_data+6]
	cim bit3, [lcd_data+6]
	oim bit1, [lcd_data+6]
	oim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_C:
	oim bit4, [lcd_data+6]
	cim bit6, [lcd_data+7]
	cim bit2, [lcd_data+6]
	oim bit3, [lcd_data+6]
	oim bit1, [lcd_data+6]
	oim bit7, [lcd_data+7]
	cim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_deg:
	oim bit4, [lcd_data+6]
	oim bit6, [lcd_data+7]
	cim bit2, [lcd_data+6]
	cim bit3, [lcd_data+6]
	cim bit1, [lcd_data+6]
	oim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_dash:
	cim bit4, [lcd_data+6]
	cim bit6, [lcd_data+7]
	cim bit2, [lcd_data+6]
	cim bit3, [lcd_data+6]
	cim bit1, [lcd_data+6]
	cim bit7, [lcd_data+7]
	oim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c5_off:
	cim bit4, [lcd_data+6]
	cim bit6, [lcd_data+7]
	cim bit2, [lcd_data+6]
	cim bit3, [lcd_data+6]
	cim bit1, [lcd_data+6]
	cim bit7, [lcd_data+7]
	cim bit0, [lcd_data+6]
	jsr update_lcd_c5
	rts


lcd_c6_0:
	oim bit4, [lcd_data+5]
	oim bit6, [lcd_data+6]
	oim bit2, [lcd_data+5]
	oim bit3, [lcd_data+5]
	oim bit1, [lcd_data+5]
	oim bit7, [lcd_data+6]
	cim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_1:
	cim bit4, [lcd_data+5]
	oim bit6, [lcd_data+6]
	oim bit2, [lcd_data+5]
	cim bit3, [lcd_data+5]
	cim bit1, [lcd_data+5]
	cim bit7, [lcd_data+6]
	cim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_2:
	oim bit4, [lcd_data+5]
	oim bit6, [lcd_data+6]
	cim bit2, [lcd_data+5]
	oim bit3, [lcd_data+5]
	oim bit1, [lcd_data+5]
	cim bit7, [lcd_data+6]
	oim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_3:
	oim bit4, [lcd_data+5]
	oim bit6, [lcd_data+6]
	oim bit2, [lcd_data+5]
	oim bit3, [lcd_data+5]
	cim bit1, [lcd_data+5]
	cim bit7, [lcd_data+6]
	oim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_4:
	cim bit4, [lcd_data+5]
	oim bit6, [lcd_data+6]
	oim bit2, [lcd_data+5]
	cim bit3, [lcd_data+5]
	cim bit1, [lcd_data+5]
	oim bit7, [lcd_data+6]
	oim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_5:
	oim bit4, [lcd_data+5]
	cim bit6, [lcd_data+6]
	oim bit2, [lcd_data+5]
	oim bit3, [lcd_data+5]
	cim bit1, [lcd_data+5]
	oim bit7, [lcd_data+6]
	oim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_6:
	oim bit4, [lcd_data+5]
	cim bit6, [lcd_data+6]
	oim bit2, [lcd_data+5]
	oim bit3, [lcd_data+5]
	oim bit1, [lcd_data+5]
	oim bit7, [lcd_data+6]
	oim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_7:
	oim bit4, [lcd_data+5]
	oim bit6, [lcd_data+6]
	oim bit2, [lcd_data+5]
	cim bit3, [lcd_data+5]
	cim bit1, [lcd_data+5]
	oim bit7, [lcd_data+6]
	cim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_8:
	oim bit4, [lcd_data+5]
	oim bit6, [lcd_data+6]
	oim bit2, [lcd_data+5]
	oim bit3, [lcd_data+5]
	oim bit1, [lcd_data+5]
	oim bit7, [lcd_data+6]
	oim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_9:
	oim bit4, [lcd_data+5]
	oim bit6, [lcd_data+6]
	oim bit2, [lcd_data+5]
	oim bit3, [lcd_data+5]
	cim bit1, [lcd_data+5]
	oim bit7, [lcd_data+6]
	oim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_C:
	oim bit4, [lcd_data+5]
	cim bit6, [lcd_data+6]
	cim bit2, [lcd_data+5]
	oim bit3, [lcd_data+5]
	oim bit1, [lcd_data+5]
	oim bit7, [lcd_data+6]
	cim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_r:
	cim bit4, [lcd_data+5]
	cim bit6, [lcd_data+6]
	cim bit2, [lcd_data+5]
	cim bit3, [lcd_data+5]
	oim bit1, [lcd_data+5]
	cim bit7, [lcd_data+6]
	oim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_n:
	cim bit4, [lcd_data+5]
	cim bit6, [lcd_data+6]
	oim bit2, [lcd_data+5]
	cim bit3, [lcd_data+5]
	oim bit1, [lcd_data+5]
	cim bit7, [lcd_data+6]
	oim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_F:
	oim bit4, [lcd_data+5]
	cim bit6, [lcd_data+6]
	cim bit2, [lcd_data+5]
	cim bit3, [lcd_data+5]
	oim bit1, [lcd_data+5]
	oim bit7, [lcd_data+6]
	oim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_dash:
    cim bit4, [lcd_data+5]
	cim bit6, [lcd_data+6]
	cim bit2, [lcd_data+5]
	cim bit3, [lcd_data+5]
	cim bit1, [lcd_data+5]
	cim bit7, [lcd_data+6]
	oim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


lcd_c6_off:
	cim bit4, [lcd_data+5]
	cim bit6, [lcd_data+6]
	cim bit2, [lcd_data+5]
	cim bit3, [lcd_data+5]
	cim bit1, [lcd_data+5]
	cim bit7, [lcd_data+6]
	cim bit0, [lcd_data+5]
	jsr update_lcd_c6
	rts


update_lcd_c0:
    lcd_send_char 0
    lcd_send_char 1
    lcd_send_char 3
	rts


update_lcd_c1:
    lcd_send_char 1
    lcd_send_char 2
	rts


update_lcd_c2:
    lcd_send_char 0
    lcd_send_char 1
    lcd_send_char 2
	rts


update_lcd_c3:
    lcd_send_char 3
    lcd_send_char 4
	rts


update_lcd_c4:
    lcd_send_char 4
    lcd_send_char 5
	rts


update_lcd_c5:
    lcd_send_char 6
    lcd_send_char 7
	rts


update_lcd_c6:
    lcd_send_char 5
    lcd_send_char 6
	rts


lcd_wait:  ;sleeps 200 cycles and then reads from lcd? (206/211 cycles(ret))
	lda A, 0x32  ;2
.waitloop:
	dec A  ;1
	bne .waitloop  ;3
	lda A, [LCD_CONTROLLER]  ;4
	rts  ;5


send_lcd_data:  ;writes to LCD controller
;  ;a has 0b00 -> display data 5 bit addr
;  ;b has data
;  ;a has 0b01 -> bit manipulation. com addr 10 display 5
;  ;b has seg addr
;  ;a has 0b10 mode setting
;  ;a has 0b11 
	sta A, [LCD_CONTROLLER]
	sta B, [LCD_CONTROLLER]
	rts


trap:
nmi:
swi:
irq1:
irq2:
ici:
sio:
	cli
	rti



#addr 0xffea
interrupt_vector:
#d16 irq2
#d16 cmi
#d16 trap
#d16 sio
#d16 toi
#d16 oci
#d16 ici
#d16 irq1
#d16 swi
#d16 nmi
#d16 reset

