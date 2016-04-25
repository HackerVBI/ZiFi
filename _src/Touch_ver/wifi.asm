	device zxspectrum128

;; temp pages:
Tile0_spr_page		equ #d8
Vid_page		equ #e0
Sprite_page		equ #e8
Tile_page		equ #ef

Mouse_pal_num		equ #f0

cursor_adr		equ #c000
cursor_page		equ #10	

get_buffer_page		equ #40
get_buffer		equ #4000

window_height		equ #0d
window_start_Yl		equ #c400
window_start_Y		equ high window_start_Yl


link_adreses		equ #0;+6


		org #8000
start
		ld sp,#bfff
;		ld hl,all_pal_bin+7+2
;		ld (hl),#63

		call all_init
/*
		ld hl,0
		ld de,1
		ld bc,#fff
		ld (hl),l
		ldir
*/
		ld hl,get_buffer
		ld de,link_adreses
		call parse_get
		ex de,hl
		ld bc,6
		or a
		sbc hl,bc
		ld a,(hl)	; all lines
		sub window_height
		ld (all_lines_counter+1),a

		call set_Textpage
		ld hl,#c080
		ld a,#07
1		ld (hl),a
		inc l
		jr nz,1b
		ld l,#80
		inc h
		jr nz,1b

		ld ix,link_adreses
		ld hl,get_buffer
		ld de,window_start_Yl
		ld b,window_height
2		push bc
		call show_line_get_buffer
		pop bc
		djnz 2b
		ei
1		call wait_frame

		jr 1b

text_down_copy	db #1a,0	;low #c000+window_height*2*256
		db #1c,Vid_page
	        db #1d,0	;low #c200+window_height*2*256
	        db #1f,Vid_page
	        db #26,#ff
	        db #28,0
		
		db #ff
/*
		ld hl,get_buffer
		ld de,link_adreses
		; 0 -  number of link
		; 1,2 - adress of link name
		; 3,4 - adress of link url
		; 5 - count of chars date+author lenght
*/

text_up		
link_num	ld a,0
all_lines_counter
		cp 0
		ret z
		inc a
		ld (link_num+1),a		
		add window_height-1
		call calc_link_num
		ld hl,text_up_copy
		call set_ports
		ld hl,window_start_Yl+((window_height-1)*2*256)
		push hl
		call clear_text_line
		pop de
		ld l,(ix+1)
		ld h,(ix+2)
		call show_line_get_buffer
		ld a,1
		ret

calc_link_num	ld l,a
		ld h,0
		add hl,hl
		push hl
		add hl,hl
		pop de
		add hl,de
		push hl
		pop ix
		ret

text_down	
		ld a,(link_num+1)
		or a
		ret z
		dec a
		ld (link_num+1),a
		call calc_link_num
		ld hl,text_down_copy
		call set_ports
		ld d,window_start_Y+window_height*2-4
		ld e,window_start_Y+window_height*2-2
		ld a,window_height-1
		ld (text_down_cnt+1),a
text_down1	ld b,high DMASADDRH 
		out (c),d
		ld b,high DMADADDRH 
		out (c),e
		dec d
		dec e
		dec d
		dec e
		ld b,#27
		ld a,DMA_RAM
		out (c),a
		call dma_stats

text_down_cnt	ld a,0
		dec a
		jr z,down_link
		ld (text_down_cnt+1),a
		jr text_down1

/*
		ld hl,get_buffer
		ld de,link_adreses
		; 0 -  number of link
		; 1,2 - adress of link name
		; 3,4 - adress of link url
		; 5 - count of chars date+author lenght
*/
down_link
		ld hl,window_start_Yl
		push hl
		call clear_text_line
		pop de
		ld l,(ix+1)
		ld h,(ix+2)
		call show_line_get_buffer
		ld a,1
		ret

text_up_copy	db #1a,0
		db #1b,window_start_Y+2
		db #1c,Vid_page
	        db #1d,0
	        db #1e,window_start_Y
	        db #1f,Vid_page
	        db #26,#80-1
	        db #28,window_height*2-1	;-1
		db #27,DMA_RAM
		db #ff




set_Tilepage	ld a,Tile_page
		jr set_page3
set_Textpage	ld a,Vid_page
		jr set_page3

