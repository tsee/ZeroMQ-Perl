#ifndef  __PERL_ZEROMQ_H__
#define  __PERL_ZEROMQ_H__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "zmq.h"

struct PerlZMQ_Context_t;

typedef struct {
    void *ctxt;
    unsigned int count;
    unsigned int socket_bufsiz;
    unsigned int socket_count;
    struct PerlZMQ_Socket_t **sockets;
} PerlZMQ_Context;

typedef struct PerlZMQ_Socket_t {
    void *socket;
    PerlZMQ_Context *ctxt;
} PerlZMQ_Socket;

typedef zmq_msg_t PerlZMQ_Message;

typedef struct {
    int bucket_size;
    int item_count;
    zmq_pollitem_t **items;
    char **item_ids;
    SV  **callbacks;
} PerlZMQ_PollItem;

/* ZMQ_PULL was introduced for version 3, but it exists in git head.
 * it's just rename of ZMQ_UPSTREAM and ZMQ_DOWNSTREAM so we just
 * fake it here
 */
#ifndef ZMQ_PULL
#define ZMQ_PULL ZMQ_UPSTREAM
#endif

#ifndef ZMQ_PUSH
#define ZMQ_PUSH ZMQ_DOWNSTREAM
#endif

#endif /* __PERL_ZERMQ_H__ */