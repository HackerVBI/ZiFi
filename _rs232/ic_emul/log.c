#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>


void log_(const char *fmt, ...)
{
#if 1
  va_list ap;
  char *msg=(char*)malloc(1024);

  if(msg)
  {
    va_start(ap, fmt);
    vsprintf(msg, fmt, ap);
    printf("Log: %s\n",msg);
    va_end(ap);
    free(msg);
  }
#endif
}



void logerr(const char *fmt, ...)
{
#if 1
  va_list ap;
  char *msg=(char*)malloc(1024);

  if(msg)
  {
    va_start(ap, fmt);
    vsprintf(msg, fmt, ap);
    printf("Error: %s\n",msg);
    va_end(ap);
    free(msg);
  }
#endif
}
