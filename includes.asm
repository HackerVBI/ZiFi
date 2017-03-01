
	IFUSED Galois16
Galois16	ld   hl, #FFFF      ; 10
SeedValue	EQU   $-2
		add  hl, hl         ; 11
		sbc  a         ; 4
		and  #EB         ; 7 instead of #EB one can use #AF
		ld   c, a         ; 4
		xor  l         ; 4
		ld   l, a         ; 4
		ld   a,c         ; 4
		xor  h         ; 4
		ld   h,a         ; 4
		ld   (SeedValue), hl      ; 16
		and   %10101010
		add   l         ; +7+4 => +11t
		ret 

	ENDIF

	IFUSED	rnd
rnd     	ld  de,0x2b3b   ; xz -> yw
		ld  hl,0x9c18   ; yw -> zt; 0xC0DE
		ld  (rnd+1),hl  ; x = y, z = w
		ld  a,l         ; w = w ^ ( w << 3 )
		add a,a
		add a,a
		add a,a
		xor l
		ld  l,a
		ld  a,d         ; t = x ^ (x << 1)
		add a,a
		xor d
		ld  h,a
		rra             ; t = t ^ (t >> 1) ^ w
		xor h
		xor l
		ld  h,e         ; y = z
		ld  l,a         ; w = t
		ld  (rnd+4),hl
		ret
	ENDIF

	IFUSED spr_off
spr_off		ld bc, FMADDR
		ld a, FM_EN+#c
		out (c), a      ; open FPGA arrays at #0000
		; clean SFILE

FM_SFILE        equ #0200+#c000
		ld hl,FM_SFILE
		xor a
spr_off_l1	ld (hl), a
		inc l
		jr nz,spr_off_l1
		inc h
spr_off_l2	ld (hl), a
		inc l
		jr nz,spr_off_l2
		out (c), a      ; close FPGA arrays at #0000
		ret
	ENDIF


	IFUSED clear_tileset
