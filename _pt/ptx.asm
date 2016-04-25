      ifndef _ptx_asm_defined
      define _ptx_asm_defined
      
      module PTX
      ld hl,End
      jr Init
Play  jp 0
Mute  jp 0
      
Init  
      call .tryTS
      call nz,.tryPT2
      call nz,.tryPT3
      ret z
      ld hl,.ex
      ld d,h,e,l
.addr ld (Play+1),hl
      ld (Mute+1),de
.ex   ret

.tryTS
      push hl
      call TS.CheckFormat
      pop hl
      ret nz
      call TS.Init
      ld hl,TS.Play
      ld de,TS.Mute
      jr .addr      

.tryPT2
      push hl
      call PT2.CheckFormat
      pop hl
      ret nz
      call PT2.Init
      ld hl,PT2.Play
      ld de,PT2.Mute
      jr .addr

.tryPT3
      push hl
      call PT3.CheckFormat
      pop hl
      ret nz
      call PT3.Init
      ld hl,PT3.Play
      ld de,PT3.Mute
      jr .addr      
      
      endmod

      define HaveFormatCheck
      define NoPrologue
      include "_pt/PTSPlay.asm"
      include "_pt/pt3.asm"
      include "_pt/pt2.asm"
      include "_pt/ts.asm"
PTX.End      
      display "PTX module size: ",PTX.End-PTX.Init
      endif