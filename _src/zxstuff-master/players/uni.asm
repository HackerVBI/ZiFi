      ifndef _uni_asm_defined
      define _uni_asm_defined
      
      module UNI
      ld hl,End
      jr Init
Play  jp 0
Mute  jp 0
      
Init  ;check most stable first
      call .tryMTC
      call nz,.tryTFC
      call nz,.tryTS
      call nz,.tryPT2
      call nz,.tryPT3
      ret z
      ld hl,52
      ld d,h,e,l
.addr ld (Play+1),hl
      ld (Mute+1),de
      ret

.tryMTC
      push hl
      call MTC.CheckFormat
      pop hl
      ret nz
      call MTC.Init
      ld hl,MTC.Play
      ld de,MTC.Mute
      jr .addr      
      
.tryTFC
      push hl
      call TFC.CheckFormat
      pop hl
      ret nz
      call TFC.Init
      ld hl,TFC.Play
      ld de,TFC.Mute
      jr .addr
      
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
      include "mtc.asm"
UNI.End      
      display "UNI module size: ",UNI.End-UNI.Init
      endif