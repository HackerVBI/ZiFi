	device zxspectrum128

;; temp pages:
splash_gfx_page		equ #20
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
music_page		equ #1d	; 2 pages for music
list_ram_page		equ #1f
download_page		equ #20	; allocate #28 pages for 640rb TRD

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
	
cable_zifi=0		; 1 - Cable version, 0 - wifi version

	IF cable_zifi 
start_download_adress 	equ 0
	ELSE 
start_download_adress	equ #0001
	ENDIF


		org #8000
start
		ld sp,#bfff
		call all_init
 		call set_256c_mode		
		call sd_init

	IF !cable_zifi 
		call load_ini
		call parse_ini
	ENDIF
		ei
 		ld b,60
 		call wait
 		ld hl,int_main
		ld (#beff),hl
 		call gfx_init
		call set_text_colors

	IF cable_zifi 
		call psb_start
	ELSE
		call init_zifi
	ENDIF
;		call autoupdate		; !!!!!!!!!!!!!
main
sites_sw	ld a,0
		or a
		call nz,sites_list	; показать список сайтов для раздела

load_sw		ld a,0
		or a
		jp z,main_ex
		call modem_load_file
	
		ld a,(do_after_load+1)
		cp save_file
		jr c,do_after_load
		call create_filename
do_after_load	ld a,0
		cp save_file
		jr c,1f
		push af
		call save_downloaded_file
		pop af
1		cp view_downloaded_list
		call z,create_link_list
		cp view_text
		call z,text_view
		cp play_music
		call z,music_loaded
		cp view_gfx
		call z,view_image

main_ex		call wait_frame

do_start_music	ld a,1
		or a
		call z,music_init

; off music before loading new music file
do_init_music	ld a,0
		or a
		jr z,main
		call music_init
		xor a
		ld (music_sw+1),a
		ld (is_music_play+1),a
		ld (do_init_music+1),a
		jp main

selfupdate_msg1		db "ZiFi ver. "
cur_version		db '0.67',0

autoupdate	ld hl,cur_version
		ld de,upd_ver
		ldi
		inc hl
		ldi
		ldi
		ld hl,selfupdate_msg1
		ld b,1
		call zifi_echo
		ld hl,selfupdate_msg2
		ld b,1
		call zifi_echo
		ld hl,selfupdate
		call parse_url
		ld a,download_page
		ld (load_ram_page+1),a
		call modem_load_file
		ld de,not_update_message
		ld hl,(ix+thread.adress)
		ld a,"Y"
		cp (hl)
		jr nz,4f
		inc hl
		ld a,'o'
		cp (hl)
		jr z,3f
		dec hl
4		push hl
		ld bc,4
		add hl,bc	; first 4 chars must be CRC16
		ld (ix+thread.adress),hl
		ex de,hl
		ld hl,(ix+thread.full_len)
		or a
		sbc hl,bc
		ld (ix+thread.full_len),hl
		ld b,h
		ld c,l
;Inputs:    de->data bc=number of bytes
;Outputs:   hl=CRC16
		call CRC16
		ld a,download_page
		call set_page1
		pop de
		call str2hex
		cp h
		jr nz,1f
		call str2hex
		cp l
		jr z,2f
1		ld de,checksum_error_mes
		jr 3f

2		ld a,sd_driver_page
		call set_page0

		CALL SETROOT; возвращаемся в коневой
		LD HL,DIR2
		CALL FENTRY
		CALL SETDIR

;i: HL - flag(1),name(1-255),0
;o:  Z - NOT FOUND
;   NZ - FILE DELETED
		ld hl,update_file
		push hl
		call DELFL
		pop hl
		inc l
		ld de,FILE_NAME
		call copy_ini
		call save_downloaded_file
		ld de,update_message
3		ex de,hl
		call set_Textpage
		ld b,1
		call zifi_echo
		jp set_download_dir

selfupdate_msg2		db "Check for updates... ",0
checksum_error_mes	db "Checksum error, please restart",0
not_update_message	db "Your ZiFi is up to date.",0
update_message		db "-+- Your ZiFi is updated! -+- Please restart -+-",0

selfupdate	db "http://ts.retropc.ru/zifi_ver.php?"
	IF cable_zifi 
		db "c"
	ELSE
		db "w"
	ENDIF	
		db "="
upd_ver		ds 3
		db #0d



str2hex		call str2hex1
		add a,a
		add a,a
		add a,a
		add a,a
		ld c,a
		call str2hex1
		or c
		ret

str2hex1	ld a,(de)
		cp #40
		jr c,1f
		sub #7
1		sub #30
		inc de
		ret


CRC16:
;Borrowed from http://zilog.sh.cvut.cz/~base/misc/z80bits.html
; and moddified to be a loop
;The arrow comments show what lines I added or commented out from the original.
;Inputs:    de->data bc=number of bytes
;Outputs:   hl=CRC16
	   push bc     ;<---<<<
	   push de     ;<---<<<
	   push af     ;<---<<<
	   ld hl,$FFFF		; CRC16.CCITT 
	   push bc     ;<---<<<
CRC16_Read:
	   ld a,(de)
	   inc de
	   xor h
	   ld h,a
		bit 7,d
		jr z,1f
crc_page   	ld a,download_page
		inc a
		ld (crc_page+1),a
		call set_page1
	   	ld d,#40
1	   ld b,8
CRC16_CrcByte:
	   add hl,hl
	   jr nc,CRC16_Next
	   ld a,h
	   xor $10
	   ld h,a
	   ld a,l
	   xor $21
	   ld l,a
CRC16_Next:
	   djnz CRC16_CrcByte
	;   dec c      ;>>>--->
	   pop bc      ;<---<<<
	   dec bc      ;<---<<<
	   push bc     ;<---<<<
	   ld a,b      ;<---<<<
	   or c        ;<---<<<
	   jr nz,CRC16_Read
	   pop bc      ;<---<<<
	   pop af      ;<---<<<
	   pop de      ;<---<<<
	   pop bc      ;<---<<<
	   ret


create_filename			; and check extension for scl scr sxg others
		ld hl,modem_command+5	; without GET
		ld a,#0d
1		cpi
		jr nz,1b	; HTTP/1.0#0d
		ld bc,11+2
		sbc hl,bc
1		ld (ix+thread.file_ext),hl	;find file extension
		dec hl
1		ld a,(hl)			; check  \ / : * ? " < > |
		cp "\\"
		jr z,1f
		cp "/"
		jr z,1f
		cp ":"
		jr z,1f
		cp "*"
		jr z,1f
		cp "?"
		jr z,1f
		dec hl
		jr 1b
1
		inc hl		
		ld de,FILE_NAME		; file_name create
2		ld a,(hl)
		cp ' '
		jr z,1f
		ld (de),a
		inc hl
		inc de
		jr 2b

1		
		xor a
		ld (de),a

		ld a,(ix+thread.page)	; check unzip extension
		call set_page1
		ld hl,(ix+thread.adress)
		ld a,"."
		cp (hl)
		ret nz
		inc hl
1		dec de
		ld a,(de)
		cp '.'
		jr nz,1b
		inc de
		ld b,3
1		ld a,(hl)
		ld (de),a
		inc hl
		inc de
		djnz 1b
		xor a
		ld (de),a
		ld (ix+thread.adress),hl

; all lenght - 4bytes of extension
		ld a,(ix+thread.full_len_high)	; a - high 16bit lenght
		ld hl,(ix+thread.full_len)	; hl - low 16bit lenght
		ld de,4
		or a
		sbc hl,de
		sbc a,0
		ld (ix+thread.full_len_high),a	; a - high 16bit lenght
		ld (ix+thread.full_len),hl	; hl - low 16bit lenght
		ret

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
modem_load_file
		xor a
		ld (pause_music+1),a
		ld l,a
		ld h,a
		ld ix,read_threads
		ld (ix+thread.full_len),hl
		ld (ix+thread.full_len_high),a
		ld a,(do_after_load+1)
		cp play_music
		jr nz,1f
		ld a,(is_music_play+1)
		or a
		jr z,1f
		call set_music_pages
		call music_player_mute
		call restore_music_pages
		xor a
		ld (music_sw+1),a
		ld (is_music_play+1),a
		ld (do_init_music+1),a
1
; show link
;		ld hl,cmd_conn2site_adr
;		ld de,#1e00		; show link
;		call show_line_get_buffer
;		ld hl,modem_command
;		ld de,#1000		; show link
;		call show_line_get_buffer
load_ram_page	ld a,0
		ld (clr_load_mem1+1),a
		ld (clr_load_mem2+1),a
		call set_page3
		call off_int_dma
		ld hl,0
		ld (#c000),hl
		ld hl,clr_load_mem
		call set_ports
		ld de,download_icon
		call set_icon
		call on_int_dma
		ld hl,progress_bar_screen_adr-1
		ld (progress_bar+1),hl
		ld b,4
		call view_progress_bar

	IF cable_zifi 
		ld a,(load_ram_page+1)
		ld hl,modem_command
		call psb_get

	ELSE

		call zifi_get
	ENDIF

; bc: hl - lenght of readed data
		ld ix,read_threads
		ld a,c
		ld (ix+thread.full_len_high),a	; bc - high 16bit lenght
		ld (ix+thread.full_len),hl	; hl - low 16bit lenght
;		ld a,1		; thread num -1
		xor a
		ld (ix+thread.num),a
		ld a,(load_ram_page+1)
		ld (ix+thread.page),a
		call set_page1
		ld hl,status_copy		; clear statusbar gfx
		call set_ports
		xor a
		ld (load_sw+1),a
		call find_0d0a
		ld (ix+thread.adress),hl
		push hl		
		ld de,#4000+start_download_adress
		or a
		sbc hl,de
		ex de,hl
		ld hl,(ix+thread.full_len)
		sbc hl,de
		ld (ix+thread.full_len),hl	; hl - low 16bit lenght
		pop hl
		ld a,(do_after_load+1)
		cp view_downloaded_list
		ret nz
; добавляем строку поиска первой и переставляем адрес загрузки (!!!)
		ld bc,list_search_db_end-list_search_db
		push bc
		or a
		sbc hl,bc
		ld (ix+thread.adress),hl
		ex de,hl
		ld hl,list_search_db
		pop bc
		ldir
		call off_int_dma
		ld hl,link_page_copy
		call set_ports
		jp on_int_dma


zifi_get	ld a,(load_ram_page+1)
		ld (zipd_page+1),a
		call set_page0
		inc a
		call set_page1
		ld hl,0
		ld (readed_len_low+1),hl
		ld hl,cmd_conn2site	; AT+CIPSTART	- connect to site
		call zifi_send
		ld de,str_ok
        	call buffer_cmp
        	cp low output_buff+#bf
		jr z,zifi_get

1		ld hl,cmd_cipsend	; AT+CIPSEND=<link ID>,<length>
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

		ld hl,start_download_adress		; load in page0 - page1
		ld (zipd_adr+1),hl
read_all_ipds				; call read_idp_packet
		
reread_ipd	;ld a,3
;		out (#fe),a
		ld e,#ff
		ld hl,output_buff
		call rdipd
;		xor a
;		out (#fe),a
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
		ld a,h
		cp #40
		jr c,1f
zipd_page	ld a,0
		inc a
		ld (zipd_page+1),a
		call set_page0
		inc a
		call set_page1
		ld a,h
		sub #40
		ld h,a
1		ld (zipd_adr+1),hl

		ld hl,(zipd_full_len+1)
		ld b,h
readed_len_low	ld de,0
		add hl,de
		ld (readed_len_low+1),hl
		jr nc,1f
readed_len_high	ld a,0
		inc a
		ld (readed_len_high+1),a
1
		call view_progress_bar
	        jp read_all_ipds

zifi_read_ipd_ex	
		ld a,(readed_len_high+1)
		ld c,a
		ld hl,(readed_len_low+1)
		ret



rdipd:  	call    zifi_getchar
		jr      z,rdipd
		ld      (hl),a
		inc     hl
		cp      ':'
		ret     z
		cp #0a
		ret z
		jr      rdipd

zifi_getchar:	
wifi_cancel_download	ld a,0
		or a
		jr nz,wifi_cancel_download_ex
		ld      bc,0xc0ef
		in      a,(c)
		jr z,zifi_getchar
		ld      b,0
		in      a,(c)
		dec     b
		ret

wifi_cancel_download_ex
		ld sp,#bfff
		xor a
		ld (load_sw+1),a
		ld (wifi_cancel_download+1),a
		ld hl,status_copy		; clear statusbar gfx
		call set_ports
		jp main

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

read_pack_proc	cp 0xbf
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
		ret

fifo_inir	push de
		call zifi_input_fifo_check
		ld hl,output_buff	; read data from fifo, count: #bf
		push hl
		ld bc,zifi_data_reg
		inir
		pop hl
		pop de
		ret

zifi_send			call zifi_send_raw
zifi_check_receive_command	jp fifo_inir


zifi_send_echo	push hl
		ld b,1
		call zifi_echo
		pop hl
		call zifi_send_raw
		call fifo_inir
1		ld a,(hl)
		inc hl
		cp #0d+1
		jr c,1b
		dec hl
		ld b,3
zifi_echo	ld de,#1000
		call print
		ld a,d
		cp 24
		jr c,1f
		ld hl,text_up_copy
		call set_ports
		ld hl,24*256
		call clear_text_line
		ld a,22
1		ld (zifi_echo+2),a
		ret

print		ld a,(hl)
		cp #ff
		ret z
		ld a,b
		or a
		jr nz,1f
		ld b,1
1		push de
print1		ld a,(hl)
		inc hl
		cp #0d+1
		jr c,print2
		ld (de),a
		inc de
		jr print1 

print2		ld a,(hl)
		cp #0d+1
		jr nc,1f
		inc hl
1		pop de
		inc d
		djnz print
		ret

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
		ld a,(wifi_cancel_download+1)
		or a
		jp nz,wifi_cancel_download_ex
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



set_icon	ld a,e
		ld (status_icon_copy+1),a
		ld a,d
		ld (status_icon_copy+3),a
		ld hl,status_icon_copy
		jp set_ports

wait		call wait_frame
		djnz wait
		ret

view_progress_bar
		ld a,b
		or a
		ret z
		push hl
		push bc
		push bc
		ld a,Vid_page+9
		call set_page0_lite
		pop bc
progress_bar	ld hl,0
		inc hl
		bit 7,l
		jr z,1f
		ld l,low progress_bar_screen_adr
		ld a,(progress_bar_color+1)
		xor #18
		ld (progress_bar_color+1),a
1		ld (progress_bar+1),hl
progress_bar_color
		ld a,#74
		ld (hl),0
		inc h
		inc h
		dup 3
		ld (hl),a
;		inc l
;		ld (hl),a
;		dec l
		inc h
		inc h
		edup
		ld (hl),0
		inc h
		inc h
		djnz progress_bar
		call restore_page0
		pop bc
		pop hl
		ret




/*
+#0000 #04 #7f+"SXG" - 4 байта сигнатура, что это формат файла SXG
+#0004 #01 1 байт версия формата
+#0005 #01 1 байт цвет фона (используется для очистки)
+#0006 #01 1 байт тип упаковки данных (#00 - данные не пакованы)
+#0007 #01 1 байт формат изображения (1 - 16ц, 2 - 256ц)
+#0008 #02 2 байта ширина изображения
+#000a #02 2 байта высота изображения

(далее указываются смещения, для того, что бы можно было расширить заголовок)
+#000c #02 смещение от текущего адреса до начала данных палитры
+#000e #02 смещение от текущего адреса до начала данных битмап
Собственно начало данных палитры +#0010 #0200 512 байт палитра
и начало данных битмап +#0210 #xxxx данные битмап
*/

init_view_image	
		ld hl,int_gfx_view
		ld (#beff),hl
		xor a
		ld bc,VSINTL
		out (c),a
		inc b
		out (c),a
		call wait_frame
		ld hl,(ix+thread.adress)
		ret


view_image	ld ix,read_threads
		ld hl,(ix+thread.file_ext)
		inc hl
		ld a,"x"		; sxg / scr
		cpi
		jr z,view_sxg_image
		ld a,"r"
		cpi 
		ret nz

view_scr_image		
		ld a,Gfx_vid_page
		call set_page3
		call init_view_image
		ld de,#c000
		ld bc,#1b00
		ldir
		xor a
		ld (gfx_vmode+1),a
		ld (gfx_border+1),a
		ld a,#0f
		ld (gfx_vpal+1),a	; palsel
		jp show_gfx


view_sxg_image
		
		ld a,(ix+thread.page)
		call set_page1
		call init_view_image
		ld de,5
		add hl,de
		push hl
		ld a,(hl)	; background? #4005
		ld l,a
		ld h,a
		ld (gfx_border+1),a

		ld a,Gfx_vid_page
		call set_page3
		ld (#c000),hl
		ld hl,clr_gfx_screen
		call set_ports

		pop hl
		inc hl
		inc hl	; #4007
; 		push	af
;		ld	(clrColor+1),a
;		ld	a,(hl)	; Тип упаковки данных (#00 - не пакованы)
		ld a,(hl)		; Video mode
		ld c,a
		inc hl
		cp 2

; 16c mode
		ld b,DMA_RAM + DMA_DALGN	; dma mode
		ld a,1				; high byte pal adress
		ld de,#0f08			; 32byte for pal dma send, 8 for palsel
		jr nz,3f
		xor a
		ld b,DMA_RAM + DMA_DALGN + DMA_ASZ
		ld de,#ff00

3		ld (view_image_pals_vpal_adr+1),a
		ld (color_type+1),a
		ld a,b
		ld (gfx_copy_type+1),a
		ld (gfx_copy_t2+1),a
		ld a,e
		ld (gfx_vpal+1),a
		ld a,d
		ld (view_image_pals_vpal+1),a
		or a
		rl e
		rl e
		rl e
		rl e
		ld a,e
		ld (gfx_border+1),a
/*		
		ld	(imageMode),a
		push	hl
		call	setImageMode
		pop	hl
		cp	#ff					; error -> exit
		ret	z
*/
		ld	e,(hl)					; Width 0-512
		inc	hl
		ld	d,(hl)
		inc	hl

; 	#168 - 360; #140 - 320; #100- 256
		ld a,#68
		cp e
		jr nz,1f
		ld a,VID_360X288
		jr 2f

1	
;		ld a,#40
;		cp e
;		jr nz,
		ld a,VID_320X240	; standart resolution
2		or c
		ld (gfx_vmode+1),a

		srl d
		rr e
color_type	ld a,0
		or a
		jr z,4f
		srl d
		rr e		; Width 0-512 /4
4		ld a,e
		dec a
		ld (gfx_copy_w+1),a

		ld	e,(hl)					; Height 0-512
		inc	hl
		ld	d,(hl)
		inc	hl
		bit 0,d
		jr z,1f
		ld a,#ff
		jr 2f

1		xor a
		dec e
2		ld (gfx_copy_h+1),a
		dec e
		ld a,e
		ld (gfx_copy_h2+1),a

		ld	c,(hl)					; Указатель (смещение) на начало данных палитры
		inc	hl
		ld	b,(hl)
		inc	hl
		push	hl
		add	hl,bc					; Начало данных палитры
		ld a,l
		ld (view_image_pals+1),a
		ld a,h
		ld (view_image_pals+3),a
		ld hl,view_image_pals
		call set_ports
;gPalNum		ld	b,#01					; Номер экрана для кого грузить палитру
;		ld	a,setGfxPalette
;		call	cliKernel
		pop	hl
		ld	c,(hl)					; Указатель (смещение) на начало данных bitmap
		inc	hl
		ld	b,(hl)
		inc	hl
		add	hl,bc					; Начало данных bitmap
		ld a,l
		ld (gfx_copy+1),a
		ld a,h
		ld (gfx_copy+3),a

		ld hl,gfx_copy
		call set_ports
gfx_copy_h2	ld a,0
		ld b,#28
		out (c),a
		dec b
gfx_copy_t2	ld a,DMA_RAM + DMA_DALGN
		out (c),a
		call dma_stats

show_gfx	call wait_frame
gfx_vmode	ld a,0
		ld bc,VCONFIG
		out (c),a

		ld b,high PALSEL
gfx_vpal	ld a,#08
		out (c),a

		ld b,high TSCONFIG
		ld a,0
		out (c),a
		ld b,high BORDER
gfx_border	ld a,0
		out (c),a
		ld a,Gfx_vid_page
		ld b,high VPAGE
		out (c),a
		
		xor a
		ld b,high GYOFFSL
		out (c),a
		inc b
		out (c),a
		call pause
		LD BC,#FADF
3		IN A,(C)     ;читаем порт кнопок
		and 3
		cp 3
		jr z,3b
		call pause
		ld hl,int_main
		ld (#beff),hl
		ld b,high TSCONFIG
		ld a,TSU_SEN
		out (c),a
		ld hl,all_pals
		call set_ports
		ld hl,zx_pals
		jp set_ports

pause		ld b,#0a
		call wait_frame
		djnz $-3
		ret
text_view	
		ld a,download_page
		call set_page1
text_view_in	xor a
		ld (lmb_click_sw+1),a
		ld (do_after_load+1),a
		inc a
		ld (text_scroll+1),a
		call set_text_colors
		xor a
		call set_page3
		call set_Textpage
		call parse_text
;		ld hl,(ix+thread.adress)
;		ld ix,#c000;2		; text line buffer adresses
;		ld (ix+0),l
;		ld (ix+1),h

		ld hl,#c000
		ld de,window_start_Yl	; text page
		ld b,window_height*4	; rows
		call show_text_line
		ld hl,window_height*2
		ld (text_up_line_adr+1),hl
		ld a,l
		ld (text_up+1),a
		ret

parse_text	ld de,(ix+thread.adress)
		ld hl,#c000		; text line buffer adresses
		ld b,download_page
parse_text0	ld c,0
		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		ld (hl),b
		inc hl
parse_text1	ld a,(de)
		or a
		jr z,parse_text_ex
		cp #ff
		jr z,parse_text_ex
		cp #0d
		jr nz,parse_text2
		inc de
		inc de
		jr parse_text4
		
parse_text2	inc de
		bit 7,d
		jr z,parse_text3
		ld d,#40
		inc b
		ld a,b
		push bc
		call set_page1
		pop bc
parse_text3	inc c
		ld a,c
		cp 80
		jr nz,parse_text1
parse_text4	ld (hl),c
		inc hl
		jr parse_text0

parse_text_ex	xor a
		ld (hl),a
		inc hl
		ld (hl),a
		ret
/*
		ld de,window_start_Yl	; text page
		ld bc,(window_height*2)*256+80		; rows col, chars in row
		call show_text_line
*/		
show_text_line	ld (show_text_line_adr+1),de
show_text_line1	ld e,(hl)
		inc hl
		ld d,(hl)
		inc hl
		ld a,d
		or e
		ret z
		ld a,(hl)
		inc hl
		push bc
		call set_page1
		ld c,(hl)
		inc hl
		ld a,c
		or a
		jr z,show_text_line2
		push hl
		ex de,hl
show_text_line_adr
		ld de,0
		ld a,d
		ld b,0
		ldir
		inc a
		ld (show_text_line_adr+2),a
		pop hl
show_text_line2	pop bc
		djnz show_text_line1
		ld a,1
		ret
/*
show_text_line	ld a,(hl)
		or a
		ret z
		cp #ff
		ret z
		cp #0d
		jr nz,text_view2
		inc hl
		inc hl
text_nl		ld a,0
		or a
		jr z,text_nl2
		inc ix
		inc ix
		ld (ix+0),l
		ld (ix+1),h
text_nl2	inc d
		ld e,0
		ld c,80
		dec b
		jr nz,show_text_line
		ld a,1
		or a
		ret

text_view2	ld (de),a
		inc hl
		inc de
		dec c
		jr z,text_nl
		jr show_text_line
*/


text_up		ld a,1
		or a
		ret z

		ld a,download_page
		call set_page1
		ld hl,text_up_copy
		call set_ports
		ld hl,window_start_Yl+((window_height-1)*2*256)
		push hl
		call clear_text_line
		pop de
;		ld a,1
;		ld (text_nl+1),a

text_up_line_adr
		ld hl,0
		add hl,hl
		add hl,hl		
		ld a,h
		add #c0
		ld h,a
		push hl
		ld hl,(text_up_line_adr+1)
		inc hl
		inc hl
		ld (text_up_line_adr+1),hl
		xor a
		call set_page3
		call set_Textpage_lite
		pop hl
		ld bc,2*256+80		; rows col, chars in row
		call show_text_line
		or a
		ld (text_up+1),a
		ret


text_down	ld hl,(text_up_line_adr+1)
		ld de,window_height*2
		or a
		sbc hl,de
		jr nz,1f
;		cp window_height*2
;		jr nz,1f
		xor a
		ret
		
1		ld hl,(text_up_line_adr+1)
		dec hl
		dec hl
		ld (text_up_line_adr+1),hl
		or a
		sbc hl,de
		add hl,hl
		add hl,hl
		ld a,h
		or #c0
		ld h,a
		push hl
		ld a,download_page
		ld (text_up+1),a
		call set_page1
		call text_dma_down
		xor a
		call set_page3
		call set_Textpage_lite
		pop hl
		ld de,window_start_Yl
		ld b,2	; rows
		jp show_text_line
		
text_dma_down	ld hl,text_down_copy
		call set_ports
		ld d,window_start_Y+window_height*2-4
		ld e,window_start_Y+window_height*2-2
		ld a,window_height*2-1
td1		exa
		ld b,high DMASADDRH 
		out (c),d
		ld b,high DMADADDRH 
		out (c),e
		dec d
		dec e
;		dec d
;		dec e
		ld b,#27
		ld a,DMA_RAM
		out (c),a
		call dma_stats
		exa
		dec a
		jr nz,td1
		ld hl,#180
		ld a,7
		ld (hl),a
		inc l
		jr nz,$-2
		ret

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
		call set_page3
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
		call text_view_in
		ei 
		jr $

ini_db		db "SSID:"
		db "password:"
error_ini_text	db "Error parsing ini file",0

site_list	dw download_site_list,gfx_site_list,music_site_list,press_site_list

download_site_list	
		db "Games: vtrdos.ru ",#0d,#0a, "http://ts.retropc.ru/vtrdos.php?t=g",#0d,#0a, save_file,download_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db "Games: prods.tslabs.info - ZX Enhanced",#0d,#0a, "http://prods.tslabs.info/prods_zifi.php?t=2",#0d,#0a, save_file,download_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db "Demo Packs: vtrdos.ru",#0d,#0a, "http://ts.retropc.ru/vtrdos_demo.php?p=1",#0d,#0a, save_file,download_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db "Demos: prods.tslabs.info - ZX Enhanced",#0d,#0a, "http://prods.tslabs.info/prods_zifi.php?t=1",#0d,#0a, save_file,download_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db "Demos: pouet.net - ZX Spectrum",#0d,#0a, "http://ts.retropc.ru/pouet.php?src=pouet_zx",#0d,#0a, save_file,download_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db "Demos: pouet.net - ZX Enhanced",#0d,#0a, "http://ts.retropc.ru/pouet.php?src=pouet_zxe",#0d,#0a, save_file,download_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db "System: vtrdos.ru",#0d,#0a, "http://ts.retropc.ru/vtrdos.php?t=s",#0d,#0a, save_file,download_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a		
		db #00

gfx_site_list	db "Graphics: zxart.ee",#0d,#0a, "http://zxart.ee/zxnet/?a=g",#0d,#0a, view_gfx,download_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db #00
music_site_list	db "Music database: zxart.ee",#0d,#0a, "http://zxart.ee/zxnet/?a=m",#0d,#0a, play_music,music_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db " Most popular",#0d,#0a, "http://zxart.ee/zxnet/?a=m&o=p",#0d,#0a, play_music,music_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db " Top-rated",#0d,#0a, "http://zxart.ee/zxnet/?a=m&o=r",#0d,#0a, play_music,music_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db " First places",#0d,#0a, "http://zxart.ee/zxnet/?a=m&o=w",#0d,#0a, play_music,music_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db " Top of last year published",#0d,#0a, "http://zxart.ee/zxnet/?a=m&o=y",#0d,#0a, play_music,music_page,#0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		
		
		db #00
press_site_list	db "Hype: hype.retroscene.org",#0d,#0a, "http://ts.retropc.ru/get.php?src=hype",#0d,#0a, view_text,download_page, #0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db "Emags: vtrdos.ru", #0d,#0a, "http://ts.retropc.ru/vtrdos.php?t=p",#0d,#0a, save_file,download_page, #0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db "IRC Logs", #0d,#0a, "http://irclogs.retroscene.org/zifi.php?src=z80",#0d,#0a, view_downloaded_list,download_page, #0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db "RSS Channels", #0d,#0a, "http://irclogs.retroscene.org/zrss.php",#0d,#0a, view_text,download_page, #0d,#0a, " ",#0d,#0a, " ",#0d,#0a
		db #00


hl_menu_src	db #1a,0
		db #1b,0
hl_menu_desc	db #1d,0
		db #1e,0
		db #1c,highlight_menu_page
		db #1f,Vid_page
		db #26,88/2-1
		db #28,16-1
		db #27,DMA_RAM + DMA_DALGN +DMA_ASZ
		db #ff

hl_menu_adr	dw 0,#c000+88
		dw highlight_size,#e000+88
		dw highlight_size*2,#c000+88+88+8
		dw highlight_size*3,#e000+88+88+8

sites_list	dec a		; highlight menu gfx
		push af
		add a,a
		add a,a
		ld l,a
		ld h,0
		ld de,hl_menu_adr
		add hl,de
		ld de,hl_menu_src+1
		ld b,4
1		ld a,(hl)
		ld (de),a
		inc hl
		inc de
		inc de
		djnz 1b
		ld hl,menu_copy
		call set_ports
		ld hl,hl_menu_src
		call set_ports

		ld a,download_page
		ld (load_ram_page+1),a
		xor a
		ld (scroll_sw+1),a	; switch off mouse scrolls
		call set_text_colors
				; clear text screen
		pop af
		add a,a
		ld l,a
		ld h,0
		ld de,site_list
		add hl,de
		ld a,(hl)
		inc hl
		ld h,(hl)
		ld l,a
		push hl
		ld de,link_adreses
		call parse_get
		ld a,c
		ld (all_lines_counter+1),a
		ld (sum_list_lines+1),a
		ld ix,link_adreses
		ld b,a
		dec b
		pop hl
		ld de,window_start_Yl
2		push bc
		call show_line_get_buffer
		pop bc
		djnz 2b
		xor a
		ld (sites_sw+1),a
		ld (click_offset+1),a	; GYOFFSL =0 
		ld a,view_downloaded_list
		ld (do_after_load+1),a
		ret

set_text_colors
		call off_int_dma
		call set_Textpage
		ld hl,0
		ld (#0000),hl
		ld hl,clr_text_screen
		call set_ports
		
		ld hl,#0080
set_text_colors_color
		ld a,#07
1		ld (hl),a
		inc l
		jr nz,1b
		ld l,#80
		inc h
		bit 5,h
		jr z,1b
		jp on_int_dma

create_link_list
		ld a,1
		ld (scroll_sw+1),a
		xor a
		ld (text_scroll+1),a
		ld (link_num+1),a
		ld (click_offset+1),a		
		ld hl,(ix+thread.adress)
		push hl
		ld de,link_adreses
		call parse_get
		ld a,c
		ld (sum_list_lines+1),a
		cp window_height		; check num of prods < window list for scrolls
		jr nc,1f
		xor a
		jr 2f

1		sub window_height
2		ld (all_lines_counter+1),a

		ld a,c
		call set_text_colors

		ld ix,link_adreses
		pop hl
		ld de,window_start_Yl
		ld b,window_height
2		push bc
		call show_line_get_buffer
		pop bc
		djnz 2b

do_after_link_list		ld a,0				; действие после загрузки 
				ld (do_after_load+1),a
				ld c,0
				cp play_music
				jr nz,1f
				ld c,1

1				ld a,c
				ld (autoplay+1),a

loadpage_after_link_list	ld a,0				; страница для загрузки прода данного раздела
				ld (load_ram_page+1),a
		xor a
		ld (load_sw+1),a
		ret

find_0d0a	ld hl,get_buffer
find_0d0a_hl
ss_cm4		ld a,#0d
ss_cm3		cpi
		jr nz,ss_cm3
		ld a,#0a
		cpi
		jr nz,ss_cm4
		ld a,#0d
		cpi
		jr nz,ss_cm4
		ld a,#0a
		cpi
		jr nz,ss_cm4
		ret

/*
		ld hl,get_buffer
		ld de,link_adreses
		; 0 -  number of link
		; 1,2 - adress of link name
		; 3,4 - adress of link url
		; 5 - count of chars date+author lenght
*/

list_up
text_scroll	ld a,0
		or a
		jp nz,text_up
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
		ex de,hl
		ld ix,link_adreses
		add ix,de
		ret

list_down	ld a,(text_scroll+1)
		or a
		jp nz,text_down
		ld a,(link_num+1)
		or a
		ret z
		dec a
		ld (link_num+1),a
		call calc_link_num
		call text_dma_down
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

; ------- page 0
set_Textpage_lite
		ld a,Text_page
		jr set_page0_lite

set_Textpage	ld a,Text_page
		jr set_page0

set_page0	ld (restore_page0+1),a
set_page0_lite	ld bc,PAGE0
		out (c),a
		ret

restore_page0	ld a,0
		jr set_page0_lite

; -------  page 1
set_buffer_page	ld a,list_ram_page
set_page1	ld (restore_page1+1),a
set_page1_lite	ld bc,PAGE1
		out (c),a
		ret

restore_page1	ld a,0
		jr set_page1_lite

; -------  page 3


set_page3	ld (restore_page3+1),a
set_page3_lite	ld bc,PAGE3
		out (c),a
		ret

restore_page3	ld a,0
		jr set_page3_lite

set_music_pages	ld a,music_page
		call set_page0
		inc a
		call set_page1
		ld a,music_players_page
		jp set_page3
restore_music_pages
		xor a
		call set_page0
		ld a,list_ram_page
		jp set_page1
		
/*
set_music_pages	ld a,(restore_page0+1)
		ld (rest_p0+1),a
		ld a,(restore_page1+1)
		ld (rest_p1+1),a
		ld a,(restore_page3+1)
		ld (rest_p3+1),a

		ld a,music_page
		call set_page0
		inc a
		call set_page1
		ld a,music_players_page
		jp set_page3
restore_music_pages
rest_p0		ld a,0
		call set_page0
rest_p3		ld a,0
		call set_page3
rest_p1		ld a,list_ram_page
		jp set_page1
*/



set_music_pages_lite	
		ld a,music_page
		call set_page0_lite
		inc a
		call set_page1_lite
		ld a,music_players_page
		jp set_page3_lite

restore_music_pages_lite
		call restore_page0
		call restore_page1
		jp restore_page3

/*
		ld hl,get_buffer
		ld de,link_adreses
		; 0 -  number of link
		; 1,2 - adress of link name
		; 3,4 - adress of link url
		; 5 - type of a site_list
*/
parse_get	
		call set_buffer_page
		ld c,1
parse_get1	ld a,(hl)
		cp #0a
		jr c,parse_get_ex
		cp #0d
		jr z,parse_get_ex
		ld a,c
		ld (de),a	; number of link
		inc de
		call save_parsed	; adress of link name
		call scan_0d
		call save_parsed	; adress of link url
		call scan_0d		; date adr
		call scan_0d		; author
		call scan_0d		; city
		inc de
		call scan_0d			; next record
		inc c
		jr parse_get1

parse_get_ex	ld a,c
		ld (de),a	; number of link
		inc de
save_parsed	ld a,l
		ld (de),a	; adress of link adress
		inc de
		ld a,h
		ld (de),a
		inc de
		ret

scan_0d		ld a,(hl)
		inc hl
		cp #0a
		jr nz,scan_0d
;		inc hl		; #0a
		ret

clear_text_line	ld d,h
		inc d
		ld e,l
		call set_Textpage_lite
		xor a
		ld b,#80
1		ld (hl),a
		ld (de),a
		inc l
		inc e
		djnz 1b
		jp restore_page0

show_line_get_buffer
		call set_Textpage_lite
		ld a,list_ram_page
		call set_page1_lite
		ld a,(hl)	; end of list
		or a
		jp z,slgb_ex
		push de
		ld a,6+8
		call drawString	; name
		call scan_0d	; propusk: links

		ld a,(hl)
		cp #0b	; пропуск всех пустых строк сразу (для списка ссылок раздела и поиска)
		jr nc,show_get_buf4
		or a
		jr z,show_get_buffer_ex
		call scan_0d
		call scan_0d
		call scan_0d
		jr show_get_buffer_ex+3

; echo $x++.'.'.$lx['title']."\r\n
; $lx['url']."\r\n"
; $lx['year']."\r\n".
; substr($authors,0,-1)."\r\n";
; addslashes($lx['city'])."\r\n";

show_get_buf4	ld (show_year_adr+1),hl	; store "year"
		call scan_0d
		ld (show_author_adr+1),hl	; store "authors"
		call scan_0d
;		ld (show_city_adr+1),hl	; store "city"
		call scan_0d
		ld (show_get_buffer_ex+1),hl

show_author_adr	ld hl,0
		ld a,(hl)	; check "by author"
		cp #0e
		jr c,1f
		push hl
		ld hl,by_db	; by
		ld a,4
		call drawString
		pop hl
		ld a,4+8	; authors
		call drawString
1		
show_year_adr	ld hl,0			; year
		ld a,(hl)	; check "year"
		cp #0e
		jr c,1f
		ld a,","
		ld (de),a
		inc de
		inc de
		ld a,4
		call drawString
1

show_get_buffer_ex
		ld hl,0
		ld de,6
		add ix,de
		pop de
		inc d
		inc d
slgb_ex		call restore_page0
		jp restore_page1



by_db		db " by ",#0a

drawString	; de: screen adress in tiles
		; hl: string
		ld (char_color+1),a
		push de
		exx
		pop hl
		set 7,l
		exx
dStr1		ld a,(hl)
		cp #0a
		jr z,dStr2
		cp #0d
		jr z,dStr3
		ld (de),a
		inc e
		exx
char_color	ld (hl),0
		inc l
		exx
		inc hl
		jr dStr1

dStr3		inc hl
dStr2		inc hl		; #0a
		ret


wait_frame	ld a,(frame+1)
		or a
		jr z,wait_frame
		xor a
		ld (frame+1),a
		ret

int_gfx_view	push af,hl,de,bc,ix
		ld a,(frame+1)
		inc a
		ld (frame+1),a
		ld a,(music_sw+1)
		or a
		call nz,pt_play
		pop ix,bc,de,hl,af
		ei
		ret

int_main	push af,hl,de,bc,ix,iy
		ld a,#34
		ld bc,BORDER
		out (c),a
		exx
		push hl,de,bc
		exx
		exa
		push af
		exa
		xor a
		ld b,high GYOFFSL
		out (c),a
		inc b
		out (c),a
		call set_256c_mode
frame		ld a,0
		inc a
		ld (frame+1),a

save_mode	ld a,1
		or a
		jr z,int_ex2
mouse_sw	ld a,1
		or a
		call nz,mouse
link_highlight	ld a,0
		or a
		call nz,link_highlight_view

int_ex2		ld hl,56+4*8-2
		ld de,int_text_cor
int_ex		ld bc,VSINTL
		out (c),l
		ld b,high VSINTH
		out (c),h
		ex de,hl
		ld (#beff),hl
		exa
		pop af
		exa
		exx
		pop bc,de,hl
		exx
		pop iy,ix,bc,de,hl,af
		ei
		ret

int_text_cor	push af
		push hl
		push bc
		ld hl,56+4*8
		ld bc,VSINTL
		out (c),l
		ld b,high VSINTH
		out (c),h
		ld hl,int_text_on
		ld (#beff),hl
		xor a
		ld (int_text_cor_ex+1),a
		ei
int_text_cor_ex	ld a,0
		or a
		jr z,int_text_cor_ex
		pop bc
		pop hl
		pop af
		ret

int_text_on	push af,hl,de,bc,ix,iy
txt_border	ld a,#f0
		ld bc,BORDER
		out (c),a
		exx
		push hl,de,bc
		exx
		exa
		push af
		exa
		ld a,(click_offset+1)
		ld b,high GYOFFSL
		out (c),a
		ld b,high VCONFIG
		ld a,VID_TEXT+VID_320X240
		out (c),a
;		ld b,high TSCONFIG
;		ld a,TSU_SEN
;		out (c),a
		ld b,high VPAGE
		ld a,Text_page
		out (c),a
		ld b,high PALSEL
		ld a,#3f
		out (c),a
		ld (int_text_cor_ex+1),a
		ld hl,47+240-1-2
		ld de,int_text_ofcor
		jp int_ex

int_text_ofcor	push af
		push hl
		push bc
		ld hl,47+240
		ld bc,VSINTL
		out (c),l
		ld b,high VSINTH
		out (c),h
		ld hl,int_text_off
		ld (#beff),hl
		xor a
		ld (int_text_ofcor_ex+1),a
		ei
int_text_ofcor_ex	ld a,0
		or a
		jr z,int_text_ofcor_ex
		pop bc
		pop hl
		pop af
		ret

int_text_off	push af,hl,de,bc,ix,iy
		ld a,#34
		ld bc,BORDER
		out (c),a
		exx
		push hl,de,bc
		exx
		exa
		push af
		exa
		call set_256c_mode
		ld hl,47+240-1
		ld b,high GYOFFSL
		out (c),l
		inc b
		out (c),h
music_sw	ld a,0
		or a
		call nz,pt_play

		ld a,(save_mode+1)
		or a
		jr z,int_ex3	
analizator_sw	ld a,1
		or a
		call nz,music_analizator

enter_search_sw	ld a,0
		or a
		call nz,enter_search

int_ex3		ld hl,0
		ld de,int_main
		ld a,1
		ld (int_text_ofcor_ex+1),a
		jp int_ex

pt_play		call set_music_pages_lite
		call music_player_play

autoplay	ld a,1
		or a
		jr z,pt_play_ex

		ld a,(music_setup_vars)
		bit 7,a
		jr z,pt_play_ex
	; loop is passed
		ld a,(sum_list_lines+1)
		dec a
		ld c,a
autoplay_num	ld a,0
		inc a
		cp c
		jr c,1f
		ld a,1
1		ld (autoplay_num+1),a
		call calc_link_num
		ld a,list_ram_page
		call set_page1
		ld h,(ix+4)
		ld l,(ix+3)
		call parse_url
		ld a,1
		ld (load_sw+1),a
pt_play_ex	jp restore_music_pages_lite
/*
SETUP	DB 0 ;set bit0, if you want to play without looping
	     ;(optional);
	     ;set bit1 for PT2 and reset for PT3 before
	     ;calling INIT;
	     ;bits2-3: %00-ABC, %01-ACB, %10-BAC (optional);
	     ;bits4-5: %00-no TS, %01-2 modules TS, %10-
	     ;autodetect PT3 TS-format by AlCo (PT 3.7+);
	     ;Remark: old PT3 TS-format by AlCo (PT 3.6) is not
	     ;documented and must be converted to new standard.
	     ;bit6 is set each time, when loop point of 2nd TS
	     ;module is passed (optional).
	     ;bit7 is set each time, when loop point of 1st TS
	     ;or of single module is passed (optional).
*/

set_256c_mode
		ld bc,VCONFIG
		ld a,VID_256C+VID_320X240 ;VID_NOGFX+
		out (c),a
		ld b,high VPAGE
		ld a,Vid_page
		out (c),a
		ld b,high PALSEL
		xor a
		out (c),a
		ld b,high TSCONFIG
		ld a,TSU_SEN
		out (c),a
		ret

link_highlight_view
		ld a,#0a
		dec a
		ld (link_highlight_view+1),a
		ret nz

1		ld a,(link_highlight+1)
		ld d,a
		ld a,Text_page
		call set_page3_lite
		ld e,#80
		ld hl,highlight_colors_buff
		ld bc,80
		ldir
		xor a
		ld (link_highlight+1),a
		ld a,#0a
		ld (link_highlight_view+1),a
		jp restore_page3

music_analizator
		ld a,Vid_page+9
		call set_page3_lite

		ld hl,0
		ld (analizator_screen_adr),hl
		ld hl,clr_analizator
		call set_ports_nowait		; clear video mem

		ld hl,ay_volume
		push hl
		ld b,3
2		ld a,(hl)
		or a
		jr z,1f
		dec (hl)
1		inc hl
		djnz 2b

		ld hl,ay_volume
		ld de,#0308
ma1		LD BC, #FFFD
		OUT (C), e
		IN A, (C)
		and #0f
		cp (hl)
		jr c,1f
		ld (hl),a
1		inc hl
		inc e
		dec d
		jr nz,ma1

		pop de
		ld hl,analizator_screen_adr
		ld c,3
ma3		ld a,(de)
		inc a
		inc de
		add a,a
		ld b,a
		add #40
ma2		ld (hl),a
		inc hl
		djnz ma2
		ld l,low analizator_screen_adr
		inc h
		inc h
		dec c
		jr nz,ma3
		jp restore_page3
ay_volume	ds 3



; Mouse_proc
/*
1  D0 - левая кнопка
2  D1 - правая кнопка
4  D2 - средняя кнопка

#10-#f0
  D4-D7 - wheel
*/

mouse_buttons
scroll_sw	ld a,0
		or a
		jr z,lmb_old

wheel_old	ld c,#f0
		ld a,(mouse_button)
		cpl
		and #f0
		cp c
		jr z,lmb_old
		ld (wheel_old+1),a
		sub c
		jp m,list_up
		jp nc,list_down
		jp p,list_down
		jp list_up

/*
		jp m,list_down
		jp nc,list_up
		jp p,list_up
		jp list_down
*/
lmb_wait	equ #c

lmb_old		ld a,(mouse_button)
		cpl
		and 1
		cp 1 ; lmb pressed
		jp nz,lmb_release
lmb_counter	ld a,0
		inc a
		cp lmb_wait
		jr z,drag_start
		jr nc,lmb_drag
		ld (lmb_counter+1),a
		ret

drag_start	ld (lmb_counter+1),a
		ld a,(mouse_y)
		ld (drag_start_pos+1),a		; begin pos of drag
		ld (lmb_line_cnt+1),a
		ld (lmb_old_line_cnt+1),a
		ret

lmb_drag	ld a,1
		or a
		ret z
		ld a,(scroll_sw+1)
		or a
		ret z

lmb_line_cnt	ld e,0		; current point of prirost + y_coord
lmb_old_line_cnt
		ld d,0		; old point of prirost + y_coord
		ld a,(mouse_y)
drag_start_pos	sub 0		; begin pos of drag
		ld l,a	
		ld h,high mouse_step
		ld a,e
		add (hl)	; prirost
		ld e,a
		ld (lmb_line_cnt+1),a
		sub d
		jp m,ld10
		cp #10
		jr c,ld2
		jr ld01

ld10		cp #f0
		jr nc,ld2
		neg
		sub #10
		add e
		; ld a,e
		ld (lmb_old_line_cnt+1),a
		call list_down
		jr nz,ld2
		ld (lmb_drag+1),a
		ld (click_offset+1),a
		jr ex_no_offset
; +

ld01		ld a,e
		ld (lmb_old_line_cnt+1),a
		call list_up
		jr nz,ld2
		xor a
		ld (lmb_drag+1),a
		ld (click_offset+1),a
		jr ex_no_offset

ld2		ld a,(lmb_old_line_cnt+1)
		ld c,a
		ld a,(lmb_line_cnt+1)
		sub c
		and #0f
		ld (click_offset+1),a
ex_no_offset	ld a,#02
		jp lmb_ex2

lmb_release
		ld a,(lmb_counter+1)
		or a
		jp z,lmb_ex
		cp lmb_wait-1
		jp nc,lmb_ex

		ld a,(mouse_y)
		cp 4*8
		jp c,menu_click
		cp 240-8
		jp nc,status_click
lmb_click_sw	ld a,1
		or a
		jp z,lmb_ex

		ld a,(mouse_y)
		sub 4*8		; Y offset from menu
click_offset	add 0		; mouse Y offset 0-15
		srl a
		srl a
		srl a
		srl a
		ld c,a
sum_list_lines	ld a,0
		dec a
		ld b,a
		cp c
		jp z,lmb_ex
		jp c,lmb_ex
		ld a,c
; save txt colors buffer
		push bc
		add a,a
		inc a
		add #c0
		ld (link_highlight+1),a
		ld h,a
		ld a,Text_page
		call set_page3_lite
		ld l,#80
		ld de,highlight_colors_buff
		ld bc,80
		ldir
		ld l,#80
		ld a,#0f
1		ld (hl),a
		inc l
		jr nz,1b
		call restore_page3
		pop bc
		ld a,(link_num+1)
		add c
		cp b		; all links counter
		jp z,lmb_ex
		ld c,a
		or a
		jr nz,1f
		ld a,(do_after_load+1)
		cp view_downloaded_list
		jr z,1f
		ld a,1				; start enter search word
		ld (enter_search_sw+1),a
		call set_Textpage_lite
		ld hl,search_textpage_adr
		ld (search_input_adress+1),hl
		ld a,"_"
		ld (hl),a
		inc l
		xor a
		ld b,#40
		ld (hl),a
		inc l
		djnz $-2
		ld hl,highlight_colors_buff+7
		ld b,#40
		ld a,7
2		ld (hl),a
		inc l
		djnz 2b
		jr lmb_ex

1		ld a,(do_after_load+1)
		cp play_music
		jr nz,1f
		ld a,c
		ld (autoplay_num+1),a
1		ld a,c
		call calc_link_num
		ld a,list_ram_page
		call set_page1
		ld h,(ix+4)
		ld l,(ix+3)
		push hl
		ld (main_list_url+1),hl
		ld a,(do_after_link_list+1)	; проверка на файло для закачки
		cp save_file
		jr nz,not_unzip
						; проверка на zip
		ld de,zip_url_buffer_data
		ld bc,#0d0a
		call find_copy_char
		ld a,#0d
		ld (de),a		
		ld hl,zip_url_buffer

not_unzip	call parse_url
		pop hl
		call scan_0d
		ld a,(hl)			; проверка на клик по списку сайтов в разделе
		cp #0d		
		jr nc,1f
		ld (do_after_link_list+1),a	; тип действия для данного сайта
		inc hl
		ld a,(hl)			; пага загрузки для данного сайта
		ld (loadpage_after_link_list+1),a
		ld h,(ix+4)
		ld l,(ix+3)
		ld (main_site_url+1),hl

main_list_url	ld hl,0
		ld (current_list_url+1),hl
		ld bc,#0d0d
		ld de,current_paging_url
		call find_copy_char
		ex de,hl
		ld (hl),"&"
		inc hl
		ld (hl),"p"	; page num
		inc hl
		ld (hl),"="
		inc hl
		ld (current_paging_page+1),hl
		ld (hl),"0"
		inc hl
		ld (hl),"2"
		inc hl
		ld (hl),#0d
		ld a,start_paging_page
		ld (current_list_page+1),a
1		ld a,1
		ld (load_sw+1),a
lmb_ex		
		ld a,1
		ld (lmb_drag+1),a
		dec a
		ld (lmb_counter+1),a
lmb_ex2		ld (mouse_spr+4),a
		ret

status_click
		ld hl,(current_list_url+1)
		ld a,h
		or l
		or a
		jr z,lmb_ex	; url with link list not loaded

		call mouse_x_div8
		cp #0a
		jr c,cancel_download
		cp #19
		jp z,music_play
		cp #1a
		jp z,music_stop
		ld c,a

		ld a,(load_sw+1)	; 1-load now, check for download now 
		or a
		jr nz,lmb_ex

		ld a,c
		cp #21
		jp z,first_page
		cp #22
		jp z,page_back
		cp #27
		jp z,page_forward
		jr lmb_ex

cancel_download	ld a,1
	if cable_zifi=1
		ld (uart.cable_cancel_download+1),a
	else 
		ld (wifi_cancel_download+1),a
	endif
		jr lmb_ex

first_page
current_list_url	
		ld hl,0
		call parse_url
		ld a,start_paging_page
		ld (current_list_page+1),a

paging_page_ex	ld a,1
		ld (load_sw+1),a
		ld a,view_downloaded_list
		ld (do_after_load+1),a
		ld a,download_page
		ld (load_ram_page+1),a
		jp lmb_ex

page_back	ld a,(current_list_page+1)
		dec a
		cp start_paging_page-1		; p=1
		jp z,lmb_ex
		ld (current_list_page+1),a
		jr current_list_page_count

page_forward
current_list_page
		ld a,0
		inc a
		ld (current_list_page+1),a
current_list_page_count
		ld l,a
		ld h,0
current_paging_page
		ld de,0
		ld bc,-10
		call Num1
		ld (de),a
		inc de
		ld c,-1
		call Num1
		ld (de),a
		ld hl,current_paging_url
		call parse_url
		jr paging_page_ex


music_loaded	ld a,1
		ld (music_play+1),a
		xor a
		ld (is_music_play+1),a
		ld hl,(ix+thread.adress)
;		res 7,h
		res 6,h
		ld (music_adr+1),hl
music_play	ld a,0		; music is loaded?
		or a
		jp z,lmb_ex

is_music_play	ld a,0		; music is inited, check pause/play
		or a
		jr nz,pause_music
		ld (do_start_music+1),a
		jp lmb_ex

music_stop	ld a,(music_play+1)
		or a
		jp z,lmb_ex
		ld (do_init_music+1),a
		jp lmb_ex

music_init	call set_music_pages
music_adr	ld hl,0
		call music_player_init
;		call music_player_mute
		call restore_music_pages

;		ld hl,SETUP
;		res 0,(hl)		; loop mode
		ld a,1
		ld (music_sw+1),a
		ld (is_music_play+1),a
		ld (do_start_music+1),a
		ret

pause_music	ld a,0
		cpl
		ld (pause_music+1),a
		or a
		jr nz,pause_music1

		ld a,1
		ld (music_sw+1),a
		jp lmb_ex

pause_music1	xor a
		ld (music_sw+1),a
		call set_music_pages
		call music_player_mute
		call restore_music_pages
		jp lmb_ex

menu_click	srl a
		srl a
		srl a
		srl a
		ld c,a
		ld a,(load_sw+1)	; 1-load now, check for download now 
		or a
		jp nz,lmb_ex
		ld a,c
		call mouse_x_div8
		cp 11
		jp c,lmb_ex
		cp 29
		jp nc,lmb_ex		; empty left/right menu

		cp 21	; download / graphics
		jr c,menu_first
		cp 23	; music/press
		jp c,lmb_ex	; subdivider

menu_two	ld a,c
		or a
		jr nz,menu_two_gfx
		ld a,music_sites

menu_sw		ld (sites_sw+1),a
		ld a,download_page
		ld (load_ram_page+1),a
		xor a
		ld (link_num+1),a
		inc a
		ld (lmb_click_sw+1),a
		xor a
		ld (do_after_link_list+1),a	; тип действия для данного сайта
		jp lmb_ex

menu_two_gfx	ld a,press_sites
		jr menu_sw

menu_first	ld a,c
		or a
		jr nz,menu_first_music
		ld a,download_sites
		jr menu_sw

menu_first_music
		ld a,gfx_sites
		jr menu_sw

mouse_x_div8
		ld hl,(mouse_x)
		or a
		srl h
		rr l
		srl h
		rr l
		srl h
		rr l
		ld a,l
		ret

key_wait	equ #07

enter_search	ld a,1
		dec a
		ld (enter_search+1),a
		ret nz
		inc a
		ld (enter_search+1),a

		call Read_Keyboard
		or a
		ret z
		cp enter
		jr nz,es1
		xor a			; press ENTER
		ld (enter_search_sw+1),a
		ld hl,search_textpage_adr
		ld (search_input_adress+1),hl
main_site_url	ld hl,0
		ld bc,#0d0d
		ld de,search_url
		push de
		call find_copy_char
		ex de,hl
		ld (hl),"&"
		inc hl
		ld (hl),"s"	; page num
		inc hl
		ld (hl),"="
		inc hl
		ex de,hl
		ld hl,search_textpage_adr
		call copy_ini
		dec de
		ld a,#0d
		ld (de),a
		pop hl
		ld (main_list_url+1),hl
		ld a,view_downloaded_list
		ld (do_after_load+1),a
		ld a,download_page;	list_ram_page
		ld (load_ram_page+1),a
		call parse_url
		jp main_list_url		; готовим строку поиска

es1		cp del
		jr nz,es2
		ld hl,(search_input_adress+1)
		ld a," "
		ld (hl),a
		dec l
		ld a,l
		cp #08		; начало строки поиска - 1
		jr nc,search_input_adress2
		ld hl,search_textpage_adr
		jr search_input_adress2

es2		cp #20
		ret c
		push af
		call set_Textpage_lite
		pop af

search_input_adress	
		ld hl,search_textpage_adr
		ld (hl),a
		inc l
		ld a,l
		cp #08+32
		ret z
search_input_adress2
		ld (search_input_adress+1),hl
search_input_adress3
		ld a,"_"
		ld (hl),a
		ld a,key_wait
		ld (enter_search+1),a
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

mouse_show_sw	ld a,0
		or a
		ret nz
		ld hl,sprites
		jp set_ports

/*
  D0 - левая кнопка
  D1 - правая кнопка
  D2 - средняя кнопка

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

		LD     BC,#FBDF
		IN     A,(C)
MOUSE11		LD     d,0
		LD     (MOUSE11+1),A
		sub d
		CALL   NZ,MOUSE_X_vector
		LD     B,#FF
		IN     A,(C)

;		call key_scan

MOUSE12		LD     D,0
		LD     (MOUSE12+1),A
		SUB    D
		CALL   NZ,MOUSE_Y_vector
		RET

MOUSE_X_vector	JP M,MOUSE35	; Sign Negative (M)
		ld e,a
		ld d,0
		ld hl,(mouse_x)
		add hl,de
		ld (mouse_x),hl
		ld de,320
		sub hl,de
		ret c
1		ld hl,320-1
		jr 1f

MOUSE35		neg
		ld e,a
		ld d,0
		or a
		ld hl,(mouse_x)
		sub hl,de
		jr nc,1f
		ld hl,0
1		ld (mouse_x),hl
		RET

MOUSE_Y_vector
		JP M,MOUSE45
		ld e,a
		ld d,0
		or a
		ld hl,(mouse_y)
		sub hl,de
		jr nc,2f
		ld hl,0
2		ld (mouse_y),hl
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
		ld hl,240-1
		jr 2b



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
		ld hl,int_gfx_view
		ld (#beff),hl
		im 2
		ret

fill_ports	out (c),a
		inc b
		dec e
		jr nz,$-4
		ret

Read_Keyboard	LD HL,Keyboard_Map      ; Point HL at the keyboard list
                LD D,8                  ; This is the number of ports (rows) to check
                LD C,#FE                ; C is always FEh for reading keyboard ports
Read_Keyboard_0	LD B,(HL)               ; Get the keyboard port address from table
                INC HL                  ; Increment to list of keys
                IN A,(C)                ; Read the row of keys in
                AND #1F                 ; We are only interested in the first five bits
                LD E,5                  ; This is the number of keys in the row
Read_Keyboard_1 SRL A                   ; Shift A right; bit 0 sets carry bit
                JR NC,Read_Keyboard_2   ; If the bit is 0, we've found our key
                INC HL                  ; Go to next table address
                DEC E                   ; Decrement key loop counter
                JR NZ,Read_Keyboard_1   ; Loop around until this row finished
                DEC D                   ; Decrement row loop counter
                JR NZ,Read_Keyboard_0   ; Loop around until we are done
                AND A                   ; Clear A (no key found)
                RET

Read_Keyboard_2
		ld a,(hl)
		cp "0"
		ret nz
		ld bc,#fefe
		in a,(c)
		bit 0,a
		ld a,(hl)
		ret nz
		ld a,del
                RET
/*
		ld d,0
		ld bc,#fefe                               ; check for CAPS SHIFT
		in a,(c)
		bit 4,a
		jr nz,1f
		ld d,#30
1		ld a,d
		add e
*/
Keyboard_Map:       
		DB #FB,"q","w","e","r","t"
		DB #F7,"1","2","3","4","5"
		DB #EF,"0","9","8","7","6"
		DB #DF,"p","o","i","u","y"
		DB #BF,enter,"l","k","j","h"
		DB #7F," ",sym,"m","n","b"
		DB #FD,"a","s","d","f","g"
		DB #FE,caps,"z","x","c","v"
caps	equ #01
sym	equ #02
enter	equ #0d
del	equ #0c
/*
   Рассмотрим рисунок клавиатуры:

N:БИТA| 0| 1| 2| 3| 4| 4| 3| 2| 1| 0|
------+--+--+--+--+--+--+--+--+--+--+   N_
N_  3 | 1| 2| 3| 4| 5| 6| 7| 8| 9| 0| 4 П
П     +--+--+--+--+--+--+--+--+--+--+   О
О   2 | Q| W| E| R| T| Y| U| I| O| P| 5 Л
Л     +--+--+--+--+--+--+--+--+--+--+   У
У   1 | A| S| D| F| G| H| J| K| L|ENT 6 Р
Р     +--+--+--+--+--+--+--+--+--+--+   Я
Я   0 |CS| Z| X| C| V| B| N| M|SS|SPC 7 Д
Д     +--+--+--+--+--+--+--+--+--+--+   А
А
         3-#F7             4-#EF
         2-#FB             5-#DF
         1-#FD             6-#BF
         0-#FE             7-#7F
*/


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
		xor a
		call set_page0
		call im2_init
		call mouse_pos
		ld bc,PAGE3
		ld a,Vid_page
		out (c),a
		ld hl,#0000		;1111 - white
		ld (#c000),hl
		ld hl,init_ts
		call set_ports
		ld hl,all_pals
		call set_ports		
		ld hl,splash_copy
		jp set_ports

gfx_init	ld hl,cursor_copy
		call set_ports
		ld hl,menu_copy
		call set_ports
		ld hl,status_copy
		call set_ports
		ld hl,mouse_step
		xor a
1		ld b,4
		ld (hl),a
		inc l
		djnz $-2
		ld (hl),a
		inc a
2		inc l
		bit 7,l
		jr z,1b
		ld l,#80
		ld d,h
		ld e,#80
3		ld a,(hl)
		neg
		ld (de),a
		inc e
		dec l
		jr nz,3b
		xor a
		ld (lmb_click_sw+1),a
		ret

init_ts		db #20,6
		db high BORDER,#f0	; border
		db high SGPAGE, Sprite_page
		db high CacheConfig,#0c	; cache for #8000 - #c000


clr_gfx256_screen
		defb #1a,0	;
		defb #1b,0	;
		defb #1c,Vid_page	;
		defb #1d,0	;
		defb #1e,0	;
		defb #1f,Vid_page	;
		defb #26,#ff	;
		defb #28,#ff	;
		defb #27,%00000100
		db #ff

clr_load_mem	defb #1a,0	;
		defb #1b,0	;
clr_load_mem1	defb #1c,0	;
		defb #1d,0	;
		defb #1e,0	;
clr_load_mem2	defb #1f,0	;
		defb #26,#ff	;
		defb #28,32-1	;
		defb #27,%00000100
		db #ff


gfx_copy	db #1a,0
		db #1b,0	;#0210 - данные битмап
		db #1c,download_page
		db #1d,0
		db #1e,0
		db #1f,Gfx_vid_page
gfx_copy_w	db high DMALEN,0
gfx_copy_h	db high DMANUM,0
gfx_copy_type	db #27,DMA_RAM + DMA_DALGN;+DMA_ASZ
		db #ff

view_image_pals
		db #1a,0
		db #1b,0
		db #1c,download_page
		db #1d,0
view_image_pals_vpal_adr
		db #1e,1
		db #1f,0
view_image_pals_vpal
		db #26,#1f
		db #28,0
		db #27,#84
		db #ff

clr_gfx_screen
		defb #1a,0	;
		defb #1b,0	;
		defb #1c,Gfx_vid_page	;
		defb #1d,0	;
		defb #1e,0	;
		defb #1f,Gfx_vid_page	;
		defb #26,#ff	;
		defb #28,#ff	;
		defb #27,%00000100
		db #ff

clr_analizator	defb #1a,low analizator_screen_adr	;
		defb #1b,high analizator_screen_adr	;
		defb #1c,Vid_page+9
		defb #1d,low analizator_screen_adr	;
		defb #1e,high analizator_screen_adr	;
		defb #1f,Vid_page+9
		defb high DMALEN ,#f	;
		defb high DMANUM,3-1	;
		defb #27,DMA_FILL+DMA_ASZ+DMA_DALGN
		db #ff

clr_text_screen
		defb #1a,0	;
		defb #1b,0	;
		defb #1c,Text_page	;
		defb #1d,0	;
		defb #1e,0	;
		defb #1f,Text_page	;
		defb #26,#ff	;
		defb #28,32-1	;
		defb #27,%00000100
		db #ff

link_page_copy	db #1a,0
		db #1b,0
		db #1c,download_page
		db #1d,0
		db #1e,0
		db #1f,list_ram_page
		db #26,#ff
		db #28,32-1
		db #27,DMA_RAM
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

menu_copy	db #1a,0
		db #1b,0
		db #1c,menu_gfx_page
		db #1d,0
		db #1e,0
		db #1f,Vid_page
		db #26,320/2-1
		db #28,32-1
		db #27,DMA_RAM + DMA_DALGN +DMA_ASZ
		db #ff

splash_copy	db #1a,0
		db #1b,0
		db #1c,splash_gfx_page
		db #1d,40
		db #1e,0
		db #1f,Vid_page+2
		db #26,240/2-1
		db #28,109-1
		db #27,DMA_RAM + DMA_DALGN +DMA_ASZ
		db #ff

status_copy	db #1a,0
		db #1b,#28
		db #1c,menu_gfx_page
		db #1d,0
		db #1e,#3e-2
		db #1f,Vid_page+8
		db #26,320/2-1
		db #28,9-1
		db #27,DMA_RAM + DMA_DALGN +DMA_ASZ
		db #ff

status_icon_copy
		db #1a,0
		db #1b,0
		db #1c,2 
		db #1d,4
		db #1e,#3e-2
		db #1f,Vid_page+8
		db #26,10/2-1
		db #28,9-1
		db #27,DMA_BLT + DMA_DALGN +DMA_ASZ
		db #ff



sprites		db #1a,low spr_db
		db #1b,high spr_db
		db #1c,2
		db #1d,0
		db #1e,2
		db #1f,0
		db #26,#ff
		db #28,0
		db #27,DMA_RAM_SFILE
		db #ff
all_pals
		db #1a,low all_pal_bin
		db #1b,high all_pal_bin
		db #1c,2
		db #1d,0
		db #1e,0
		db #1f,0
		db #26,(256/2)-1
		db #28,0
		db #27,#84
		db #ff

zx_pals
;		db #1a,low all_pal_bin
;		db #1b,high all_pal_bin
;		db #1c,2
		db #1d,#e0
		db #1e,1
		db #1f,0
		db #26,#0f
		db #28,0
		db #27,#84
		db #ff

text_up_copy	db #1a,0
		db #1b,window_start_Y+2
		db #1c,Text_page
		db #1d,0
		db #1e,window_start_Y
		db #1f,Text_page
		db #26,#80-1
		db #28,window_height*2-1	;-1
		db #27,DMA_RAM
		db #ff

text_down_copy	db #1a,0	;low #c000+window_height*2*256
		db #1c,Text_page
		db #1d,0	;low #c200+window_height*2*256
		db #1f,Text_page
		db #26,#7f
		db #28,0
		db #ff

		include "../includes.asm"
		include "../tsconfig.asm"


mouse_button	db 0
/*
  D0 - левая кнопка
  D1 - правая кнопка
  D2 - средняя кнопка
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
spr_db_end



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
str_ipd		db "+IPD,",0

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

sd_init
		ld a,sd_driver_page
		call set_page0
		CALL DOS_SWP; DEPACK Driver
		CALL DEV_INI
		JP NZ,ER0
		CALL HDD
		JP NZ,ER1
		CALL SETROOT; SET ROOT DIR
		jp sd_exit

/*
[17:37:51] Koshi: ну вначале зайди в папко
[17:37:55] Koshi: где файло настроек
[17:38:02] Koshi: чтобы зайти в папко ннадо сделать
[17:38:08] Koshi: LD HL,DIR1
        CALL FENTRY
[17:38:13] Koshi: затем CALL SETDIR
[17:38:35] Koshi: затем запустить LD HL,FILE_INI:CALL FENTRY
[17:38:40] Koshi: и тока потом уже можна LOAD512
[17:38:48] Koshi: если конечно файл нашелся
[17:39:23] Koshi: FENTRY ищет файлы/каталоги
[17:39:29] Koshi: и выдает длину оных в ответ
[17:39:43] Koshi: плюс позиционирует на них
[17:39:58] Koshi: но LOAD512 сразу после FENTRY, када искали дир
[17:40:03] Koshi: буит читать САМ дир
[17:40:10] Koshi: аля содержимое низкоуровневое дира
[17:40:20] Koshi: чтобы перейти на дир
[17:40:23] Koshi: надо сетнуть его
[17:40:26] Koshi: и потом уже в НЕМ
[17:40:28] Koshi: искать файло
[17:40:34] Koshi: по то му же FENTRY
*/

on_int_dma	ld a,1
		jr sw_int_dma
off_int_dma	xor a
sw_int_dma	ld (save_mode+1),a
	;	ld (analizator_sw+1),a
;		ld (mouse_sw+1),a
		jp wait_frame


save_downloaded_file	; ld de,10884	; file lenght 
		call off_int_dma
		ld de,disk_icon
		call set_icon
		ld ix,read_threads
		ld de,(ix+thread.full_len)
		ld hl,FILE+1
		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		ld a,(ix+thread.full_len_high)
		ld (hl),a
;		ld (save_over_64+1),a
;		ld c,a
		ex de,hl
		ld d,0
		ld e,a
		call DEL512  ;i:[DE,HL]/512 	
/*
		ld a,e
		or a
		jr z,1f
		inc d
1		bit 0,d
		jr z,1f
		inc d
1		srl c
		rr d		; d= sectors (512bytes)
*/
		push hl
;Create File (flag,size,name,0):
		ld a,sd_driver_page
		call set_page0
		LD HL,FILE
		CALL MKFILE
		pop bc		; bc= num sectors
		JP Z,1f
				;File Creation Failed
/*
[15:50:27] Way Be: если файло есть, то ;File Creation Failed получаем, так?
[15:50:55] Koshi: и смотрим в A код ошибке
[15:51:01] Koshi: если 3 - то имя уже занято

;i: HL - flag(1),ln(4),name(1-255),0
;   NZ - ERROR (NO ENOUGHT SPACE)
;        A: 1 - ln not valid
;           2 - index fatality
;           3 - ln already exists
;         255 - unknown error
;    Z - SUCCESS
MKFILE  EQU CORE+57
*/
		cp 3
		jr z,2f
		cp 4
		jr z,2f
		LD A,5:OUT (254),a
		jr 2f
1
; check size>64kb
/*
save_over_64	ld a,0
		or a
		jr z,save_64
*/
		ld a,b
		or a
		jr z,save_64
;Save data into new file >128kb:
		ld a,c
		push af
		ld c,(ix+thread.page)
		ld hl,(ix+thread.adress)
		ld a,b
3		push af
		ld b,#80
		call SAVE512
		ld b,#80
		call SAVE512		
		pop af
		dec a
		jr nz,3b
		pop af
		or a
		jr z,3f
		ld b,a
		jr 2f

;Save data into new file <128kb:
save_64		ld b,c
		ld c,(ix+thread.page)
		ld hl,(ix+thread.adress)
2		call SAVE512
3
/*
[11:50:29] Koshi: просто пишешь до посинения
[11:50:35] Koshi: пока цепочка не кончиццо
[11:50:59] Koshi: када цепочки конец - сейв512 и лоад512 выдадут в А=#0F
*/
		ld hl,status_copy		; clear statusbar gfx
		call set_ports

		call on_int_dma
		jp sd_exit

DEL512  ;i:[DE,HL]/512
        LD A,L,L,H,H,E,E,D,D,0
        LD BC,1:OR A:CALL NZ,ADD4B
        LD A,2

DELITX2 ;i:[DE,HL]/A
;                A - Power of Two
;        o:[DE,HL]

        CP 2:RET C
        LD C,0
        SRL A
L33T    SRL D:RR E,H,L,C
        SRL A:JR NC,L33T

        LD A,C:OR A:RET Z
        LD BC,1:CALL ADD4B
        RET

ADD4B   ADD HL,BC:RET NC:INC DE
        RET
; читаем настройки:
load_ini
		ld a,sd_driver_page
		call set_page0
		LD HL,DIR2
		CALL FENTRY
		CALL SETDIR
		LD HL,FILE_INI
		CALL FENTRY
		LD C,download_page	; page ini
		LD HL,#0000
		LD B,#32
		CALL LOAD512
		CALL SETROOT; возвращаемся в коневой
		jp sd_exit
/*
читаем настройки:
        LD HL,DIR_INI
        CALL FENTRY
        CALL SETDIR
        LD HL,FILE_INI
        CALL FENTRY
        LD C,0
        LD HL,0
        LD B,X
        CALL LOAD512
        CALL SETROOT; возвращаемся в коневой
*/

;CALL VYGREB; Выгребаем каталог, чисто по приколу

;LD HL,FILENAM ; ищем файл
;CALL FENTRY:JP Z,ER2
;LD HL,#1000,C,#02 ; читаем файл (1 блок, 512 байт)
;LD B,1:CALL LOAD512

current_dir	call SETDIR
		jr sd_exit 

; переходим в папку
set_download_dir
		ld a,sd_driver_page
		call set_page0
		call SETROOT
		LD HL,DIR1
		CALL FENTRY
		jp nz,current_dir; Set DIR found by FENTRY active
		LD HL,DIR1+1
		CALL MKDIR
		JR Z,set_download_dir
		JP ER3

;---------------------------------------
sd_exit    ;LD BC,#11AF,A,#05:OUT A

;       LD BC,MEMCONFIG
;       ld A,%00000001
;       OUT (c),A
		xor a
		jp set_page0
;LD BC,#12AF,A,#0F:OUT A


;---------------------------------------
/*
VYGREB  LD DE,#8000
VYG     CALL NXTETY:RET Z
        LD A,D:CP #C0:RET NC
        JR VYG
*/
;---------------------------------------
ER0     ;Device not found
;       (SD Card NOT ready!)
		LD A,1:OUT (254),a
		JP sd_exit
;-------
ER1     ;FAT32 NOT FOUND

		LD A,2:OUT (254),a
		JP sd_exit
;-------
ER2     ;File NOT FOUND

		LD A,3:OUT (254),a
		JP sd_exit
;-------
ER3     ;Dir Creation Failed

		LD A,4:OUT (254),a
		JP sd_exit
;-------
ER4     ;File Creation Failed
/*
[15:50:27] Way Be: если файло есть, то ;File Creation Failed получаем, так?
[15:50:55] Koshi: и смотрим в A код ошибке
[15:51:01] Koshi: если 3 - то имя уже занято
*/
		LD A,5:OUT (254),a
		JP sd_exit

;---------------------------------------
/*
FILENAM		DB #00; 0 - file, 1 - DIR
		DB "WC_History.txt",0
*/

FILE		DB #00;        flag
;		DW #1000,#0000;length - 4kb
		DW #0000,#0000;length
FILE_NAME	ds 48
		db 0

/*
[14:12:36] Koshi: младший, старший вестимо
[14:12:42] Way Be: ок
[14:12:46 | Змінено в 14:12:49] Koshi: #0000 1000 = 4кб
[14:13:03] Koshi: в примере же написано		
*/

FILE_INI	DB #00; 0 - file, 1 - DIR
		DB "zifi.ini",0

update_file	DB #00; 0 - file, 1 - DIR
	if cable_zifi=1
		DB "zifi_rs.spg",0
	else
		DB "zifi.spg",0		
	endif

DIR1		DB #10
		DB "downloads",0

DIR2		DB #10
		DB "zifi",0

;---------------------------------------
CORE    EQU #2002
DEV_INI EQU CORE+3
HDD     EQU CORE+9
;-------
;i: CHL - Addres
;     B - lenght (512b blocks)
;o: CHL - New Value
;     A - EndOfChain (#0F)
LOAD512 EQU CORE+21

;i: CHL - Addres
;     B - lenght
;o: CHL - New Value
;     A - EndOfChain (#0F)
SAVE512 EQU CORE+24

DOS_SWP EQU CORE+27

;i: HL - flag(1),ln(4),name(1-255),0
;   NZ - ERROR (NO ENOUGHT SPACE)
;        A: 1 - ln not valid
;           2 - index fatality
;           3 - ln already exists
;         255 - unknown error
;    Z - SUCCESS
MKFILE  EQU CORE+57

;i: HL - DirName(1-255,0)
;o: NZ - ERROR
;        A: 1 - ln not valid
;           2 - index fatality
;           3 - ln already exists
;         255 - unknown error
;    Z - SUCCESS
MKDIR   EQU CORE+60

;i: HL - flag(1),name(1-255),0
;o:  Z - NOT FOUND
;   NZ - FILE DELETED
DELFL   EQU CORE+63

;i: HL - flag(1),oldname(1-255),0
;   DE - newname(1-255),0
;o:  Z - NOT FOUND
;   NZ - SUCCESS
RENAM   EQU CORE+66

;Search for entry in current DIR
;i: HL - flag(1),name(1-255),0
;o:  Z - NOT FOUND
;   NZ - [DE,HL] - file length
;        SEEK0 is automatically called
FENTRY  EQU CORE+78

;Seek/Skip N sectors
;i: B - Number of sectors to process
LOADNON EQU CORE+84

;GetNextEntryFromActiveDir
;i: DE - Addres
;o: DE - New Value
;    Z - EndOfDir
;   NZ - OK
;
;STRUCTURE:
;fclus(4),size(4),date(2),time(2),
;!flag(1),name(1-255),#00
NXTETY  EQU CORE+87

;Set DIR found by ENTRY active
SETDIR  EQU CORE+93

;Set ROOT DIR active
SETROOT EQU CORE+96

SEEK0   EQU CORE+99

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



read_threads	ds 6*5
		db #ff



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
		call set_Textpage
		ld hl,cmd_at
		call zifi_send_echo
;ld hl,cmd_uart
;		call zifi_send
		ld hl,cmd_gmr
		call zifi_send_echo
		ld hl,cmd_cwmode
		call zifi_send_echo
		ld hl,cmd_cwautoconn
		call zifi_send_echo
		ld hl,cmd_cipmux
		call zifi_send_echo
;		ld hl,cmd_cwqap	; Disconnect from AP 
;		call zifi_send
;		ld b,25
;		call wait
;		call zifi_check_receive_command
;	ret
		ld hl,cmd_cwjap	; AT+CWJAP_CUR . Connect to AP, for current
		call zifi_send_echo

2		call zifi_check_receive_command
		ld de,str_ok
        	call buffer_cmp
        	cp low output_buff+#bf
        	jr z,2b
;		ld b,25
;		call wait
;		ld hl,cmd_cipsta	; is Set IP address of station ?
;		call zifi_send
;		call zifi_check_receive_command
		ret
/*
		ld b,25
		call wait
		ret
*/

zifi_error
		ret


/*
Address         Mode Name Description
0x00EF..0xBFEF  R    DR   Data register (ZIFI or RS232).
                          Get byte from input FIFO.
                          Input FIFO must not be empty (xx_IFR > 0).
0x00EF..0xBFEF  W    DR   Data register (ZIFI or RS232).
                          Put byte into output FIFO.
                          Output FIFO must not be full (xx_OFR > 0).

Address Mode Name   Description
0xC0EF  R    ZF_IFR ZIFI Input FIFO Used Register. Switch DR to ZIFI FIFO.
                    0 - input FIFO is empty, 191 - input FIFO contain 191 or more bytes.
0xC1EF  R    ZF_OFR ZIFI Output FIFO Free Register. Switch DR to ZIFI FIFO.
                    0 - output FIFO is full, 191 - output FIFO free 191 or more bytes.
0xC2EF  R    RS_IFR RS232 Input FIFO Used Register. Switch DR to RS232 FIFO.
                    0 - input FIFO is empty, 191 - input FIFO contain 191 or more bytes.
0xC3EF  R    RS_OFR RS232 Output FIFO Free Register. Switch DR to RS232 FIFO.
                    0 - output FIFO is full, 191 - output FIFO free 191 or more bytes.

Address Mode Name   Description
0xC7EF  W    CR     Command register. Command set depends on API mode selected.

  All mode commands:
    Code     Command      Description
    000000oi Clear ZIFI FIFOs
             i: 1 - clear input ZIFI FIFO,
             o: 1 - clear output ZIFI FIFO.
    000001oi Clear RS232 FIFOs
             i: 1 - clear input RS232 FIFO,
             o: 1 - clear output RS232 FIFO.
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

--------------------------------------------------------------------------------

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






;; PSB com driver	---------------------------------
	IF cable_zifi 

	include "_rs232/sockets.mac"
psb_start	jp init
psb_get		jp get

init
        ;init uart
        ld hl,1 ;BaudRate = 115200 / divfq;
        call uart.SetBaud

	;init uart
	ld a,uart.WLSB1+uart.WLSB0 ;8 bit word, no parity
	call uart.SetLineControl

	ret

; BUFFER equ 0
; BUFFER_SIZE equ 1

GET_HDR dw 0
GET_HDR_LEN dw 0
GET_PAGE db 0
host_addr_len dw 0
host_addr dw 0

;in:
;a=page
;hl=get hdr
;out:
;a=0 - ok
;hl=len_l
;bc=len_h
get
	ld (GET_HDR),hl
	ld (GET_PAGE),a
;get host name
g1	ld a,(hl)
	or a:jp z,get_err
	cp 'H':jr z,get_h1
	inc hl:jr g1

get_h1  inc hl
	ld a,(hl):cp 'o':jr nz,g1:inc hl
	ld a,(hl):cp 's':jr nz,g1:inc hl
	ld a,(hl):cp 't':jr nz,g1:inc hl
	ld a,(hl):cp ':':jr nz,g1:inc hl
	ld a,(hl):cp ' ':jr nz,g1:inc hl

	ld (host_addr),hl
	ld bc,0
gh1 	ld a,(hl):cp 13:jr z,ghe
	cp ":":jr z,ghe
	cp "/":jr z,ghe ;?
	inc hl,bc:jr gh1

ghe 	ld (host_addr_len),bc

;get HDR len
g2	ld a,(hl)
	or a:jr z,g3
	inc hl:jr g2

g3	ld de,(GET_HDR):or a:sbc hl,de:ld (GET_HDR_LEN),hl

	;gethostbyname
	ld hl,(host_addr),bc,(host_addr_len)
	call sockets.gethostbyname
	or a:jp nz,get_err
	ld (server_addr),hl,(server_addr+2),bc

	;create socket
	socket AF_INET,SOCK_STREAM,0
	cp INVALID_SOCKET:jp z,get_err
	ld (fd),a

	;bind my socket
	bind fd,my_addr
	or a:jp nz,get_err

	;connect to host
	connect fd,server_addr
	or a:jr nz,get_err

	;send HTTP request
	send fd,(GET_HDR),(GET_HDR_LEN)
	or a:jr nz,get_err

	ld ix,0 ;full pages got
	ld hl,#c001		; 		----------- !!!!!!!!!! align 2 fix ------------------
get_loop
	ld a,(GET_PAGE)
	call set_page3
	ld de,#0000:ex de,hl:or a:sbc hl,de:ex de,hl ;de=len,hl=start
	;recv data
; 	recv fd,BUFFER,BUFFER_SIZE
	push hl
	ld b,d,c,e
	ld a,(fd)
	call sockets.recv
	pop hl
	or a:jr nz,get_end
;	ld a,b:or c:jr z,get_end
	call view_progress_bar
	add hl,bc

	ld a,h
	or a
	jr nz,get_loop

	ld hl,GET_PAGE:inc (hl)
	ld hl,#c000
	inc ixl
        jr get_loop

get_end ;res 6,h:res 7,h
	ld a,h
	and #3f
	ld h,a
	ld de,0,b,0,c,ixl
	srl c:rr d:rr e
	srl c:rr d:rr e
	add hl,de ;bc:hl=len


get_e	ld a,(fd):cp #ff:jr z,noclose
	push hl,bc
	;close socket
	close fd
	pop bc,hl
noclose ld a,#ff,(fd),a
	xor a
	ret


get_err call get_e
	inc a
	ret

cable_cancel_download_ex
		ld sp,#bfff
		xor a
		ld (uart.cable_cancel_download+1),a
		ld (load_sw+1),a
		close fd
		call noclose
		ld hl,status_copy		; clear statusbar gfx
		call set_ports
		jp main

;-----------------------------------------------------------

fd	db #ff ;socket fd
my_addr	db 0,0,0,0:dw 0 ;my ip+port

server_addr db 93,158,134,3:dw 80

;code
	include "_rs232/uart.a80"
	include "_rs232/sockets.a80"

; PSB com driver  ---------------------
	ENDIF


		align 2 
download_icon	incbin "_spg/download.tga.pix"
disk_icon	incbin "_spg/disk.tga.pix"

highlight_colors_buff	ds 80
link_adreses		ds 256
		align 256
output_buff		ds #100
	
end

music_player		equ #c000
music_player_init	equ @music_player+3
music_player_play	equ @music_player+5
music_player_mute	equ @music_player+8
music_setup_vars	equ music_player+#55

/*
	; uni player
		org #c000
music_player		INCLUDE	"_pt\ptx.asm"

music_player_init	equ @music_player+3
music_player_play	equ @music_player+5
music_player_mute	equ @music_player+8
music_setup_vars	equ music_player+#55
music_players_end
		SAVEBIN "_spg/ptplay.bin",music_player, music_players_end-music_player
*/

	IF cable_zifi 
		SAVEBIN "_spg/zifi_rs.bin",start, end-start
	ELSE 
		SAVEBIN "_spg/zifi.bin",start, end-start
	ENDIF
		