clear_tileset	ld bc,PAGE3
	    	ld a,Tile_page
		out (c),a
		ld (#c000),hl
		ld hl,tileset_clr
		jp set_ports

tileset_clr
		defb #1a,0	;
		defb #1b,0	;
		defb #1c,Tile_page	;
		defb #1d,0	;
		defb #1e,0	;
		defb #1f,Tile_page	;
		defb #28,#ff	;
		defb #26,#1f	;
		defb #27,%00000100
		db #ff

	ENDIF
	IFUSED clear_tileset0
clear_tileset0	ld bc,PAGE0
	    	ld a,Tile_page
		out (c),a
		ld (#0000),hl
		ld hl,tileset0_clr
		jp set_ports

tileset0_clr
		defb #1a,0	;
		defb #1b,0	;
		defb #1c,Tile_page	;
		defb #1d,0	;
		defb #1e,0	;
		defb #1f,Tile_page	;
		defb #28,#3f	;
		defb #26,#3f	;
		defb #27,DMA_FILL+DMA_DALGN
		db #ff

	ENDIF

	IFUSED fadeOUT
/*
		ld b,8
c_pal1		push bc
c_pal		ld hl,viol_pal-32
		ld de,32
		add hl,de
		ld (c_pal+1),hl
		call fadeOUT
		ld hl,(c_pal+1)
		ld de,32*4
		add hl,de
		ex de,hl
		ld hl,temp_pal
		ld bc,32
		ldir
		pop bc
		djnz c_pal1
*/	
fadeOUT
		ld hl,temp_pal
		ld b,#10
fadeout2	push bc
		xor a
		ld (greenH+1),a	; Green High
		ld (greenL+1),a ; Green Low
		ld (red+1),a
		ld (blue+1),a
		call fdout
greenL		ld a,0
blue		or 0
		ld (hl),a
		inc hl
red		ld a,0
greenH		or 0
		ld (hl),a
		inc hl
		pop bc
		djnz fadeout2
		ret

fdout		inc hl
		ld a,(hl)	; 0RRrrrGG gggBBbbb
		dec hl
		push af
		and %01111100
		srl a
		srl a
		dec a
		cp #ff
		jr z,fd21
		sla a
		sla a
		ld (red+1),a; R
fd21
		pop af
		and %00000011	; GG
		ld c,a
		ld a,(hl)
		push af
		and %11100000	; ggg  	0RRrrrGG gggBBbbb
		sla a
		rl c
		sla a
		rl c
		sla a
		rl c
		ld a,c
		dec a
		cp #ff
		jr z,fd22
		ld c,0
		srl a
		rr c
		srl a
		rr c
		srl a
		rr c
		ld (greenH+1),a	; Green High
		ld a,c
		ld (greenL+1),a ; Green Low
fd22
		pop af
		and %00011111
		dec a
		cp #ff
		ret z
		ld (blue+1),a
		ret
		align 2
temp_pal	ds 32
	ENDIF

	IFUSED tile_filler
/*
		ld hl,#c996
		ld de,#0000
		ld bc,#1008	; 128x160
		ld a,Tile_page
		call tile_filler
*/

tile_filler	exx
		ld bc,PAGE3
		out (c),a
		exx
tile_filler_st	ld a,l
		ld (rfil3+1),a
		ld a,#40
		sub b
		ld (rfil4+1),a
rfil1		push bc
rfil2		ld (hl),e
		inc l
		ld (hl),d
		inc l
		inc de
		djnz rfil2
		inc h
rfil3		ld l,0
		ex de,hl
rfil4		ld bc,0
		add hl,bc
		ex de,hl
		pop bc
		dec c
		jr nz,rfil1
		ret
	ENDIF

	IFUSED tile_filler_page0
/*
		ld hl,#0996
		ld de,#0000
		ld bc,#1008	; 128x160
		ld a,Tile_page
		call tile_filler
*/

tile_filler_page0	
		exx
		ld bc,PAGE0
		out (c),a
		exx
		ld a,l
		ld (rfilp3+1),a
		ld a,#40
		sub b
		ld (rfilp4+1),a
2		push bc
1		ld (hl),e
		inc l
		ld (hl),d
		inc l
		inc de
		djnz 1b
		inc h
rfilp3		ld l,0
		ex de,hl
rfilp4		ld bc,0
		add hl,bc
		ex de,hl
		pop bc
		dec c
		jr nz,2b
		ret
	ENDIF
	IFUSED set_ports
set_ports	ld c,#AF
.m1		ld b,(hl) 
		inc hl
		inc b
		jr z,dma_stats
		outi
		jr .m1
	ENDIF
	
	IFUSED set_ports_nowait
set_ports_nowait
		ld c,#AF
.m2		ld b,(hl) 
		inc hl
		inc b
		ret z
		outi
		jr .m2
	ENDIF
	IFUSED dma_stats
dma_stats	ld b,high DMASTATUS
		in a,(c)
		AND #80
		jr nz,$-4
		ret
	ENDIF


	IFUSED inch
inch
	    	INC H
	        LD A,H
	        AND 7
	        ret NZ 
	        LD A,L
	        ADD A,32
	        LD L,A
	        ret C
	        LD A,H
	        SUB 8
	        LD H,A
		ret
	ENDIF
	
	IFUSED incd
incd		INC d
	        LD A,d
	        AND 7
	        ret NZ 
	        LD A,e
	        ADD A,32
	        LD e,A
	        ret C
	        LD A,d
	        SUB 8
	        LD d,A
		ret
	ENDIF

	;in:    de-adr of tab
;       b-dx
;       c-amplitude

	IFUSED SINMAKE
SINMAKE
        INC     C
        LD      HL,SIN_DAT
        PUSH    BC
        LD      B,E
LP_SMK1 PUSH    HL
        LD      H,(HL)
        LD      L,B
        LD      A,#08
LP_SMK2 ADD     HL,HL
        JR      NC,$+3
        ADD     HL,BC
        DEC     A
        JR      NZ,LP_SMK2
        LD      A,H
        LD      (DE),A
        POP     HL
        INC     HL
        INC     E
        BIT     6,E
        JR      Z,LP_SMK1
        LD      H,D
        LD      L,E
        DEC     L
        LD      A,(HL)
        LD      (DE),A
        INC     E
LP_SMK3 LD      A,(HL)
        LD      (DE),A
        INC     E
        DEC     L
        JR      NZ,LP_SMK3
LP_SMK4 LD      A,(HL)
        NEG
        LD      (DE),A
        INC     L
        INC     E
        JR      NZ,LP_SMK4
        POP     BC
LP_SMK5 LD      A,(DE)
        ADD     A,B
        LD      (DE),A
        INC     E
        JR      NZ,LP_SMK5
        RET

SIN_DAT
  DB  #00,#06,#0D,#13,#19,#1F,#25,#2C
  DB  #32,#38,#3E,#44,#4A,#50,#56,#5C
  DB  #62,#67,#6D,#73,#78,#7E,#83,#88
  DB  #8E,#93,#98,#9D,#A2,#A7,#AB,#B0
  DB  #B4,#B9,#BD,#C1,#C5,#C9,#CD,#D0
  DB  #D4,#D7,#DB,#DE,#E1,#E4,#E7,#E9
  DB  #EC,#EE,#F0,#F2,#F4,#F6,#F7,#F9
  DB  #FA,#FB,#FC,#FD,#FE,#FE,#FF,#FF

	ENDIF