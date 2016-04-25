--------------------------------------------------------------------------------

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
