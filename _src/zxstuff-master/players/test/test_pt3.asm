      device zxspectrum128

      org #6000
begin 
      include "test.asm"
      
      org #c000
player      
init=player
play=player+5
mute=player+8
      include "pt3.asm"

module      
      ;incbin PT3_DRUMTEST
      ;incbin PT3_MYSTICAL
      ;incbin PT3_NEWOLD
      incbin PT3_SNEGURKA

      savesna "test_pt3.sna",begin
      savebin "../pt3_c000.bin",player,module-player
