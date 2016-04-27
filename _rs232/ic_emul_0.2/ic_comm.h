
/* ic commands */

#define IC_CMD_NOP		0x00
#define IC_CMD_SOCKET		0x01
#define IC_CMD_BIND		0x02
#define IC_CMD_CONNECT		0x03
#define IC_CMD_LISTEN		0x04
#define IC_CMD_ACCEPT		0x05
#define IC_CMD_CLOSE		0x06
#define IC_CMD_SELECT		0x07

#define IC_CMD_GETHOSTBYNAME	0X20
#define IC_CMD_GETHOSTBYADDR	0X21

#define IC_CMD_SEND		0x10
#define IC_CMD_RECV		0x11
#define IC_CMD_SENDTO		0x18
#define IC_CMD_RECVFROM		0x19

#define IC_CMD_INFO		0x30
#define IC_CMD_RESET		0xF0

#define IC_CMD_RES_OK		0x00
#define IC_CMD_RES_FAIL		0xff


/* ic defines */

#define IC_SOCK_STREAM		1	// stream socket (TCP)
#define IC_SOCK_DGRAM		2	// datagram socket (UDP)
#define IC_AF_INET		2	// internetwork: UDP, TCP, etc.
