#include <winsock2.h>

#include "ic_comm.h"
#include "ic_cmds.h"
#include "uart.h"
#include "log.h"

//Winsock shit
WORD wVersionRequested;
WSADATA wsaData;


//vars
SOCKET sockets[SOCKET_MAX];



//Init
int init(char *comport)
{
  int i;

  for(i=0; i<SOCKET_MAX; ++i)
    sockets[i]=0;

  if(uart_init(comport) < 0) return -1;

  //Init winsock
  wVersionRequested = MAKEWORD(2,2);
  WSAStartup(wVersionRequested, &wsaData);
  

  return 0;
}



//Process
void process(void)
{
  unsigned char cmd;

  while(1)
  {
    //read command
    uart_read(&cmd,1);

    switch(cmd)
    {
      case IC_CMD_SOCKET:  cmd_socket();  break;
      case IC_CMD_BIND:    cmd_bind();    break;
      case IC_CMD_CONNECT: cmd_connect(); break;
      case IC_CMD_LISTEN:  cmd_listen();  break;
      case IC_CMD_ACCEPT:  cmd_accept();  break;
      case IC_CMD_CLOSE:   cmd_close();   break;
      case IC_CMD_SELECT:  cmd_select();  break;
                          
      case IC_CMD_GETHOSTBYNAME: cmd_gethostbyname(); break;
      case IC_CMD_GETHOSTBYADDR: cmd_gethostbyaddr(); break;
                          
      case IC_CMD_SEND:     cmd_send();     break;
      case IC_CMD_RECV:     cmd_recv();     break;
      case IC_CMD_SENDTO:   cmd_sendto();   break;
      case IC_CMD_RECVFROM: cmd_recvfrom(); break;

      default:
        logerr("Wrong command #%2x!",cmd);
    }
  }


}









void cmd_res_fail(void)
{
  unsigned char t=IC_CMD_RES_FAIL;
  uart_write(&t,1);
}

void cmd_res_ok(void)
{
  unsigned char t=IC_CMD_RES_OK;
  uart_write(&t,1);
}





void cmd_socket(void)
{
  unsigned char params[10];
  SOCKET tsock;
  int i;

  //get params
  uart_read(params,3);
  //find free socket
  for(i=0; i<SOCKET_MAX; ++i)
    if(sockets[i]==0) break;

  if(i==SOCKET_MAX)
  { //not found, result=fail
    cmd_res_fail();
    logerr("CMD_SOCKET: No free sockets.");
  }
  else
  { //found, create real socket
    tsock=socket((int)params[0],(int)params[1],(int)params[2]);

    if(tsock==INVALID_SOCKET)
    { //socket() fail
      cmd_res_fail();
      logerr("socket() failed.");
    }
    else
    { //socket created
      sockets[i]=tsock;
      params[0]=IC_CMD_RES_OK;	//res=ok
      params[1]=i;		//fd
      uart_write(params,2);
      log_("Socket created, id=%i.",i);
    }
  }
}





void cmd_bind(void)
{
  unsigned char params[10];
  unsigned char fd;
  struct sockaddr_in loc_addr;

  //get params
  uart_read(params,7);
  fd=params[0];
  if(fd>=SOCKET_MAX || sockets[fd]==0)
  { //wrong fd
    cmd_res_fail();
    logerr("CMD_BIND: Wrong socket descriptor, id=%i.",fd);
  }
  else
  { //correct fd
    loc_addr.sin_family = AF_INET; //fix in proto?
    loc_addr.sin_addr.S_un.S_addr=htonl(params[1] | (params[2]<<8) | (params[3]<<16) | (params[4]<<24));
    loc_addr.sin_port=htons(params[5] | (params[6]<<8));
    if(bind(sockets[fd], (struct sockaddr *)&loc_addr, sizeof(loc_addr)) == 0)
    { //bind ok
      cmd_res_ok();
      log_("Socket id=%i binded to %u.%u.%u.%u:%u.",fd,params[1],params[2],params[3],params[4], params[5] | (params[6]<<8));
    }
    else
    { //bind error
      cmd_res_fail();
      logerr("bind() error.");
    }
  }
}


