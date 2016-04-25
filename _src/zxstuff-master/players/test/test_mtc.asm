      device zxspectrum128

      org #6000
begin 
      include "test.asm"
      
      org #8000
player      
init=player
play=player+5
mute=player+8
      include "mtc.asm"

module      
      ;incbin MTC_CYBERMOTION
      ;incbin MTC_DRUMTEST
      ;incbin MTC_MUG
      ;incbin MTC_MYSTICAL
      ;incbin MTC_NEWOLD
      ;incbin MTC_SNEGURKA
      incbin MTC_INDEEDREST

      savesna "test_mtc.sna",begin
      savebin "../mtc_8000.bin",player,module-player
