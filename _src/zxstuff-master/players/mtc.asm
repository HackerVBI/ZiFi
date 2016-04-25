        ifndef _mtc_asm_defined
        define _mtc_asm_defined
        
        module MTC

        ;enum-like
        struct StreamType
PT3     db 0
PT2     db 0
TS      db 0        
TFC     db 0
Unknown db 0
        ends
        
        struct StreamData
Type    db 0
Data1   dw 0        
Data2   dw 0
Init    dw 0
Play    dw 0
Mute    dw 0
        ends
        
Start        
        ifndef NoPrologue
        ld hl,End
        jr Init
        jp Play
        jp Mute
        endif

        ifdef HaveFormatCheck
        
        include "format.asm"
        
;in HL - module addr
;out Z - is mtc
CheckFormat
        EqualTo "M"
        EqualTo "T"
        EqualTo "C"
        EqualTo "1"
        EqualTo 0
        EqualTo 0
        ret
        
        display "MTC checker size: ",$-CheckFormat

        endif

;in HL - module addr
Init    ld ix,Streams
        ld (ix+StreamData.Type),StreamType.Unknown
        call ParseChunk
        cp ChunkId.MTC1
        call z,ParseMTC1
        call MergeStreams
        ld ix,Streams
.initstreams
        ld a,(ix+StreamData.Type)
        cp StreamType.Unknown
        ret z
        ld l,(ix+StreamData.Data1)
        ld h,(ix+StreamData.Data1+1)
        ld e,(ix+StreamData.Data2)
        ld d,(ix+StreamData.Data2+1)
        ld c,(ix+StreamData.Init)
        ld b,(ix+StreamData.Init+1)
        push ix
        call jp_bc
        pop ix
        ld bc,StreamData
        add ix,bc
        jr .initstreams
        
Play    ld ix,Streams
.playstreams        
        ld a,(ix+StreamData.Type)
        cp StreamType.Unknown
        ret z
        ld c,(ix+StreamData.Play)
        ld b,(ix+StreamData.Play+1)
        push ix
        call jp_bc
        pop ix
        ld bc,StreamData
        add ix,bc
        jr .playstreams

Mute    ld ix,Streams
.mutestreams        
        ld a,(ix+StreamData.Type)
        cp StreamType.Unknown
        ret z
        ld c,(ix+StreamData.Mute)
        ld b,(ix+StreamData.Mute+1)
        push ix
        call jp_bc
        pop ix
        ld bc,StreamData
        add ix,bc
        jr .mutestreams

jp_bc   push bc
        ret

;in hl - chunk start
;out a - chunkid
;out hl - chunk data start
;out bc - chunk data size
;corrupt de
ParseChunk
        ld de,ChunkId
.checkid
        ld b,4
        dup 4
        ld a,(de)
        inc e
        cp (hl)
        inc hl
        jr nz,$+3
        dec b
        edup
        ;nz if last byte is not matched
        ;nz if b != 0 (not all bytes matched)
        ld a,e
        jr z,.matched
        cp ChunkId.Unknown
        jr z,.getdata
        dec hl,hl,hl,hl
        jr .checkid
.matched
        sub 4
.getdata
        ;skip higher bytes of size, assume they are zero
        inc hl
        inc hl        
        ld b,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ret

;put streams in gap
Streams 
MinStreamsCount=3 ;approx: ts+tfm
        ds MinStreamsCount*StreamData ;approx
Streams.End
        display "MTC: loosed ",256-low $," bytes"
        align 256

ChunkId
.MTC1=low $
        db "MTC1"
.TRCK=low $
        db "TRCK"
.DATA=low $
        db "DATA"
.NAME=low $
        db "NAME"
.AUTH=low $
        db "AUTH"
.ANNO=low $
        db "ANNO"
.PROP=low $
        db "PROP"
.Unknown=low $

MaxStreamsCount=(ChunkId-Streams)/StreamData
        display "MTC: max streams ",MaxStreamsCount

        macro MoveNextChunk
        ;chunk is always aligned at word boundary, so correct odd length
        push bc
        pop af
        adc hl,bc
        endm
        
;in hl - content
;in bc - size
ParseMTC1
        push hl
        add hl,bc
        ex (sp),hl
        ; (sp) - end of avail data
.nextchunk        
        call ParseChunk
        push hl,bc
        cp ChunkId.TRCK
        call z,ParseTrack
        pop bc,hl
        MoveNextChunk
        pop bc
        ;hl- end of chunk
        ;de- end of avail
        sbc hl,bc
        ret z ;last chunk
        add hl,bc
        push bc
        jr .nextchunk

;in hl - content
;in bc - size        
ParseTrack        
        push hl
        add hl,bc
        ex (sp),hl
        ; (sp) - end of avail data
