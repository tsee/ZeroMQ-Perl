#include "perl_zeromq.h"

static int
PerlZMQ_Context_free(pTHX_ SV* const sv, MAGIC* const mg)
{
    PerlZMQ_Context* const ctxt = (PerlZMQ_Context *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    zmq_term( ctxt );
    return 1;
}

static int
PerlZMQ_Context_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
#ifdef USE_ITHREADS /* single threaded perl has no "xxx_dup()" APIs */
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#else
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#endif
    return 0;
}

static MAGIC*
PerlZMQ_Context_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("ZeroMQ::Context: Invalid ZeroMQ::Context object was passed to mg_find");
    return NULL; /* not reached */
}


static MGVTBL PerlZMQ_Context_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    PerlZMQ_Context_free, /* free */
    NULL, /* copy */
    PerlZMQ_Context_mg_dup, /* dup */
    NULL,  /* local */
};

static int
PerlZMQ_Socket_free(pTHX_ SV* const sv, MAGIC* const mg)
{
    PerlZMQ_Socket* const ctxt = (PerlZMQ_Socket *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    zmq_close( ctxt );
    return 1;
}

static int
PerlZMQ_Socket_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
#ifdef USE_ITHREADS /* single threaded perl has no "xxx_dup()" APIs */
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#else
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#endif
    return 0;
}

static MAGIC*
PerlZMQ_Socket_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("ZeroMQ::Socket: Invalid ZeroMQ::Socket object was passed to mg_find");
    return NULL; /* not reached */
}


static MGVTBL PerlZMQ_Socket_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    PerlZMQ_Socket_free, /* free */
    NULL, /* copy */
    PerlZMQ_Socket_mg_dup, /* dup */
    NULL,  /* local */
};

static int
PerlZMQ_Message_free(pTHX_ SV* const sv, MAGIC* const mg)
{
    PerlZMQ_Message* const ctxt = (PerlZMQ_Message *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    Safefree(ctxt);
    return 1;
}

static int
PerlZMQ_Message_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
#ifdef USE_ITHREADS /* single threaded perl has no "xxx_dup()" APIs */
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#else
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#endif
    return 0;
}

static MAGIC*
PerlZMQ_Message_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("ZeroMQ::Message: Invalid ZeroMQ::Message object was passed to mg_find");
    return NULL; /* not reached */
}


static MGVTBL PerlZMQ_Message_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    PerlZMQ_Message_free, /* free */
    NULL, /* copy */
    PerlZMQ_Message_mg_dup, /* dup */
    NULL,  /* local */
};


MODULE = ZeroMQ    PACKAGE = ZeroMQ 

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

MODULE = ZeroMQ    PACKAGE = ZeroMQ::Context   PREFIX = PerlZMQ_Context_

PROTOTYPES: DISABLE

PerlZMQ_Context *
PerlZMQ_Context_new(class_sv, threads = 1)
        SV *class_sv;
        int threads;
    CODE:
        RETVAL = zmq_init(threads);
    OUTPUT:
        RETVAL

MODULE = ZeroMQ    PACKAGE = ZeroMQ::Socket   PREFIX = PerlZMQ_Socket_

PROTOTYPES: DISABLE

PerlZMQ_Socket *
PerlZMQ_Socket_new(class_sv, ctxt, socktype)
        SV *class_sv;
        PerlZMQ_Context *ctxt;
        int socktype;
    CODE:
        if (ctxt == NULL)
            croak("Invalid ZeroMQ::Context passed to ZeroMQ::Socket->new");

        RETVAL = zmq_socket(ctxt, socktype);
    OUTPUT:
        RETVAL

int
PerlZMQ_Socket_bind(socket, addr)
        PerlZMQ_Socket *socket;
        char *addr;
    CODE:
        RETVAL = zmq_bind(socket, addr);
        if (RETVAL != 0) {
            croak( zmq_strerror( zmq_errno() ) );
        }
    OUTPUT:
        RETVAL

int
PerlZMQ_Socket_connect(socket, addr)
        PerlZMQ_Socket *socket;
        char *addr;
    CODE:
        RETVAL = zmq_connect(socket, addr);
        if (RETVAL != 0) {
            croak( zmq_strerror( zmq_errno() ) );
        }
    OUTPUT:
        RETVAL

