

#define SOCKET_MAX 20  //max sockets
#define MAX_SELECT 20  //max total sockets for select

int init(char *sname, int baud);
void process(void);


void cmd_nop(void);
void cmd_socket(void);
void cmd_bind(void);
void cmd_connect(void);
void cmd_listen(void);
void cmd_accept(void);
void cmd_close(void);
void cmd_select(void);
                          
void cmd_gethostbyname(void);
void cmd_gethostbyaddr(void);
                          
void cmd_send(void);
void cmd_recv(void);
void cmd_sendto(void);
void cmd_recvfrom(void);

void cmd_info(void);
void cmd_reset(void);