void cmd_connect(void)
{
  unsigned char params[10];
  unsigned char fd;
  struct sockaddr_in rm_addr;

  //get params
  uart_read(params,7);
  fd=params[0];
  if(fd>=SOCKET_MAX || sockets[fd]==0)
  { //wrong fd
    cmd_res_fail();
    logerr("CMD_CONNECT: Wrong socket descriptor, id=%i.",fd);
  }
  else
  { //correct fd
    rm_addr.sin_family = AF_INET; //fix in proto?
    rm_addr.sin_addr.S_un.S_addr=htonl(params[4] | (params[3]<<8) | (params[2]<<16) | (params[1]<<24));
    rm_addr.sin_port=htons(params[5] | (params[6]<<8));
    if(connect(sockets[fd], (struct sockaddr *)&rm_addr, sizeof(rm_addr)) == 0)
    { //connect ok
      cmd_res_ok();
      log_("Socket id=%i connected to %u.%u.%u.%u:%u.",fd,params[1],params[2],params[3],params[4], params[5] | (params[6]<<8));
    }
    else
    { //connect error
      cmd_res_fail();
      logerr("connect() error.");
    }
  }
}



void cmd_listen(void)
{

}



void cmd_accept(void)
{

}



void cmd_close(void)
{
  unsigned char fd;

  //get params
  uart_read(&fd,1);
  if(fd>=SOCKET_MAX || sockets[fd]==0)
  { //wrong fd
    cmd_res_fail();
    logerr("CMD_CLOSE: Wrong socket descriptor, id=%i.",fd);
  }
  else
  { //correct fd
    closesocket(sockets[fd]);
    sockets[fd]=0;
    cmd_res_ok();
    log_("Close socket, id=%i.",fd);
  }
}



void cmd_select(void)
{
  unsigned char params[MAX_SELECT],tlen[3];
  fd_set fdrd;
  fd_set fdwr;
  fd_set fdexc;
  struct timeval tout={0,0};
  int n,nr,nw,ne,i,p;

  //get nums & timeout
  uart_read(params,3);
  nr=params[0];
  nw=params[1];
  ne=params[2];
  n=nr+ne+nw;

  if(n>MAX_SELECT || nr>MAX_SELECT || nw>MAX_SELECT || ne>MAX_SELECT)
  { //too much sockets! error...
    while(n>0)
    {
      nr=(n>MAX_SELECT) ? MAX_SELECT : n;
      uart_read(params,nr);
      n-=nr;
    }
    cmd_res_fail();
    logerr("CMD_SELECT: Too much sockets.");
    return;
  }
  else
  { //ok, get fds
    uart_read(params,n);
    FD_ZERO(&fdrd);
    FD_ZERO(&fdwr); 
    FD_ZERO(&fdexc); 

    //fill fd_set
    if(nr)
    {
      for(i=0;i<nr;++i)
      {
        if(sockets[params[i]]==0)
        {
          cmd_res_fail();
          logerr("CMD_SELECT: Wrong socket.");
          return;
        }
        FD_SET(sockets[params[i]], &fdrd);
      }
    }

    if(nw)
    {
      for(i=0;i<nw;++i)
      {
        if(sockets[params[i+nr]]==0)
        {
          cmd_res_fail();
          logerr("CMD_SELECT: Wrong socket.");
          return;
        }
        FD_SET(sockets[params[i+nr]], &fdwr);
      }
    }

    if(ne)
    {
      for(i=0;i<ne;++i)
      {
        if(sockets[params[i+nr+nw]]==0)
        {
          cmd_res_fail();
          logerr("CMD_SELECT: Wrong socket.");
          return;
        }
        FD_SET(sockets[params[i+nr+nw]], &fdexc);
      }
    }

    n=select(FD_SETSIZE, &fdrd, &fdwr, &fdexc, &tout);

    if(n==0)
    { //no data on any socket
      params[0]=IC_CMD_RES_OK;
      params[1]=0;
      params[2]=0;
      params[3]=0;
      uart_write(params,4);
      log_("CMD_SELECT: No data.");
    }
    else if(n==SOCKET_ERROR)
    { //socket error?????
      cmd_res_fail();
      logerr("CMD_SELECT: socket error (closed?).");
    }
    else
    { //some sockets signalled
      //check all
      p=0;
        for(n=0,i=0;i<nr;++i)
          if(FD_ISSET(sockets[params[i]], &fdrd))
            params[p++]=params[i];
        tlen[0]=n;

        for(n=0,i=0;i<nw;++i)
          if(FD_ISSET(sockets[params[i+nr]], &fdrd))
            params[p++]=params[i+nr];
        tlen[1]=n;

        for(n=0,i=0;i<nr;++i)
          if(FD_ISSET(sockets[params[i]], &fdrd))
            params[p++]=params[i];
        tlen[2]=n;

      uart_write(tlen,3);
      if(p) uart_write(params,p);
      log_("CMD_SELECT: %i sockets signalled.",p);
    }

  }
}