SV *
PerlZMQ_Socket_getsockopt(socket, option_name)
        PerlZMQ_Socket *socket;
        int option_name;
    CODE:
        RETVAL = newSV(0);
        switch (option_name) {
        case ZMQ_RCVMORE:
        case ZMQ_HWM:
        case ZMQ_SWAP:
        case ZMQ_AFFINITY:
            {
                int64_t rv;
                size_t len = sizeof(int64_t);
                zmq_getsockopt(socket, option_name, (void*)&rv, &len);
                sv_setiv(RETVAL, rv);
            }
            break;
        case ZMQ_IDENTITY:
            {
                char* rv;
                size_t len = 255;
                Newxz(rv, len, char);
                zmq_getsockopt(socket, option_name, (void*)&rv, &len);
                sv_setpv(RETVAL, rv);
                Safefree(rv);
            }
            break;
        case ZMQ_RATE:
        case ZMQ_RECOVERY_IVL:
        case ZMQ_MCAST_LOOP:
        case ZMQ_SNDBUF:
        case ZMQ_RCVBUF:
            {
                uint64_t rv = 123;
                size_t len = sizeof(uint64_t);
                // Note: sizeof(uint64_t) == sizeof(int64_t) so this isn't strictly necessary:
                zmq_getsockopt(socket, option_name, (void*)&rv, &len);
                sv_setuv(RETVAL, rv);
            }
            break;
        };
    OUTPUT:
        RETVAL

PerlZMQ_Message *
PerlZMQ_Socket_recv(socket, flags = 0)
        PerlZMQ_Socket *socket;
        int flags;
    PREINIT:
        SV *class_sv = NULL;
    CODE:
        class_sv = sv_2mortal(newSV(0));
        sv_setpv(class_sv, "ZeroMQ::Message");

        Newxz(RETVAL, 1, PerlZMQ_Message);
        zmq_msg_init(RETVAL);
        if (zmq_recv(socket, RETVAL, flags) != 0) {
            Safefree(RETVAL);
            RETVAL = NULL;
            XSRETURN(0);
        }
    OUTPUT:
        RETVAL

int
PerlZMQ_Socket_send(socket, message, flags = 0)
        PerlZMQ_Socket *socket;
        SV *message;
        int flags;
    PREINIT:
        int allocated = 0;
        PerlZMQ_Message *msg = NULL;
    CODE:
        if (! SvOK(message))
            croak("ZeroMQ::Socket::send() NULL message passed");

        if (sv_isobject(message) && sv_isa(message, "ZeroMQ::Message")) {
            MAGIC *mg = PerlZMQ_Context_mg_find(aTHX_ SvRV(message), &PerlZMQ_Message_vtbl);
            if (mg) {
                msg = (PerlZMQ_Message *) mg->mg_ptr;
            }
        } else {
            STRLEN data_len;
            char *data = SvPV(message, data_len);
            Newxz(msg, 1, PerlZMQ_Message);
            allocated = 1;
            zmq_msg_init_data(msg, data, data_len, NULL, NULL);
        }

        RETVAL = (zmq_send(socket, msg, flags) == 0);

        if (allocated)
            Safefree(msg);
    OUTPUT:
        RETVAL

MODULE = ZeroMQ   PACKAGE = ZeroMQ::Message    PREFIX = PerlZMQ_Message_

PROTOTYPES: DISABLE

PerlZMQ_Message *
PerlZMQ_Message_new(class_sv, data = NULL)
        SV *class_sv;
        SV *data;
    PREINIT:
        PerlZMQ_Message *msg;
    CODE:
        Newxz( msg, 1, PerlZMQ_Message );
        if (data == NULL) {
            zmq_msg_init(msg);
        } else {
            char *x_data;
            STRLEN x_data_len;
            x_data = SvPV(data, x_data_len);

            zmq_msg_init_data(msg, x_data, x_data_len, NULL, NULL);
        }
        RETVAL = msg;
    OUTPUT:
        RETVAL

SV *
PerlZMQ_Message_data(message)
        PerlZMQ_Message *message;
    CODE:
        RETVAL = newSV(0);
        sv_setpvn( RETVAL, (char *) zmq_msg_data(message), (STRLEN) zmq_msg_size(message) );
    OUTPUT:
        RETVAL

