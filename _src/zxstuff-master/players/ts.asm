      ifndef _ts_asm_defined
      define _ts_asm_defined
      
      module TS
      
      struct Footer
Sign1 DS 4
Size1 DW 0
Sign2 DS 4
Size2 DW 0
Sign3 DS 4      
      ENDS

Start      
        ifndef NoPrologue
        ld hl,End
        jr .init
        jp PTS.PLAY
        jp PTS.MUTE
.init   call CheckFormat
        ;ignore invalids
        endif

Init    ld a,PTS.SETUP.TS02
        jp PTS.INIT

;in HL - module addr
;out Z - is ts
;out HL/DE modules offsets (valid only if Z)
CheckFormat
        ld d,h,e,l
        inc d ;skip 256 bytes
.findfooter
        ld h,d,l,e
        call CheckFooter
        ret z
        inc e
        jr nz,.findfooter
        inc d
        jr nz,.findfooter
        inc e ;reset Z
        ;hl/de are invalid!!!
        ret

;in HL - module addr
;in BC - module size
;out Z - is ts
;out HL/DE - modules offsets (valid only if Z)
        ifdef HaveFormatCheck
CheckFormatKnownSize
        add hl,bc
        endif
CheckFooter
        dec hl
        ld a,(hl)
        cp "S"
        ret nz
        dec hl
        ld a,(hl)
        cp "T"
        ret nz
        dec hl
        ld a,(hl)
        cp "2"
        ret nz
        dec hl
        ld a,(hl)
        cp "0"
        ret nz
        dec hl
        ld d,(hl)
        dec hl
        ld e,(hl) ;Size2
        dec hl,hl,hl,hl;skip Sign2
        dec hl
        ld b,(hl)
        dec hl
        ld c,(hl) ;Size1
        dec hl,hl,hl,hl;skip Sign1

        sbc hl,de
        ld d,h
        ld e,l
        sbc hl,bc
        xor a
        ret

        ifdef HaveFormatCheck
        display "TS checker size: ",$-CheckFormat
        endif

        endmod

        include "PTSPlay.asm"

TS.End    
TS.Play=PTS.PLAY
TS.Mute=PTS.MUTE        

        display "TS module size: ",TS.End-TS.Start

        endif
