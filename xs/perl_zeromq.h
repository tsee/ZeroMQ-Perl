#ifndef  __PERL_ZEROMQ_H__
#define  __PERL_ZEROMQ_H__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "zmq.h"

typedef void PerlZMQ_Context;
typedef void PerlZMQ_Socket;
typedef zmq_msg_t PerlZMQ_Message;

#endif /* __PERL_ZERMQ_H__ */