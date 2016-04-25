      device zxspectrum128

      org #6000
begin 
      include "test.asm"
      
      org #c000
player      
init=player
play=player+5
mute=player+8
      include "pt2.asm"

module      
      incbin PT2_PITON

      savesna "test_pt2.sna",begin
      savebin "../pt2_c000.bin",player,module-player