void cmd_gethostbyname(void)
{
  struct hostent *remoteHost;
  unsigned char params[10];
  unsigned char *buf;
  unsigned short len,sent;

  //get params
  uart_read(params,2);
  len=params[0] + 256*params[1];
  buf=(unsigned char*)malloc(len+1);
    
  if(buf)
  { //mem ok
    uart_read(buf,len);
    buf[len]=0;
    remoteHost = gethostbyname(buf);
    if(remoteHost==NULL)
    {
      cmd_res_fail();
      logerr("CMD_GETHOSTBYNAME: gethostbyname(%s) failed.",buf);
    }
    else
    {
      cmd_res_ok();
      memcpy(params,remoteHost->h_addr_list[0],4);
      uart_write(params,4);
      log_("CMD_GETHOSTBYNAME: %s resolved to %d.%d.%d.%d.",buf,
          params[0],params[1],params[2],params[3]);
    }
    free(buf);
  }
  else
  {
    cmd_res_fail();
    logerr("CMD_GETHOSTBYNAME: malloc() failed.");
  }
}



void cmd_gethostbyaddr(void)
{

}





void cmd_send(void)
{
  unsigned char params[10];
  unsigned char fd;
  unsigned char *buf;
  unsigned short len,sent;

  //get params
  uart_read(params,4);
  fd=params[0];
  if(fd>=SOCKET_MAX || sockets[fd]==0)
  { //wrong fd
    cmd_res_fail();
    logerr("CMD_SEND: Wrong socket descriptor, id=%i.",fd);
  }
  else
  { //correct fd
    len=params[1] + 256*params[2];
    buf=(unsigned char*)malloc(len);
    
    if(buf)
    { //mem ok
      cmd_res_ok();
      //get data and send it to real socket
      uart_read(buf,len);
      sent=send(sockets[fd],buf,len,0);
      //report real sent/error
      params[0]=sent & 0xff; params[1]=(sent>>8) & 0xff;
      uart_write(params,2);

      free(buf);
      log_("Socket id=%i send %u bytes.",fd,len);
    }
    else
    { //no mem
      cmd_res_fail();
      logerr("CMD_SEND: no memory.");
    }
  }

}



void cmd_recv(void)
{
  unsigned char params[10];
  unsigned char fd;
  unsigned char *buf;
  unsigned short len,reallen;
  fd_set fdset;
  struct timeval tout={0,0};
  int n;

  //get params
  uart_read(params,4);
  fd=params[0];
  if(fd>=SOCKET_MAX || sockets[fd]==0)
  { //wrong fd
    cmd_res_fail();
    logerr("CMD_RECV: Wrong socket descriptor, id=%i.",fd);
  }
  else
  { //correct fd
    len=params[1] + 256*params[2];
    buf=(unsigned char*)malloc(len+3);
    
    if(buf)
    { //mem ok
      FD_ZERO(&fdset); FD_SET(sockets[fd], &fdset);
      n=select(FD_SETSIZE, &fdset, NULL, NULL, &tout);

      if(n==0)
      { //timeout, no data, socket ok
        buf[0]=IC_CMD_RES_OK;
        buf[1]=0;
        buf[2]=0;
        uart_write(buf,3);
        log_("Socket id=%i recv 0 bytes.",fd);
      }
      else if(n==SOCKET_ERROR)
      { //socket error
        cmd_res_fail();
        logerr("CMD_RECV: socket error (closed?), id=%i.",fd);
      }
      else
      { //data present, read
        reallen=recv(sockets[fd],buf+3,len,0);
        if(reallen==0)
        { //socket closed
          cmd_res_fail();
          log_("CMD_RECV: socket closed, id=%i.",fd);
        }
        else
        {
          //report real sent/error
          buf[0]=IC_CMD_RES_OK;
          buf[1]=reallen & 0xff; buf[2]=(reallen>>8) & 0xff;
          uart_write(buf,reallen+3);
          log_("Socket id=%i recv %u bytes.",fd,reallen);
        }
      }
      free(buf);
    }
    else
    { //no mem
      cmd_res_fail();
      logerr("CMD_RECV: no memory, id=%i.",fd);
    }
  }

}



void cmd_sendto(void)
{

}



void cmd_recvfrom(void)
{

}



