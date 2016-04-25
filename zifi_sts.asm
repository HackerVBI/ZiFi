	device zxspectrum128

;; temp pages:
Gfx_vid_page		equ #c0
menu_gfx_page		equ #d0
highlight_menu_page	equ #d1
Text_page		equ #d8
Vid_page		equ #e0
Sprite_page		equ #f0
Mouse_pal_num		equ #f0

sd_driver_page		equ #0f
cursor_adr		equ #c000
cursor_page		equ #10	

music_players_page	equ 3
music_page		equ #3d	; 2 pages for music
list_ram_page		equ #3f
download_page		equ #40	; allocate #28 pages for 640rb TRD

get_buffer		equ #4000
window_height		equ #0d
window_start_Yl		equ #0100
window_start_Y		equ high window_start_Yl

bigbuff			equ #c000

download_sites		equ 1
gfx_sites		equ 2
music_sites		equ 3
press_sites		equ 4
highlight_size		equ 1408
search_textpage_adr	equ #0108
		
view_downloaded_list	equ 1
view_text		equ 2
save_file		equ 3
play_music		equ 4
view_gfx		equ 5

start_paging_page	equ 1
analizator_screen_adr	equ #c2e0-4
progress_bar_screen_adr	equ #0012


psb_zifi=0
zificom_page            equ #03

		org #8000
start
		ld sp,#bfff

		ld de,#c000
		ld hl,ssid_pass
		ld bc,ssid_pass_end-ssid_pass
		ldir
		call parse_ini

		ei
		call init_zifi


;		ld a,welcome_page
;		call set_page1
;		call text_view_in

main

		ld hl,test_url
		call parse_url
		nop
		call zifi_get

		di
		halt

test_url	db "http://ts.retropc.ru/vtrdos_demo.php?s=1",#0d,#0a,0


/*
Address         Mode Name Description
0x00EF..0xBFEF  R    DR   Data register. Get byte from input FIFO. Input FIFO must not be empty (IFR > 0).
0x00EF..0xBFEF  W    DR   Data register. Put byte into output FIFO. Output FIFO must not be full (OFR > 0).

Address Mode Name Description
0xC0EF  R    IFR  Input FIFO Used Register. 0 - input FIFO is empty, 255 - input FIFO is full.
0xC1EF  R    OFR  Output FIFO Free Register. 0 - output FIFO is full, 255 - output FIFO is empty.

Address Mode Name Description
0xC7EF  W    CR   Command register. Command set depends on API mode selected.
*/

zifi_get	ld hl,cmd_conn2site	; AT+CIPSTART	- connect to site
		
		call zifi_send
;		call zifi_send_raw
;		call fifo_inir
		ld de,str_ok
        	call buffer_cmp
        	cp low output_buff+#bf
		jr z,zifi_get

		ld hl,cmd_cipsend	; AT+CIPSEND=<link ID>,<length>
		call zifi_send_raw
2		call fifo_inir
		ld de,str_ok
        	call buffer_cmp
        	cp low output_buff+#bf
        	jr z,2b
1		ld a,(hl)
		inc hl
		cp #ff
		jr z,2b
		cp ">"		
		jr nz,1b

; send http request
;		ld hl,#c000
;		ld (zipd_adr+1),hl


		ld hl,modem_command
		call zifi_send_raw
1
		call zifi_getchar
		cp "O"
		jr nz,1b
		call zifi_getchar
		cp "K"
		jr nz,1b		
/*
1		call fifo_inir
		ld hl,output_buff
o1		ld a,l
		cp low output_buff+#bf
		jr z,1b
		ld a,(hl)
		inc l
		cp "O"
		jr nz,o1
		ld a,(hl)
		cp "K"
		jr nz,o1
		ld a,2
		out (#fe),a
*/

		di
		ld hl,#c000
read_all_ipds				; call read_idp_packet
		ld (zipd_adr+1),hl
