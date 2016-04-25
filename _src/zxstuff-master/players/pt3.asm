        ifndef _pt3_asm_defined
        define _pt3_asm_defined

        module PT3
        
        struct Header
Id      ds 13 ; usually 'Protracker 3.'
Subversion
        db 0
Description
        ds 84 ; usually ' compilation of ' + Name[32] + ' by ' + Author[32]
Mode    db 0
FreqTable
        db 0  ;assume 0..04
Tempo   db 0  ;01-ff
Length  db 0
Loop    db 0
Patterns
        dw 0  ;? 00-01
Samples 
        ds 64  ;(? 00-bf}{32}
Ornaments
        ds 32  ;(? 00-d9){16}
Positions
        db 0  ;*3&00-fe
        db 0  ;*3|ff       
        ends
        
Start
        ifndef NoPrologue
        ld hl,End
        jr Init
        jp PTS.PLAY
        jp PTS.MUTE
        endif

Init    ld a,PTS.SETUP.TSPT3
        jp PTS.INIT

        ifdef HaveFormatCheck
        include "format.asm"
        
;in HL - module addr
;out Z - is pt3
CheckFormat
        ; meta
        AnyBytes Header.FreqTable
        ;FreqTable
        LessOrEqual 4
        ;Tempo
        Greater 1
        ;Length
        AnyByte
        ;Loop
        AnyByte
        ;Patterns
        AnyByte
        LessOrEqual 1
        ;Samples
        ld b,(Header.Ornaments-Header.Samples)/2
.samples
        AnyByte
        LessOrEqual #bf
        djnz .samples
        ;Ornaments
        ld b,(Header.Positions-Header.Ornaments)/2
.ornaments
        AnyByte
        LessOrEqual #d9
        djnz .ornaments
        ;Positions
        ;255 at first position is denied
        LessOrEqual 254
        ld b,0
        dec hl
.positions
        ld a,(hl)
        inc hl
        cp 255
        ret z ;finish
        ;check is multiple of 3
.div3   and a
        jr z,.posok
        sub 3
        ret c
        jr nz,.div3
.posok  djnz .positions
        ;fall through
.fail   ld a,h
        and a ;reset Z
        ret
        
        display "PT3 checker size: ",$-CheckFormat
        endif
        
        endmod

        include "PTSPlay.asm"
PT3.Play=PTS.PLAY
PT3.Mute=PTS.MUTE        
PT3.End

        display "PT3 module size: ",PT3.End-PT3.Start

        endif
        