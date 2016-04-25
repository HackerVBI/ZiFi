      device zxspectrum128

      org #6000
begin 
      include "test.asm"
      
      org #8000
player      
init=player
play=player+5
mute=player+8
      include "uni.asm"

module      
      ;incbin MTC_CYBERMOTION
      ;incbin MTC_DRUMTEST
      ;incbin MTC_MUG
      incbin MTC_MYSTICAL
      ;incbin MTC_NEWOLD
      ;incbin MTC_SNEGURKA
      ;incbin TFC_CYBERMOTION
      ;incbin TFC_DRUMTEST
      ;incbin TFC_MUG
      ;incbin TFC_MYSTICAL
      ;incbin TFC_NEWOLD
      ;incbin TFC_SNEGURKA
      ;incbin PT3_DRUMTEST
      ;incbin PT3_MYSTICAL
      ;incbin PT3_NEWOLD
      ;incbin PT3_SNEGURKA
      ;incbin TS_INEEDREST
      ;incbin PT2_PITON

      savesna "test_uni.sna",begin
      savebin "../uni_8000.bin",player,module-player