reread_ipd	ld a,3
		out (#fe),a
		ld e,#ff
		ld hl,output_buff
		call rdipd
		xor a
		out (#fe),a
		ld de,CLOSED
		call buffer_cmp
		or a			; CLOSED, exit
		jp z,zifi_read_ipd_ex
		ld de,str_ipd
		call buffer_cmp
		cp low output_buff+#bf
		jr z,reread_ipd
		ex de,hl
		call count_ipd_lenght		; in HL - lenght of ipd packet
		ld (zipd_full_len+1),hl

zipd_adr	ld hl,#0000

zipd_full_len	ld de,0			; ipd len
p231		ld bc,zifi_input_fifo_status
1		in a,(c)
		or a			; 0 - input FIFO is empty,
		jr z,1b
p232		cp      0xbf            ;
		jr      c,p233          ;
		ld      a,0xbf          ; д
p233		ld      c,a             ; о
		ld      a,d             ; л
		or      a               ; г
		jr      nz,p234         ; о
		ld      a,e             ;
		cp      c               ; з
		jr      nc,p234         ; а
		ld      c,e             ; п
p234		ex      de,hl           ; р
		xor     a               ; я
		ld      b,a             ; г
		sbc     hl,bc           ; а
		ex      de,hl           ; е
		ld      b,c             ; м
		ld      c,0xef          ;
		inir                    ; и быстро едем
		ld      a,d
		or      e
		jr      nz,p231
	        jp read_all_ipds
zifi_read_ipd_ex	

		ds 2
		ret

str_ipd		db "+IPD,",0

rdipd:  	call    zifi_getchar
		jr      z,rdipd
		ld      (hl),a
		inc     hl
		cp      ':'
		ret     z
		cp #0a
		ret z
		jr      rdipd

zifi_getchar:	ld      bc,0xc0ef
		in      a,(c)
		jr z,zifi_getchar
		ld      b,0
		in      a,(c)
		dec     b
		ret
/*
		ld a,3
		out (#fe),a
		ld de,#c000
				; call read_idp_packet
read_idp_packet	push de
		ld e,#ff		; lenght
		xor a
		out (#fe),a
		call read_pack
		ld c,a
		ld hl,output_buff
		ld b,l
		pop de
		ldir
		ld a,4
		out (#fe),a
		ld a,d
		cp #d0
		jr nz,read_idp_packet
		nop
		nop
		ret
*/
read_pack
		ld bc,zifi_input_fifo_status	; ждём прихода данных в фифо
		ld hl,0
1		dec hl
		ld a,h
		or a
		jr z,zifi_read_ipd_ex
		in a,(c)
		or a				; 0 - input FIFO is empty,
		jr z,1b
		ld hl,output_buff		; in E - lenght

read_pack_proc	push af
		ld a,6
		out (#fe),a
		pop af
		cp 0xbf
		jr c,1f
		ld a,0xbf
1		ld b,a
		ld a,d
		or a
		jr nz,1f
		ld a,b
		cp e
		jr c,1f
		ld b,e
1		ld a,b
		push af
2		in a,(c)
		ld (hl),a
		inc l
		djnz 2b
;		di
;		inir
;		ei
;		push af
		xor a
		out (#fe),a
		pop af
		ret

fifo_inir	push de
		ld a,1
		out (#fe),a
		call zifi_input_fifo_check
		ld hl,output_buff	; read data from fifo, count: #bf
		push hl
		ld bc,zifi_data_reg
		inir
		xor a
		out (#fe),a
		pop hl
		pop de
		ret

zifi_send			call zifi_send_raw
zifi_check_receive_command	jp fifo_inir

zifi_send_raw	call check_output_fifo_status
		call clear_output_fifo
		push hl
		ld hl,output_buff
		ld de,output_buff+1
		ld bc,#ef
		ld (hl),l
		ldir
		pop hl

		ld bc,zifi_data_reg
1		ld a,(hl)
		or a
		ret z
		out (c),a
		inc hl
		jr 1b

zifi_input_fifo_check
		ld bc,zifi_input_fifo_status	; ждём прихода данных в фифо
		ld e,0
3		in a,(c)
		or a				; 0 - input FIFO is empty,
		ret nz
		halt
		dec e
		jr nz,3b
error		ld a,2
		out (#fe),a		
		ret

clear_output_fifo	ld a,cmd_clear_output_fifo
			call zifi_out_command
check_output_fifo_status
			ld bc,zifi_output_fifo_status
cofs			in a,(c)
			or a
			jr z,cofs		; 0 - output FIFO is full
			ret

clear_input_fifo	ld a,cmd_clear_input_fifo
			call zifi_out_command
			ld bc,zifi_input_fifo_status
clear_input_fifo1	in a,(c)
			or a
			jr nz,clear_input_fifo1		;0 - input FIFO is empty
			ret


zifi_out_command	ld bc,zifi_command_reg
			out (c),a
			ret

zifi_command_result	ld bc,zifi_error_reg
			in a,(c)
			ret

	align 256
output_buff		ds #bf+#bf

downloaded_len	db "Content-Length: ",0
CLOSED		db "CLOSED",#0d,#0a,0
wifi_disconnect	db "WIFI DISCONNECT",#0d,#0a,0	

buffer_cmp	ld hl,output_buff
data_cmp	ld (buffer_cmp_start+1),de
		ld c,low output_buff+#bf
buffer_cmp_start
		ld de,0
buffer_cmp0	ld a,(de)
		cp (hl)
		jr z,buffer_cmp1
		ld a,l
		cp c
		ret z
		inc hl
		jr buffer_cmp0

buffer_cmp1	inc de
		inc hl
		ld a,(de)
		or a
		ret z
		cp (hl)
		jr nz,buffer_cmp_start
		jr buffer_cmp1	


; 	in hl - adress:
;	http://zxaaa.untergrund.net/get.php?f=DEMO6/a_brief_history_of_vacuum_cleaner_nozzle_attachments.zip

parse_url	ld de,cmd_conn2site_adr
pu1		ld a,(hl)	; http://
		inc hl
		cp "/"
		jr nz,pu1
		inc hl ; /
		ld bc,"//"
		ld (host_url+1),hl
		call find_copy_char
		inc hl
		ld (file_url+1),hl
;		ld c,#0d
;		call find_copy_char
		
create_link1	ld hl,create_link_suffix
		ld bc,7
		ldir
		ld hl,modem_command

		ld (hl),"G"
		inc hl
		ld (hl),"E"
		inc hl
		ld (hl),"T"
		inc hl
		ld (hl)," "
		inc hl
		ld (hl),"/"
		inc hl

		ex hl,de
file_url	ld hl,0
		ld bc,#0d0a
		call find_copy_char
		ld hl,http_part1
		ld bc,http_part2-http_part1
		ldir
host_url	ld hl,0
		ld bc,"//"
		call find_copy_char
		ld a,13
		ld (de),a
		inc de
		ld a,10
		ld (de),a
		inc de
		ld hl,http_part2
		ld bc,http_part3-http_part2
		ldir
;		dec de
		ex de,hl
		ld de,modem_command
		or a
		sbc hl,de
;		inc hl
		ld de,url_len
		ld bc,-1000
		call Num1
		cp "0"
		jr z,1f
		ld (de),a
		inc de
1		ld bc,-100
		call Num1
		ld (de),a
		inc de
1		ld c,-10
		call Num1
		ld (de),a
		inc de
1		ld c,-1
		call Num1
		ld (de),a
		inc de
		ld a,#0d
		ld (de),a
		inc de
		ld a,#0a
		ld (de),a
		inc de
		xor a
		ld (de),a
		ret

Num1:		ld	a,'0'-1
Num2:		inc	a
		add	hl,bc
		jr	c,Num2
		sbc	hl,bc
		ret
		
find_copy_char	ld a,(hl)
		cp c
		ret z
		cp b
		ret z
		ld (de),a
		inc hl
		inc de
		jr find_copy_char

create_link_suffix
		db    #22,",80",13,10,0

parse_ini
		ld a,download_page
;		call set_page3
		ld hl,#c000
		ld de,ini_db
		ld b,5
		call cp_ini
		ld (ssid_ini+1),hl
2		ld a,(hl)
		cp #0d
		jr z,1f
		inc hl
		jr 2b
1		inc hl
		inc hl
		ld b,9
		call cp_ini
		ld (pass_ini+1),hl
ssid_ini	ld hl,0
		ld de,cmd_cwjap_pass
		call copy_ini
		ex de,hl
		ld bc,#222c
		ld (hl),b
		inc hl
		ld (hl),c
		inc hl
		ld (hl),b
		inc hl
		ex de,hl
pass_ini	ld hl,0
		call copy_ini
		ex de,hl
		ld (hl),#22
		inc hl
		ld (hl),13
		inc hl
		ld (hl),10
		inc hl
		ld (hl),13
		inc hl
		ld (hl),10
		inc hl
		ld (hl),0
		ret

copy_ini	ld a,(hl)
		cp #0d+1
		ret c
		ld (de),a
		inc hl
		inc de
		jr copy_ini

cp_ini		ld a,(de)
		cp (hl)
		jr nz,error_ini
		inc hl
		inc de
		djnz cp_ini
cp_ini2		ld a,(hl)
		cp #20
		ret nz
		inc hl
		jr cp_ini2

error_ini	ld a,2
		out (#fe),a
		pop hl
		ld hl,error_ini_text
		ld de,#4000
		ld bc,#200
		ldir
		ei 
		jr $

ini_db		db "SSID:"
		db "password:"
error_ini_text	db "Error parsing ini file",0


; init esp8266
cmd_at:       	defb    "ATE0",13,10,0
cmd_gmr:        defb    "AT+GMR",13,10,0	; 3. AT+GMR – View version info
			;This AT command is used to check the version of AT commands and SDK that you are using, the type of which is "executed".
cmd_uart	db 	"AT+UART_CUR=115200,8,1,0,3",13,10,0
cmd_cwmode:     defb    "AT+CWMODE_DEF=1",13,10,0	; Wi-Fi default mode（sta/AP/sta+AP） Save to Flash
cmd_cipmux	db 	"AT+CIPMUX=0",13,10,0		; Выбрать режим одиночного или множественных подключений
cmd_cwautoconn: defb    "AT+CWAUTOCONN=0",13,10,0	; Connect to AP automatically when power on
cmd_cwqap:      defb    "AT+CWQAP",13,10,0		; Disconnect from AP
cmd_cwlap:      defb    "AT+CWLAP",13,10,0		; Lists available APs
cmd_cwjap:      defb    "AT+CWJAP_CUR=",0x22		; Connect to AP, won’t save to Flash
cmd_cwjap_pass	ds 100
;		defb    "wifitest123"                           ; SSID
;		defb    0x22,0x2c,0x22
;		defb    "ZXSpectrumForeverHelloEverybody321"    ; password
cmd_cipsta:     defb    "AT+CIPSTA?",13,10,0		; AT+CIPSTA – Set IP address of station

; load data from server
cmd_conn2site		defb    "AT+CIPSTART="
;cmd_conn2site_task_num	db "0,"
			db 0x22,"TCP",0x22,",",0x22		
						;AT+CIPSTART – Establish TCP connection or UDP transmission
						;AT+CIPMODE – Set transfer mode ------!!!------
						; UART-WiFi passthrough mode (transparent transmission) can only be enabled in TCP single
						; connection mode or UDP of which remote IP and port won’t change (parameter <UDP mode> is 0
						; when using command “AT+CIPSTART” to create a UDP transmission) .
cmd_conn2site_adr	ds #40	;	defb    "zxart.ee"                              ; site
				;	defb    0x22,",80",13,10

cmd_cipsend		db    "AT+CIPSEND="
;download_task_num	db "0,"
url_len			ds 6
			db 0

str_ok:         defb    "OK",13,0
str_error:      defb    "ERROR",13,0
str_fail:       defb    "FAIL",13,0
str_send_ok:    defb    "SEND OK",13,0


current_load_page	db 0

http_part1	db " HTTP/1.0",13,10 ;size=123
		db "Host: " ;zxart.ee",13,10

http_part2	db    "User-Agent: ZiFi (ZX Evo)",13,10    ; show off ;)
		db    "Accept: */*",13,10
		db    "Connection: close",13,10,13,10
http_part3

zip_url_buffer	db "http://ts.retropc.ru/unzipremote.php?f="
zip_url_buffer_data	ds 256


list_search_db
		db "Search:"
		dup 5
		db #0a
		edup
list_search_db_end


		align 256
all_pal_bin	incbin "_spg/menu.tga.pal"
		incbin "_spg/pal_zx.tga.pal"
search_url	ds 64

		align 256
mouse_step	ds 256

parsed_link		ds #080
modem_command		ds 256+128
current_paging_url	ds 150


zifi_command_reg		equ #C7EF
zifi_error_reg			equ #C7EF
zifi_data_reg			equ #BFEF
zifi_input_fifo_status		equ #C0EF
zifi_output_fifo_status		equ #C1EF


cmd_clear_input_fifo	equ 1
cmd_clear_output_fifo	equ 2

	struct thread
num		byte	; num thread -1
len		word	; current ipd lenght
adress		word	; current adress
page		byte	; current page 
file_ext	word	; file name adress
full_len 	word	; lenght of file
full_len_high	byte	; 
	ends


count_ipd_lenght
		ld hl,0			; count lenght
;		ld de,strbuff+7
cil1		ld a,(de)
		inc     de
		cp      ':'
		ret z
		sub     0x30
		ld      c,l
		ld      b,h
		add     hl,hl
		add     hl,hl
		add     hl,bc
		add     hl,hl
		ld      c,a
		ld      b,0
		add     hl,bc
		jr      cil1


ss_cmp		ld hl,output_buff
ss_cm1		ld a,(de)
		or a
		ret z
		inc de
		cpi
		jr z,ss_cm1
		ret




init_zifi
		ld      bc,0xc7ef
		ld      de,0xfff1
		out     (c),e           ;Set API mode 1
		out     (c),d           ;Get Version
		in      a,(c)
		cp      0xff
;		jp      z,nozifi
		ld      a,0x01
		out     (c),a           ;Clear RX FIFO
;		call set_Textpage
		ld hl,cmd_at
		call zifi_send
;ld hl,cmd_uart
;		call zifi_send
		ld hl,cmd_gmr
		call zifi_send
		ld hl,cmd_cwmode
		call zifi_send
		ld hl,cmd_cwautoconn
		call zifi_send
		ld hl,cmd_cipmux
		call zifi_send
;		ld hl,cmd_cwqap	; Disconnect from AP 
;		call zifi_send
;		ld b,25
;		call wait
;		call zifi_check_receive_command
;	ret
		ld hl,cmd_cwjap	; AT+CWJAP_CUR . Connect to AP, for current
		call zifi_send

2		call zifi_check_receive_command
		ld de,str_ok
        	call buffer_cmp
        	cp low output_buff+#bf
        	jr z,2b
		ret

;		call zifi_check_receive_command	; сверка полученного
/*
		ld bc,zifi_error_reg
		in a,(c)
		or a
		jr z,clear_output_fifo		; ????
*/


/*
clear_fifo	; check fifo status AND CLEAR both
			ld bc,zifi_input_fifo_status
			in a,(c)
			or a
			call nz,clear_input_fifo	; 0 - input FIFO is empty, 255 - input FIFO is full.
			
			ld bc,zifi_output_fifo_status
			in a,(c)
			or a
			ret nz				; 0 - output FIFO is full, 255 - output FIFO is empty.
*/


/*
Address         Mode Name Description
0x00EF..0xBFEF  R    DR   Data register. Get byte from input FIFO. Input FIFO must not be empty (IFR > 0).
0x00EF..0xBFEF  W    DR   Data register. Put byte into output FIFO. Output FIFO must not be full (OFR > 0).

Address Mode Name Description
0xC0EF  R    IFR  Input FIFO Used Register. 0 - input FIFO is empty, 255 - input FIFO is full.
0xC1EF  R    OFR  Output FIFO Free Register. 0 - output FIFO is full, 255 - output FIFO is empty.

Address Mode Name Description
0xC7EF  W    CR   Command register. Command set depends on API mode selected.

  All mode commands:
    Code     Command      Description
    000000oi Clear FIFOs  i: 1 - clear input FIFO, o: 1 - clear output FIFO.
    11110mmm Set API mode or disable API:
              0     API disabled.
              1     transparent: all data is sent/received to/from external UART directly.
              2..7  reserved.
    11111111 Get Version  Returns highest supported API version. ER=0xFF - no API available.

Address Mode Name Description
0xC7EF  R    ER   Error register - command execution result code. Depends on command issued.

  All mode responses:
    Code Description
    0x00 OK - no error.
    0xFF REJ - command rejected.

--------------------

Until initialization sequence performed API is disabled and the only command recognized is 'Set API mode'.

Initialization sequence:
- Send 'Set API mode = 1' command,
- Send 'Get Version' command,
- Read highest supported API mode from ER,
- Select desired API mode.

zifi_init:
  ; select API mode 1
  ld bc, 0xC7EF
  ld a, 0xF1
  out (c), a
  ; get highest supported API mode
  ld a, 0xFF
  out (c), a
  in a, (c)
  ; select desired API mode, if need
  ld a, mode  ; possible values are 0xF2..0xF7
  out (c), a
*/




		align 2 

download_icon	incbin "_spg/download.tga.pix"
disk_icon	incbin "_spg/disk.tga.pix"

highlight_colors_buff	ds 80
link_adreses		ds 256
strbuff:

ssid_pass	incbin "_spg/zifi.ini"
ssid_pass_end

end

music_player		equ #c000
music_player_init	equ @music_player+3
music_player_play	equ @music_player+5
music_player_mute	equ @music_player+8

		
/*	; uni player
		org #c000
music_player		INCLUDE	"_pt\uni.asm"

music_player_init	equ @music_player+3
music_player_play	equ @music_player+5
music_player_mute	equ @music_player+8

music_players_end
		SAVEBIN "_spg/ptplay.bin",music_player, music_players_end-music_player
*/
		SAVEBIN "_spg/zifi.bin",start, end-start
