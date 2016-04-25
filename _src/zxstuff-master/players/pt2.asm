        ifndef _pt2_asm_defined
        define _pt2_asm_defined
        
        module PT2

        struct Header
Tempo   db 0 ;02-ff
Length  db 0 ;01-ff
Loop    db 0 ;00-fe
Samples 
        ds 64 ;(? 00-36){32}
Ornaments
        ds 32 ;(? 00-36){16}
Patterns
        dw 0 ;? 00-01
Name    ds 30 ;?
Positions
        db 0  ;00-1f
        db 0  ;ff|00-1f             
        ends
        
Start
        ifndef NoPrologue
        ld hl,End
        jr Init
        jp PTS.PLAY
        jp PTS.MUTE
        endif

Init    ld a,PTS.SETUP.PT2
        jp PTS.INIT
        
        ifdef HaveFormatCheck
        include "format.asm"
        
;in HL - module addr
;out Z - is pt2
CheckFormat
        ;Tempo
        Greater 2
        ;Length
        Greater 1
        ;Loop
        LessOrEqual 254
        ;Samples+Ornaments
        ld b,(Header.Patterns-Header.Samples)/2
.samorns
        AnyByte
        LessOrEqual #36
        djnz .samorns
        ;Patterns
        AnyByte
        LessOrEqual 1
        ;Name
        AnyBytes Header.Positions-Header.Name
        ;Positions
        ;first should be not marker
        LessOrEqual #1f
        ld b,255 ;max positions
.positions
        ld a,(hl)
        cp 255
        ret z ;finish
        LessOrEqual #1f
        djnz .positions
        ;fall through
.fail   ld a,h
        and a ;reset Z
        ret

        display "PT2 checker size: ",$-CheckFormat
        endif
        
        endmod
        
        include "PTSPlay.asm"

PT2.Play=PTS.PLAY
PT2.Mute=PTS.MUTE        
PT2.End

        display "PT2 module size: ",PT2.End-PT2.Start
        endif
       