/*

reset_buffer_page
		ld a,get_buffer_page
		ld (set_buffer_page+1),a
		jr set_page3

next_buffer_page
		ld a,(set_buffer_page+1)
		inc a
		ld (set_buffer_page+1),a
*/

set_buffer_page	ld a,get_buffer_page
set_page3	ld bc,PAGE1
		out (c),a
		ret

/*
		ld hl,get_buffer
		ld de,link_adreses
		; 0 -  number of link
		; 1,2 - adress of link name
		; 3,4 - adress of link url
		; 5 - count of chars date+author lenght
*/
parse_get	
		call set_buffer_page
		ld c,0
parse_get1	ld a,(hl)
		cp #0d
		jr z,parse_end
		ld a,c
		ld (de),a	; number of link
		inc de
		call save_parsed	; adress of link name
		call scan_0d
		call save_parsed	; adress of link url
		call scan_0d		; date adr
		ld b,0
		call scan_count_0d		; author
		call scan_count_0d		; city
		dec b
		ld a,b
		ld (de),a			;  count of chars date+author lenght
		inc de
		call scan_0d			; next record
		inc c
		jr parse_get1
parse_end	ld a,#ff
		ld (de),a
		ret

save_parsed	ld a,l
		ld (de),a	; adress of link adress
		inc de
		ld a,h
		ld (de),a
		inc de
		ret

scan_count_0d	ld a,(hl)
		inc hl
		inc b
		cp #0d
		jr nz,scan_count_0d
		inc hl		; #0a
		ret

scan_0d		ld a,(hl)
		inc hl
		cp #0d
		jr nz,scan_0d
		inc hl		; #0a
		ret

clear_text_line	ld d,h
		inc d
		call set_Textpage
		xor a
		ld b,#80
1		ld (hl),a
		ld (de),a
		inc l
		inc e
		djnz 1b
		ret

show_line_get_buffer
		call set_Textpage
		call set_buffer_page
show_get_buffer1
		push de
		push de
		ld a,6+8
		call drawString
		pop de
		inc d
		call scan_0d	; propusk: links
		ld c,(ix+5)	; num of chars
		inc c		; + " "
		ld a,80+1
		sub c
		jr nc,1f
		xor a
1		ld e,a
		ld a,4
		call drawString
		inc de
		ld a,4+8
		call drawString
		call scan_0d		; city
		ld de,6
		add ix,de
		pop de
		inc d
		inc d
		ret


drawString	; de: string
		; hl: screen adress in tiles
		ld (char_color+1),a
		ld b,d
		ld c,e
		set 7,c
dStr1		ld a,(hl)
		cp #0d
		jr z,dStr2
		ld (de),a
		inc e
char_color	ld a,0
		ld (bc),a
		inc c
		inc hl
		jr dStr1

dStr2		inc hl		; #0a
		inc hl		; #0d
		ret


	;===========procedures==============
	; display address by cell
	; IN: D-X E-Y
	; OUT: HL
DISP_ADDR_BY_CELL
		ld a,e
	;	sub e
		add #40
		ld h,a
		ld a,d
		add a,a
		add #80
		ld l,a
		ret



wait_frame	ld a,(frame+1)
		or a
		jr z,wait_frame
		xor a
		ld (frame+1),a
		ret




int_main	push af,hl,de,bc
frame		ld a,0
		inc a
		ld (frame+1),a
		call mouse_buttons
		call mouse

		ld	hl,scan_speed	;30+24
		ld	de,int_next