.nextchunk        
        call ParseChunk
        push hl,bc
        cp ChunkId.DATA
        call z,ParseData
        exa
        pop bc,hl
        MoveNextChunk
        pop bc
        exa
        ret z ;data is parsed
        ;hl- end of chunk
        ;de- end of avail
        and a
        sbc hl,bc
        ret z ;last chunk
        add hl,bc
        push bc
        jr .nextchunk
        
;in hl - content
;in bc - size        
;out Z - data parsed and added as stream
ParseData
        call ParseTFC
        call nz,ParseTS
        call nz,ParsePT2
        jr nz,ParsePT3
        ret
        
ParseTFC
        push hl,bc
        call TFC.CheckFormat
        pop bc,hl
        ret nz
        ld a,StreamType.TFC
        exx
        ld hl,TFC.Init
        ld de,TFC.Play
        ld bc,TFC.Mute
        call FillStream
AddStream        
        ld bc,StreamData
        add ix,bc
        ld (ix+StreamData.Type),StreamType.Unknown
        xor a;set Z
        ret
        
ParseTS
        push hl,bc
        call TS.CheckFormatKnownSize
        pop bc,hl
        ret nz
        call FillTS
        jr AddStream
        
ParsePT2
        push hl,bc
        call PT2.CheckFormat
        pop bc,hl
        ret nz
        ld a,StreamType.PT2
        exx
        ld hl,PT2.Init
        call FillPts
        jr AddStream

ParsePT3        
        push hl,bc
        call PT3.CheckFormat
        pop bc,hl
        ret nz
        ld a,StreamType.PT3
        exx
        ld hl,PT3.Init
        call FillPts
        jr AddStream
        
FillTS  ld a,StreamType.TS        
        exx
        ld hl,TS.Init
FillPts ld de,PTS.PLAY
        ld bc,PTS.MUTE
FillStream
        ld (ix+StreamData.Type),a
        ld (ix+StreamData.Init),l
        ld (ix+StreamData.Init+1),h
        ld (ix+StreamData.Play),e
        ld (ix+StreamData.Play+1),d
        ld (ix+StreamData.Mute),c
        ld (ix+StreamData.Mute+1),b
        exx
        ld (ix+StreamData.Data1),l
        ld (ix+StreamData.Data1+1),h
        ld (ix+StreamData.Data2),e
        ld (ix+StreamData.Data2+1),d
        ret

;some business-logic related to supported players        
MergeStreams
        ld a,(Streams+StreamData.Type)
        cp StreamType.Unknown
        ret z ;no streams
        ld a,(Streams+StreamData+StreamData.Type)
        cp StreamType.Unknown
        ret z ;single stream

        ;sort streams according to type, use simple bubblesort
Sort
        assert 0 == ((Streams ^ Streams.End) >> 8)
        assert 0 == StreamData.Type
        ld de,Streams
        ld hl,Streams+StreamData
        ld c,0;swaps mark
.cycle        
        ld a,(de)
        cp StreamType.Unknown
        jr z,.end
        cp (hl)
        jr c,.next
        jr z,.next
        ld b,StreamData
.swapitems
        ld a,(de)        
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc l
        inc e
        djnz .swapitems
        ld c,h
        jr .cycle
.next
        ld e,l
        ld a,l
        add a,StreamData
        ld l,a        
        jr .cycle
.end
        ld a,c
        and a
        jr nz,Sort
        ;try merge streams
        ; X X merged to X (last is taken)
        ; PT3 PT3 merged to TS
Merge
        assert 0 == StreamData.Type
        ld de,Streams
        ld hl,Streams+StreamData
.cycle        
        ld a,(de)
        cp StreamType.Unknown
        ret z
        cp (hl)
        jr z,.perform
        ld e,l
        ld a,l
        add a,StreamData
        ld l,a
        jr .cycle
.perform
        cp StreamType.PT3
        jr nz,.generic
        ;merge PT3 streams to TS
        push hl,de
        push hl,de
        inc l
        ld e,(hl)
        inc l
        ld d,(hl) ;data1
        pop hl
        inc l
        ld a,(hl)
        inc l
        ld h,(hl)
        ld l,a  ;data2
        pop ix
        call FillTS
        pop de,hl
.generic
        ;for other types just take last one
        ld b,StreamData
.copyitems
        ld a,(hl)
        ld (de),a
        inc l
        inc e
        djnz .copyitems        
        ld a,(de)
        cp StreamType.Unknown
        jr nz,.generic
        jr MergeStreams

        endmod
        
        ifndef NoPrologue
        define NoPrologue
        endif
        
        ifndef HaveFormatCheck
        define HaveFormatCheck
        endif
        
        ifndef ONtfm
        define ONtfm
        endif
        
        include "PTSPlay.asm"
        include "pt3.asm"
        include "pt2.asm"
        include "ts.asm"
        include "tfc.asm"
MTC.End        
        display "MTC module size: ",MTC.End-MTC.Start

        endif
