      device zxspectrum128

      org #6000
begin 
      include "test.asm"
      
      org #c000
player      
init=player
play=player+5
mute=player+8
      include "ts.asm"

module      
      incbin TS_INEEDREST

      savesna "test_ts.sna",begin
      savebin "../ts_c000.bin",player,module-player