int_ex		ld	bc,VSINTL
		out	(c),l
		ld	bc,VSINTH
		out	(c),h
		ex de,hl
		ld	(#beff),hl
		pop bc,de,hl,af
		ei
		ret

/*
int_next	push af,hl,de,bc
		call mouse_pos
		ld	hl,(288/3)*2
		ld	de,int_last
		jr int_ex
*/
scan_speed	equ 288/4

int_next	push af,hl,de,bc
		call mouse_pos
int_scan	ld hl,0	;30+24
		push hl
		ld de,288-scan_speed
		sbc hl,de
		pop hl
		jr c,1f
		ld hl,int_main
		ld (#beff),hl
		ld hl,0-scan_speed
1
		ld de,scan_speed
		add hl,de
		ld (int_scan+1),hl

		ld	bc,VSINTL
		out	(c),l
		ld	bc,VSINTH
		out	(c),h

		pop bc,de,hl,af
		ei
		ret






; Mouse_proc
/*
1  D0 - лева€ кнопка
2  D1 - права€ кнопка
4  D2 - средн€€ кнопка

#10-#f0
  D4-D7 - wheel
*/

mouse_buttons
/*
		ld a,(mouse_y)
		dec a
		ld (mouse_y),a
*/

wheel_check	ld c,0
		ld a,(mouse_button)
		cpl
		and #f0
		cp c
		jr z,lmb_old
wheel_old	ld c,0
		ld (wheel_check+1),a
		ld (wheel_old+1),a
		cp c
		jp nc,text_up
		jp text_down


lmb_old		ld a,(mouse_button)
		cpl
		and 1
		cp 1 ; lmb pressed
		jp nz,lmb_release

border_check	ld a,1
		or a
		ret z

lmb_counter	ld a,0
		inc a
		cp #08
		jr z,drag_start
		jr nc,lmb_drag
lmb_counter2	ld (lmb_counter+1),a
		ret

drag_start	ld (lmb_counter+1),a
old_drag_pos	ld a,(mouse_y)
		neg
		ld (list_y_pos+1),a
		ld a,1
		ld (border_check+1),a
		ret

lmb_drag	

		ld a,(mouse_y)
		neg
list_y_pos	ld c,0
		sub c
list_wheel_pos	or a
		ret z
		cp #18
		jr nc,ld1
		cp #10
		jr c,ld2
		call old_drag_pos
		call text_up
		ld a,0
		jp z,border_exit
		xor a

ld1		neg
		cp #10
		jr c,ld3
		call old_drag_pos
		call text_down
		or a
		jr z,border_exit
		ld a,#f1	; neg = #0f

ld3		neg
ld2		and #0f
		ld bc,GYOFFSL
		out (c),a
		ld (click_offset+1),a
ex_no_offset	ld a,#02
		jr lmb_ex2

lmb_drag_ex	
		ld a,(border_check+1)
		or a
		jr nz,lmb_drag_ex2
		xor a
		ld bc,GYOFFSL
		out (c),a

		jr lmb_ex

lmb_drag_ex2	ld a,(list_y_pos+1)
		ld c,a
		ld a,(mouse_y)
		neg
		sub c
		and #0f
		
		ld bc,GYOFFSL
		out (c),a
		jr lmb_ex

lmb_release
		ld a,(lmb_counter+1)
		or a
		jr z,border_switch_on
		cp 6
		jr nc,lmb_drag_ex
lmb_click	ld a,(mouse_y)
		sub (window_start_Y-#c0)*8
click_offset	add 0
		srl a
		srl a
		srl a
		srl a
		
		ld c,a
		ld a,(link_num+1)
		add c

		call calc_link_num
		ld de,#d000+30
		ld l,(ix+1)
		ld h,(ix+2)
		call show_line_get_buffer

/*
		and 7
		add #f0
		ld bc,BORDER
		out (c),a
*/		
lmb_ex		ld (click_offset+1),a
		xor a
		ld (lmb_counter+1),a
		xor a
lmb_ex2		ld (mouse_spr+4),a

border_switch_on	ld a,1
border_exit	
		ld (border_check+1),a
		ret

mouse		call mouse_buttons
		call mouse_pos
		ld a,(mouse_y)
		ld (mouse_spr),a	; Y
		cp 8
		jr nc,mouse_margin_y
		ld de,#fff8
		ld b,d
		ld c,e
		jr mouse_mrg_y_top

mouse_margin_y	cp 240-16
		jr c,mouse_margin_y_ex
		ld de,#0118
		ld bc,#0008

mouse_mrg_y_top	ld hl,0
		add hl,bc
		ld a,h
		cp d
		jr nz,mouse_mrg_y_top2
		ld a,l
		cp e
		jr z,mouse_margin_y_ex
mouse_mrg_y_top2
		ld (mouse_mrg_y_top+1),hl



mouse_margin_y_ex
		ld hl,(mouse_x)
		ld bc,8
		sub hl,bc
		jr nc,mouse_margin_x
		ld bc,#f8f8
		jr mouse_mrg_x_top

mouse_margin_x	ld hl,(mouse_x)
		ld bc,320-16
		sub hl,bc
		jr c,mouse_margin_x_ex
		ld bc,#c808

mouse_mrg_x_top	ld a,0
		add c
		cp b
		jr z,mouse_margin_x_ex
		ld (mouse_mrg_x_top+1),a

mouse_margin_x_ex
		ld hl,(mouse_x)
		ld a,l
		ld (mouse_spr+2),a	; X
		ld a,(mouse_spr+3)
		and #fe
		or h
		ld (mouse_spr+3),a

		ld hl,sprites
		jp set_ports
/*
  D0 - лева€ кнопка
  D1 - права€ кнопка
  D2 - средн€€ кнопка

 D4-D7 - wheel

Standard Kempston Mouse
#FADF - buttons
#FBDF - X coord
#FFDF - Y coord
*/
mouse_pos
		LD BC,#FADF
		IN A,(C)     ;читаем порт кнопок
key_in		ld (mouse_button),a
/*
		call key_scan	
ki0		LD hl,MOUSE11+1
		ld a,d
		cp #af
		jr nc,ki5

kileft		and left
		jr z,ki1	
		inc (hl)
		inc (hl)
ki1		ld a,d
kiright		and right
		jr z,ki2
		dec (hl)
		dec (hl)
ki2		LD hl,MOUSE12+1
		ld a,d
kidown		and down
		jr z,ki3
		inc (hl)
		inc (hl)
ki3		ld a,d
kiup		and up
		jr z,ki4
		dec (hl)
		dec (hl)
ki4		ld a,d
		and fire
		or a
		jr z,ki5
		ld a,#0e
		ld (mouse_button),a

ki5		ld a,d
		cp rmb_key
		jr nz,ki8
		ld a,#0d
		ld (mouse_button),a
		jr ki6
		
ki8		
;		call keys_wait_proc
;		ld a,d
;		cp key_pause
;		jp z,pause_button_view

		cp key_tower1
		jr c,ki6
		ld c,a
keys_wait	ld a,0
		or a
		jr z,ki7
		jr ki6

keys_wait_proc	ld a,(keys_wait+1)
		or a
		ret z
		dec a
		ld (keys_wait+1),a
		ret

ki7		

;		ld a,(tower_upgrade_flag)
;		or a
;		jr z,ki9
;		ld a,c
;		ld (upgrade_but+1),a
;		jr ki10

ki9;		ld a,c
;		ld (tower_keys+1),a
ki10;		xor a
;		ld (tpr_old+1),a
		ld a,18
		ld (keys_wait+1),a
		ld a,#0e
		ld (mouse_button),a
ki6
*/
;		LD     HL,(mouse_xy)
		LD     BC,#FBDF
mz0		IN     A,(C)
MOUSE11		LD     d,0
		LD     (MOUSE11+1),A
		sub d
		CALL   NZ,MOUSE_X_vector
		LD     B,#FF
mz1		IN     A,(C)
/*
mz2		ld hl,#4000
		ld (hl),a
		inc hl
		ld (mz2+1),hl
*/
MOUSE12		LD     D,0
		LD     (MOUSE12+1),A
		SUB    D
		CALL   NZ,MOUSE_Y_vector
		RET

MOUSE_X_vector	
		JP M,MOUSE35	; Sign Negative (M)
		ld e,a
		ld d,0
		ld hl,(mouse_x)
		add hl,de
		ld (mouse_x),hl
		ld de,320
		sub hl,de
		ret c
1		ld hl,320-1
		ld (mouse_x),hl
		RET


MOUSE35		
		neg
		ld e,a
		ld d,0
		or a
		ld hl,(mouse_x)
		sub hl,de
		jr nc,1f
		ld hl,0
1
		ld (mouse_x),hl
		RET

MOUSE_Y_vector
		JP     M,MOUSE45

		ld e,a
		ld d,0
		or a
		ld hl,(mouse_y)
		sub hl,de
		jr nc,2f
		ld hl,0
2
		ld (mouse_y),hl

		ret

MOUSE45
		neg
		ld e,a
		ld d,0
		ld hl,(mouse_y)
		add hl,de
		ld (mouse_y),hl
		ld de,240
		sub hl,de
		ret c
1		ld hl,240-1
		ld (mouse_y),hl
		ret



koorp		ld a,c
		and #18
	;	or #c0
		ld h,a
		ld a,c
		and #07
		rrca
		rrca
		rrca
		add a,b
		ld l,a
		ret 	; 14 байт, 53 такта


im2_init	
		xor a	
		ld bc,HSINT
		out (c),a
		ld bc,VSINTL
		out (c),a
		ld bc,VSINTH
		out (c),a
		ld e,4
		ld b,high GXOFFSL
		call fill_ports
		ld e,7
		ld b,high T0XOFFSL
		call fill_ports
		call spr_off
		ld a,#be
		ld i,a
		ld hl,int_main
		ld (#beff),hl
		im 2
		ret

fill_ports	out (c),a
		inc b
		dec e
		jr nz,$-4
		ret

; ----- alex rider keys

right:			equ #01
left:			equ #02
down:			equ #04
up:			equ #08
fire:			equ #10
rmb_key			equ #f0

key_pause		equ #cf	
key_tower1		equ #b0
key_tower2		equ #b2
key_tower3		equ #b4
key_tower4		equ #b6
key_code		equ #b8

			                     ; in: nothing
                                               ; out:
key_scan                                       ;       d - pressed directions in kempston format
	ld a,#fe                               ; check for CAPS SHIFT
	in a,(#fe)
	rra
	ld hl,key_table - 1         ; selection of appropriate keyboard table
	jr c,.no_cs
	ld hl,cs_key_table - 1      ; hl - keyboard table (zero-limited)
.no_cs:
	ld d,#00                               ; clear key flag
	ld c,#0fe                              ; low address of keyboard port
.loop:
	inc hl                                 ; next key
	ld b,(hl)                              ; high byte of port address from table
	inc b                                  ; end of table check
	dec b
	ret z
	inc hl                                 ; going to key mask
	in a,(c)                               ; reading half-row state
	or (hl)                                ;
	inc hl                                 ; going to key flag
	inc a                                  ; a = half-row state or mask. if #ff - current key isn't pressed
	ld a,d
	jr z,.loop                             ; key isn't pressed
	or (hl)                                ; result or key flag
	ld d,a                                 ; store it
	jr .loop

	; key table format
; 1st byte - high byte of keyboard half-row address
; 2nd byte - inverted key mask (e.g. outer key - #fe, next key - #0fd etc)
; 3rd byte - direction bit

key_table:
	db #0ef, #0fe, fire	;0
	db #0ef, #0fd, up	;9
	db #0ef, #0fb, down	;8
	db #0ef, #0f7, right	;7
	db #0ef, #0ef, left	;6


	db #0f7, #0fe, key_tower1	;1
	db #0f7, #0fd, key_tower2	;2
	db #0f7, #0fb, key_tower3	;3
	db #0f7, #0f7, key_tower4	;4
	db #0f7, #0ef, key_code		;5

	db #0df, #0fe, right	;p
	db #0df, #0fd, left	;o
	db #0fb, #0fe, up	;q
	db #0fd, #0fe, down	;a
	db #07f, #0fb, fire	;m
	db #07f, #0fe, key_pause	;space

	db #000


cs_key_table:
	db #0ef, #0fe, fire	;0
	db #0ef, #0fb, right	;8
	db #0ef, #0f7, up	;7
	db #0ef, #0ef, down	;6
	db #0f7, #0ef, left	;5
	db #07f, #fd , rmb_key	;caps+sym
	db #000


; ---------------- end of alex sources
fill_menu	push bc
fill_menu1	ld (hl),e
		inc l
		ld (hl),d
		inc l
		djnz fill_menu1
		inc h
		ld l,b
		pop bc
		dec c
		jr nz,fill_menu
		ret

all_init	di
		ld bc,MEMCONFIG
		ld a,%00001110
		out (c),a
		call im2_init
		call mouse_pos
		call mouse_buttons
		ld hl,#3000		; 0
		call clear_tileset
		ld hl,cursor_copy
		call set_ports

		call set_Tilepage
		ld hl,#c000
		ld de,#310c
		ld bc,#4004
		call fill_menu
		ld hl,#dd00
		ld bc,#4001
		call fill_menu
		ld hl,#dd3e
		ld de,#3109
		call set_one_tile
		call set_one_tile
		ld hl,#dd4c
		call set_one_tile
		call set_one_tile
		ld hl,text_pages_db
		ld de,#dd42
		call print

		ld hl,text_sites
		ld de,#c014
		call print

		ld hl,text_sites2
		ld de,#c014+8*2+2
		call print

		ld hl,#c000
		ld de,#3100
		ld bc,#0804	; 128x160
		ld a,Tile_page
		call tile_filler

		ld bc,PAGE3
		ld a,Vid_page
		out (c),a
		ld hl,#0000		;1111 - white
		ld (#c000),hl
		ld hl,init_ts
		jp set_ports

print		call set_Tilepage
		ld b,d
		ld c,e
print1		ld a,(hl)
		inc hl
		or a
		ret z
		dec a
		jr nz,print2
		inc b
		ld d,b
		ld e,c
		jr print1 

print2		sub #20-1
		ld (de),a
		inc e
		ld a,#30
		ld (de),a
		inc e
		jr print1


set_one_tile	ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		ld a,e
		add #40
		ld e,a
		ret




text_pages_db	db "01/01",0
text_sites	db " DEMOS",1," MUSIC",1,"GRAPHICS",0
text_sites2	db "HYPE",1,"PRESS",0

init_ts		db #00,VID_TEXT+VID_320X240 ;VID_NOGFX+
		db high VPAGE,Vid_page	;
		db #20,6
		db high BORDER,#f0	; border
		db high TSCONFIG,TSU_SEN+TSU_T0EN+TSU_T0ZEN;+TSU_T1EN +TSU_T1ZEN		; TSConfig
		db high PALSEL,#3f
		db high SGPAGE, Sprite_page
		db high TMPAGE, Tile_page
		db high T0GPAGE,Tile0_spr_page
;		db high T1GPAGE,Tile1_spr_page
clr_screen
		defb #1a,0	;
		defb #1b,0	;
		defb #1c,Vid_page	;
		defb #1d,0	;
		defb #1e,0	;
		defb #1f,Vid_page	;
		defb #26,#ff	;
		defb #28,32-1	;
		defb #27,%00000100
		db #ff

cursor_copy	db #1a,low cursor_adr
		db #1b,high cursor_adr
		db #1c,cursor_page
	        db #1d,0
	        db #1e,0
	        db #1f,Sprite_page
	        db #26,32/4-1
	        db #28,16-1
		db #27,DMA_RAM + DMA_DALGN
		db #ff

sprites
		db #1a,low spr_db
	        db #1b,high spr_db
		db #1c,2
	        db #1d,0
	        db #1e,2
	        db #1f,0
	        db #26,#ff
	        db #28,0
		db #27,DMA_RAM_SFILE
		db #ff


		include "../includes.asm"
		include "../tsconfig.asm"


mouse_button	db 0
/*
  D0 - лева€ кнопка
  D1 - права€ кнопка
  D2 - средн€€ кнопка
*/

mouse_x		dw 0
mouse_y		dw 0	
	; l - X, h- Y
mouse_map	dw 0
mouse_switch	db 0


		ALIGN 2
spr_db		

		DB 0
		DB %01000000	; leap
		DB 0
		DB %00010000
		DB 0
		DB %11100000

		
		DB 0
		DB %01000000	; leap
		DB 0
		DB %00010000
		DB 0
		DB %11100000


mouse_spr
		db 0		;y
		db SP_SIZE16+SP_ACT
		db #0		;x
		db SP_SIZE16
		db #0
		db Mouse_pal_num+#00


/*
; show text
txt_spr
		db 240-96-16;+16	;y
		db SP_SIZE16+SP_ACT
		db #0		;x
		db SP_SIZE64
		db #00
		db #ef

		db 240-96-16;+16	;y
		db SP_SIZE16+SP_ACT
		db #0+64	;x
		db SP_SIZE64
		db #08
		db #ef
*/

		DB 0		;exit
		DB %01000000	; leap
		DB 0
		DB %00010000
		DB 0
		DB %11100000




	align 2


end
		
		SAVEBIN "_spg/wifi.bin",start, end-start