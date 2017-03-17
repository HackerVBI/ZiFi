		device zxspectrum128

page_for_download	equ #20


		org #8000
start 
; memory init
		ld bc,MEMCONFIG
		ld a,%00001110
		out (c),a
		xor a
		call set_page0

		call init_zifi

; create http 
		ld hl,test_url
		call parse_url

; set page for download data
		ld a,page_for_download
		ld (zipd_page+1),a

		call get_url

; lenght of received data: #00 : #0000
		ld a,(readed_len_high+1)	; high byte lenght
		ld hl,(readed_len_low+1)	; low word lenght
		ret


test_url	db "http://ts.retropc.ru/zifi_ver.php?w=0.730",#0d

init_zifi	ld      bc,#c7ef
		ld      de,#fff1
		out     (c),e           ;Set API mode 1
		out     (c),d           ;Get Version
		in      a,(c)
		cp      #ff
		jp      z,nozifi
		ld      a,#01
		out     (c),a           ;Clear RX FIFO
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
		ld hl,cmd_cwjap		; AT+CWJAP_CUR . Connect to AP, for current
		call zifi_send

2		call zifi_check_receive_command
		ld de,str_ok
        	call buffer_cmp
        	jr nz,2b
        	ret			; we all connected, OK 0:1


nozifi		ld hl,conf_not_found_msg	; old rs232 port, cancel
		jr $

conf_not_found_msg
		db "Error: Please update TS Conf.",0



// send and receive data without header

get_url		ld hl,cmd_conn2site	; AT+CIPSTART	- connect to site
		call zifi_send

		ld de,str_error
		call buffer_cmp
		jr nz,zg_ok

		ld hl,cmd_cipclose
		call zifi_send
1		ld de,str_ok
		call buffer_cmp
		jr z,get_url
		call wait_frame
		call fifo_inir
		jr 1b

zg_ok		ld de,str_ok
        	call buffer_cmp
		jr nz,get_url

1		ld hl,cmd_cipsend	; AT+CIPSEND=<link ID>,<length>
		call zifi_send_raw
2		call fifo_inir
		ld de,str_ok
        	call buffer_cmp
        	jr nz,2b
1		ld a,(hl)
		inc hl
		cp #ff
		jr z,2b
		cp ">"		
		jr nz,1b

; send http request
		ld hl,modem_command
		call zifi_send_raw
1
		call zifi_getchar
		cp "O"
		jr nz,1b
		call zifi_getchar
		cp "K"
		jr nz,1b		

// receive header
first_ipd
		call reread_ipd
2
; skip data
		call read_fifo_char
		dec hl
		cp #0d
		jr nz,2b
		call read_fifo_char
		dec hl
		cp #0a
		jr nz,2b		
		call read_fifo_char
		dec hl
		cp #0d
		jr nz,2b
		call read_fifo_char
		dec hl
		cp #0a
		jr nz,2b
// header skipped --------------------
		ld a,h
		or l
		jr z,read_all_ipds
		ld (zipd_full_len+1),hl
		jr zipd_adr

// receive data
read_all_ipds	call reread_ipd
zipd_adr	ld hl,#0000		; adress for receive data ----------------------
zipd_full_len	ld de,0			; ipd len
p231		ld bc,zifi_input_fifo_status
1		in a,(c)
		or a			; 0 - input FIFO is empty,
		jr z,1b
p232		cp      0xbf            ; BIG THANKS FOR DDp for his MIGHTY code!
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
1	        jp read_all_ipds




read_fifo_char	ld bc,zifi_input_fifo_status	; ждём прихода данных в фифо
3		in a,(c)
		jr z,3b				; 0 - input FIFO is empty,
		ld b,0
		in a,(c)
		ret



reread_ipd	ld e,#ff
		ld hl,output_buff
		call rdipd
		ld de,CLOSED
		call buffer_cmp
;		or a			; CLOSED, exit
		jp z,zifi_read_ipd_ex
		ld de,str_ipd
		call buffer_cmp
		jr nz,reread_ipd
		ex de,hl
		call count_ipd_lenght		; in HL - lenght of ipd packet
		ld (zipd_full_len+1),hl
		ret

zifi_read_ipd_ex	
		pop af
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
		call zifi_input_fifo_check
		or a
		jr z,zifi_getchar
		ld      b,0
		in      a,(c)
		dec     b
		ret

count_ipd_lenght
		ld hl,0			; count lenght
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
		jr z,buffer_cmp_notfound
		inc hl
		jr buffer_cmp0
buffer_cmp_notfound
		or a
		ret

buffer_cmp1	inc de
		inc hl
		ld a,(de)
		or a
		ret z
		cp (hl)
		jr nz,buffer_cmp_start
		jr buffer_cmp1	


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
		call wait_frame
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



wait_frame	halt
		ret

set_page0	ld bc,PAGE0
		out (c),a
		ret

set_page1	ld bc,PAGE1
		out (c),a
		ret


zifi_command_reg		equ #C7EF
zifi_error_reg			equ #C7EF
zifi_data_reg			equ #BFEF
zifi_input_fifo_status		equ #C0EF
zifi_output_fifo_status		equ #C1EF


cmd_clear_input_fifo	equ 1
cmd_clear_output_fifo	equ 2

modem_command		ds 256+128

CLOSED		db "CLOSED",#0d,#0a,0

http_part1	db " HTTP/1.0",13,10 ;size=123
		db "Host: " ;zxart.ee",13,10

http_part2	db    "User-Agent: ZiFi (ZX Evo)",13,10    ; show off ;)
		db    "Accept: */*",13,10
		db    "Connection: close",13,10,13,10
http_part3


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
cmd_cipclose	db    "AT+CIPCLOSE",13,10,0
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
str_already_con:defb    "ALREADY CONNECT",13,0	
str_error:      defb    "ERROR",13,0
str_fail:       defb    "FAIL",13,0
str_send_ok:    defb    "SEND OK",13,0
str_ipd		db "+IPD,",0

		include "tsconfig.asm"

		align 256
output_buff
end
	


		SAVEBIN "zifi_driver.bin",start, end-start	