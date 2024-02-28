
bit0 = 0x1`8
bit1 = 0x2`8
bit2 = 0x4`8
bit3 = 0x8`8
bit4 = 0x10`8
bit5 = 0x20`8
bit6 = 0x40`8
bit7 = 0x80`8

#bankdef INTREGS
{
    #addr 0x0000
    #size 0x20
}
#bank INTREGS
#addr 0x01
P2_DIR: #res 1
#addr 0x03
P2: #res 1
#addr 0x08
TCSR1: #res 1
FRC:
FRCH: #res 1
FRCL: #res 1
OCR1:
OCR1H: #res 1
OCR1L: #res 1
ICR:
ICRH: #res 1
ICRL: #res 1
TCSR2: #res 1
SCI_RMCR: #res 1
SCI_TRCSR: #res 1
SCI_RDR: #res 1
SCI_TDR: #res 1

RAM_CTRL:
P5_CTRL: #res 1
P5: #res 1
P6_DIR: #res 1
P6: #res 1
#addr 0x19
OCR2:
OCR2H: #res 1
OCR2L: #res 1
TCSR3: #res 1
TCONR: #res 1
T2CNT: #res 1

;tcsr1
;0: OLV1 - output to p2_1
;1: IEDG - input edge p2_0
;2: ETOI - enable timer interrupt
;3: EOCI1 - enable output compare interrupt
;4  EICI - enable input capture interrupt
;5: overflow 
;6: match
;7: icr

#subruledef gpio {
    TONE_SIG => bit0 @ P2`8
    TONEH => bit1 @ P2`8
    MIC_OFF => bit2 @ P2`8
    RDATA => bit3 @ P2`8
    TDATA => bit4 @ P2`8
    TONEL => bit5 @ P2`8
    ALARM => bit6 @ P2`8
    BUSY_IND => bit7 @ P2`8
    ;port5
    PROG_CONT => bit0 @ P5`8
    MON => bit1 @ P5`8
    BAT_CHECK => bit2 @ P5`8
    PTT => bit3 @ P5`8
    CHSEL0 => bit4 @ P5`8
    CHSEL1 => bit5 @ P5`8
    CHSEL2 => bit6 @ P5`8
    CHSEL3 => bit7 @ P5`8
    ;port6
    CSA => bit0 @ P6`8
    CLX => bit1 @ P6`8
    DI => bit2 @ P6`8
    DO => bit3 @ P6`8
    CTCSS_L => bit4 @ P6`8
    CTCSS_H => bit5 @ P6`8
    BUSY => bit6 @ P6`8
    TSQ => bit7 @ P6`8 ;??
}

#ruledef {
    gpio_on {v:gpio} => 0x72@v
    gpio_off {v:gpio} => 0x71@(v^0xff00)`16
    gpio_test {v: gpio} => 0x7b@v
}
; TONE_SIG = P20
; TONEH = P21
; RDATA = P22
; TDATA = P23
; TONEL = P24
; ALARM = P26
; ; "BUSY" = P27 ;controls busy ind

; PROG_CONT = P50
; MON = P51
; BAT_CHECK = P52
; PTT = P53
; CHSEL0 = P54
; CHSEL1 = P55
; CHSEL2 = P56
; CHSEL3 = P57

; CSA = P60
; CLX = P61
; DI = P62
; DO = P63
; CTCSS_L = P64
; CTCSS_H = P65
; BUSY = P66
; TSQ = F67

#bankdef RAM
{
    #addr 0x40
    #size 192
}


#bankdef PERIPH1
{
    #addr 0x2000
    #size 0x1000
}
#bankdef PERIPH2
{
    #addr 0x4000
    #size 0x1000
}
#bankdef PERIPH3
{
    #addr 0x6000
    #size 0x1000
}
;PA0-7 is bootleg dac
;PB0-3 OPC-OPE
;PB3-5 PLLD, C, E
;HM
;??
;PC 4-7 for "SC"


#bank PERIPH1
LCD_CONTROLLER:#res 1


#ruledef {
    lcd_mode {a}, {b} => {
        asm {
            jsr lcd_wait
            lda A, 0x80|a
            lda B, b
            jsr send_lcd_data
        }
    }
    lcd_send_char {x} => asm {
        jsr lcd_wait
        lda A, x
        lda.ext B, [lcd_data+x]
        jsr send_lcd_data
    }
    lcd_on => asm {
        lcd_mode 0x9, 0x5 ;ext power 1/2 duty cycle, 1/2 duty cycle on
    }
    lcd_off => asm {
        lcd_mode 0x9, 0x1
    }
    lcd_seg_on {a}, {b} => asm {
        jsr lcd_wait
        lda A, 0x60|a
        lda B, b
        jsr send_lcd_data
    }
    lcd_seg_off {a}, {b} => asm {
        jsr lcd_wait
        lda A, 0x40|a
        lda B, b
        jsr send_lcd_data
    }
}

;up to seg29, 2 comm = 60 segments
;memory looks like
; 7 6 
; 5 4 c1_f c1_b
; 3 2 
; 1 0 c1_e c1_g
; 7 6 
; 5 4 c1_d c1_c
; 3 2 
; 1 0 
; 7 6 ? c1_a
; 5 4 
; 3 2 
; 1 0 

#bank PERIPH2
PERIPH2:
.PORTA:#res 1
.PORTB:#res 1
.PORTC:#res 1
.CTRL:#res 1

#bank PERIPH3
PERIPH3:
.PORTA:#res 1
.PORTB:#res 1
.PORTC:#res 1
.CTRL:#res 1


#bankdef EEPROM
{
    #addr 0x8000
    #size 0x8000
    #outp 0x0
    #fill
}


#bank EEPROM