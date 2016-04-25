      device zxspectrum128

      org #6000
begin 
      include "test.asm"
      
      org #c000
player      
init=player
play=player+5
mute=player+8
      include "tfc.asm"

module      
      incbin TFC_CYBERMOTION
      ;incbin TFC_DRUMTEST
      ;incbin TFC_MUG
      ;incbin TFC_MYSTICAL
      ;incbin TFC_NEWOLD
      ;incbin TFC_SNEGURKA

      savesna "test_tfc.sna",begin
      savebin "../tfc_c000.bin",player,module-player
