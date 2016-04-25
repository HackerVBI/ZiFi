      di
      call init
      ld iy,#5c3a
      ld hl,10072
      exx
      ei
.loop halt
      ld bc,1
      ld hl,500
.delay
      sbc hl,bc
      jr nz,.delay
      ld a,4
      out (-2),a
      call play
      xor a
      out (-2),a
      ld a,#7f
      in a,(-2)
      rra
      jr c,.loop
      CALL mute
.fail ld a,2
      out (-2),a
      di
      halt

      define MTC_CYBERMOTION "CyberMotion.mtc"
      define MTC_DRUMTEST "drumtest.mtc"
      define MTC_MUG "mug.mtc"
      define MTC_MYSTICAL "mystical.mtc"
      define MTC_NEWOLD "newold.mtc"
      define MTC_SNEGURKA "Snegurka.mtc"
      define MTC_INDEEDREST "ineedrest.mtc"

      define TFC_CYBERMOTION MTC_CYBERMOTION,0x76
      define TFC_DRUMTEST MTC_DRUMTEST,0xa90
      define TFC_MUG MTC_MUG,0x52
      define TFC_MYSTICAL MTC_MYSTICAL,0xcd4
      define TFC_NEWOLD MTC_NEWOLD,0x263a
      define TFC_SNEGURKA MTC_SNEGURKA,0x52

      define PT3_DRUMTEST MTC_DRUMTEST,0x52
      define PT3_MYSTICAL MTC_MYSTICAL,0x52
      define PT3_NEWOLD MTC_NEWOLD,0x52
      define PT3_SNEGURKA MTC_SNEGURKA,0xaa4

      define TS_INEEDREST "ineedrest.mtc",0x52

      define PT2_PITON "PITON.pt2"
      