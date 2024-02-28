
#bits 8

#subruledef rel
{
    {imm: u16} => {
        addr = (imm - (pc + 2))
        assert(addr <= 0x7f)
        assert(addr >= !0x7f)
        addr`8
    }
}
#subruledef idx
{
    X[{imm: i8}] => imm
    [X+{imm: i8}] => imm
    [{imm: i8}+X] => imm
    [X] => 0`8
}
#subruledef dir
{
    [{imm:i8}] => imm
}
#subruledef ext
{
    [{imm:i16}] => imm
}

#ruledef
{
	nop     => 0x01 
	tap     => 0x06 
	tpa     => 0x07 
	inx     => 0x08 
	dex     => 0x09 
	clv     => 0x0a 
	sev     => 0x0b 
	clc     => 0x0c 
	sec     => 0x0d 
	cli     => 0x0e 
	sei     => 0x0f 
	sba     => 0x10 
	cba     => 0x11 
	tab     => 0x16 
	tba     => 0x17 
	daa     => 0x19 
	aba     => 0x1b 
	tsx     => 0x30 
	ins     => 0x31 
	pul A   => 0x32 
	pul B   => 0x33 
	des     => 0x34 
	txs     => 0x35 
	psh A   => 0x36 
	psh B   => 0x37 
	wai     => 0x3e 
	swi     => 0x3f 
    rts     => 0x39
    rti     => 0x3b
    xgdx    => 0x18
    slp     => 0x1a
    lsrd    => 0x04
    asld    => 0x05
    abx     => 0x3a
    mul     => 0x3d
    bra {r: rel}   => 0x20 @ r
    brn {r: rel}   => 0x21 @ r
    bhi {r: rel}   => 0x22 @ r
    bls {r: rel}   => 0x23 @ r
    bcc {r: rel}   => 0x24 @ r
    bcs {r: rel}   => 0x25 @ r
    bne {r: rel}   => 0x26 @ r
    beq {r: rel}   => 0x27 @ r
    bvc {r: rel}   => 0x28 @ r
    bvs {r: rel}   => 0x29 @ r
    bpl {r: rel}   => 0x2a @ r
    bmi {r: rel}   => 0x2b @ r
    bge {r: rel}   => 0x2c @ r
    blt {r: rel}   => 0x2d @ r
    bgt {r: rel}   => 0x2e @ r
    ble {r: rel}   => 0x2f @ r
    bsr {r: rel}   => 0x8d @ r

    subd {v: i16} => 0x83 @ v
    subd {v: dir} => 0x93 @ v
    subd {v: idx} => 0xa3 @ v
    subd {v: ext} => 0xb3 @ v
    subd.ext {v: ext} => 0xb3 @ v
    addd {v: i16} => 0xc3 @ v
    addd {v: dir} => 0xd3 @ v
    addd {v: idx} => 0xe3 @ v
    addd {v: ext} => 0xf3 @ v
    addd.ext {v: ext} => 0xf3 @ v

    jsr {v: idx} => 0xad @ v
    jsr {v: u16} => 0xbd @ v
    jmp {v: idx} => 0x6e @ v
    jmp {v: u16} => 0x7e @ v
    

    aim {v: u8}, {v2: idx} => 0x61 @ v @ v2
    aim {v: u8}, {v2: dir} => 0x71 @ v @ v2
    oim {v: u8}, {v2: idx} => 0x62 @ v @ v2
    oim {v: u8}, {v2: dir} => 0x72 @ v @ v2
    eim {v: u8}, {v2: idx} => 0x65 @ v @ v2
    eim {v: u8}, {v2: dir} => 0x75 @ v @ v2
    tim {v: u8}, {v2: idx} => 0x6b @ v @ v2
    tim {v: u8}, {v2: dir} => 0x7b @ v @ v2

    cim {v: u8}, {v2: dir} => 0x71 @ (!v)`8 @ v2
    cim {v: u8}, {v2: idx} => 0x61 @ (!v)`8 @ v2

    neg A        => 0x40
    neg B        => 0x50
    neg {v: idx} => 0x60 @ v
    neg {v: ext} => 0x70 @ v
    
    com A        => 0x43
    com B        => 0x53
    com {v: idx} => 0x63 @ v
    com {v: ext} => 0x73 @ v
    
    lsr A        => 0x44
    lsr B        => 0x54
    lsr {v: idx} => 0x64 @ v
    lsr {v: ext} => 0x74 @ v
    
    ror A        => 0x46
    ror B        => 0x56
    ror {v: idx} => 0x66 @ v
    ror {v: ext} => 0x76 @ v
    
    asr A        => 0x47
    asr B        => 0x57
    asr {v: idx} => 0x67 @ v
    asr {v: ext} => 0x77 @ v
    
    asl A        => 0x48
    asl B        => 0x58
    asl {v: idx} => 0x68 @ v
    asl {v: ext} => 0x78 @ v
    
    rol A        => 0x49
    rol B        => 0x59
    rol {v: idx} => 0x69 @ v
    rol {v: ext} => 0x79 @ v
    
    dec A        => 0x4A
    dec B        => 0x5A
    dec {v: idx} => 0x6A @ v
    dec {v: ext} => 0x7A @ v
    
    inc A        => 0x4C
    inc B        => 0x5C
    inc {v: idx} => 0x6C @ v
    inc {v: ext} => 0x7C @ v

    tst A        => 0x4d
    tst B        => 0x5d
    tst {v: idx} => 0x6d @ v
    tst {v: ext} => 0x7d @ v
    
    clr A        => 0x4F
    clr B        => 0x5F
    clr {v: idx} => 0x6F @ v
    clr {v: ext} => 0x7F @ v
    

    sub A, {v: i8}  => 0x80 @ v
    sub A, {v: dir} => 0x90 @ v
    sub A, {v: idx} => 0xA0 @ v
    sub A, {v: ext} => 0xB0 @ v
    sub B, {v: i8}  => 0xC0 @ v
    sub B, {v: dir} => 0xD0 @ v
    sub B, {v: idx} => 0xE0 @ v
    sub B, {v: ext} => 0xF0 @ v
    
    cmp A, {v: i8}  => 0x81 @ v
    cmp A, {v: dir} => 0x91 @ v
    cmp A, {v: idx} => 0xA1 @ v
    cmp A, {v: ext} => 0xB1 @ v
    cmp.ext A, {v: ext} => 0xB1 @ v
    cmp B, {v: i8}  => 0xC1 @ v
    cmp B, {v: dir} => 0xD1 @ v
    cmp B, {v: idx} => 0xE1 @ v
    cmp B, {v: ext} => 0xF1 @ v
    cmp.ext B, {v: ext} => 0xF1 @ v
    
    sbc A, {v: i8}  => 0x82 @ v
    sbc A, {v: dir} => 0x92 @ v
    sbc A, {v: idx} => 0xA2 @ v
    sbc A, {v: ext} => 0xB2 @ v
    sbc.ext A, {v: ext} => 0xB2 @ v
    sbc B, {v: i8}  => 0xC2 @ v
    sbc B, {v: dir} => 0xD2 @ v
    sbc B, {v: idx} => 0xE2 @ v
    sbc B, {v: ext} => 0xF2 @ v
    sbc.ext B, {v: ext} => 0xF2 @ v
    
    and A, {v: i8}  => 0x84 @ v
    and A, {v: dir} => 0x94 @ v
    and A, {v: idx} => 0xA4 @ v
    and A, {v: ext} => 0xB4 @ v
    and B, {v: i8}  => 0xC4 @ v
    and B, {v: dir} => 0xD4 @ v
    and B, {v: idx} => 0xE4 @ v
    and B, {v: ext} => 0xF4 @ v
    
    bit A, {v: i8}  => 0x85 @ v
    bit A, {v: dir} => 0x95 @ v
    bit A, {v: idx} => 0xA5 @ v
    bit A, {v: ext} => 0xB5 @ v
    bit B, {v: i8}  => 0xC5 @ v
    bit B, {v: dir} => 0xD5 @ v
    bit B, {v: idx} => 0xE5 @ v
    bit B, {v: ext} => 0xF5 @ v
    
    lda A, {v: i8}  => 0x86 @ v
    lda A, {v: dir} => 0x96 @ v
    lda A, {v: idx} => 0xA6 @ v
    lda A, {v: ext} => 0xB6 @ v
    lda.ext A, {v: ext} => 0xB6 @ v
    lda B, {v: i8}  => 0xC6 @ v
    lda B, {v: dir} => 0xD6 @ v
    lda B, {v: idx} => 0xE6 @ v
    lda B, {v: ext} => 0xF6 @ v
    lda.ext B, {v: ext} => 0xF6 @ v
    
    sta A, {v: dir} => 0x97 @ v
    sta A, {v: idx} => 0xA7 @ v
    sta A, {v: ext} => 0xB7 @ v
    sta.ext A, {v: ext} => 0xB7 @ v
    sta B, {v: dir} => 0xD7 @ v
    sta B, {v: idx} => 0xE7 @ v
    sta B, {v: ext} => 0xF7 @ v
    sta.ext B, {v: ext} => 0xF7 @ v

    
    eor A, {v: i8}  => 0x88 @ v
    eor A, {v: dir} => 0x98 @ v
    eor A, {v: idx} => 0xA8 @ v
    eor A, {v: ext} => 0xB8 @ v
    eor B, {v: i8}  => 0xC8 @ v
    eor B, {v: dir} => 0xD8 @ v
    eor B, {v: idx} => 0xE8 @ v
    eor B, {v: ext} => 0xF8 @ v
    
    adc A, {v: i8}  => 0x89 @ v
    adc A, {v: dir} => 0x99 @ v
    adc A, {v: idx} => 0xA9 @ v
    adc A, {v: ext} => 0xB9 @ v
    adc.ext A, {v: ext} => 0xB9 @ v
    adc B, {v: i8}  => 0xC9 @ v
    adc B, {v: dir} => 0xD9 @ v
    adc B, {v: idx} => 0xE9 @ v
    adc B, {v: ext} => 0xF9 @ v
    adc.ext B, {v: ext} => 0xF9 @ v

    ora A, {v: i8}  => 0x8a @ v
    ora A, {v: dir} => 0x9a @ v
    ora A, {v: idx} => 0xAa @ v
    ora A, {v: ext} => 0xBa @ v
    ora.ext A, {v: ext} => 0xBa @ v
    ora B, {v: i8}  => 0xCa @ v
    ora B, {v: dir} => 0xDa @ v
    ora B, {v: idx} => 0xEa @ v
    ora B, {v: ext} => 0xFa @ v
    ora.ext B, {v: ext} => 0xFa @ v
    
    add A, {v: i8}  => 0x8b @ v
    add A, {v: dir} => 0x9b @ v
    add A, {v: idx} => 0xAb @ v
    add A, {v: ext} => 0xBb @ v
    add.ext A, {v: ext} => 0xBb @ v
    add B, {v: i8}  => 0xCb @ v
    add B, {v: dir} => 0xDb @ v
    add B, {v: idx} => 0xEb @ v
    add B, {v: ext} => 0xFb @ v
    add.ext B, {v: ext} => 0xFb @ v
    
    cpx {v: i16}  => 0x8c @ v
    cpx {v: dir} => 0x9c @ v
    cpx {v: idx} => 0xAc @ v
    cpx {v: ext} => 0xBc @ v
    cpx.ext {v: ext} => 0xBc @ v
    ldd {v: i16}  => 0xCc @ v
    ldd {v: dir} => 0xDc @ v
    ldd {v: idx} => 0xEc @ v
    ldd {v: ext} => 0xFc @ v
    ldd.ext {v: ext} => 0xFc @ v
    
    lds {v: i16}  => 0x8e @ v
    lds {v: dir} => 0x9e @ v
    lds {v: idx} => 0xAe @ v
    lds {v: ext} => 0xBe @ v
    ldx {v: i16}  => 0xCe @ v
    ldx {v: dir} => 0xDe @ v
    ldx {v: idx} => 0xEe @ v
    ldx {v: ext} => 0xFe @ v
    ldx.ext {v: ext} => 0xFe @ v

    std {v: dir} => 0xdd @ v
    std {v: idx} => 0xed @ v
    std {v: ext} => 0xfd @ v
    std.ext {v: ext} => 0xfd @ v
    
    sts {v: dir} => 0x9f @ v
    sts {v: idx} => 0xAf @ v
    sts {v: ext} => 0xBf @ v
    stx {v: dir} => 0xDf @ v
    stx {v: idx} => 0xEf @ v
    stx {v: ext} => 0xFf @ v
    stx.ext {v: ext} => 0xFf @ v

}