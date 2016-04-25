;some format checking macros
        ifndef _format_asm_defined
        define _format_asm_defined

        macro LessOrEqual number
        ld a,number
        cp (hl)
        inc hl
        ret c
        endm
        
        macro Greater number
        ld a,(hl)
        inc hl
        cp number
        ret c
        endm
        
        macro AnyByte
        inc hl
        endm
        
        macro AnyBytes count
        if count > 7
        ld a,l
        add a,count
        ld l,a
        adc a,h
        sub l
        ld h,a
        else
        dup count
        inc hl
        edup
        endif
        endm
        
        macro EqualTo number
        ld a,number
        cp (hl)
        inc hl
        ret nz
        endm

        endif
