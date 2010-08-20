#include "perl_zeromq.h"

#define PerlZMQ_Context_inc(ctxt) (ctxt->count++)
#define PerlZMQ_Context_dec(ctxt) (ctxt->count--)
#define PerlZMQ_Context_count(ctxt) (ctxt->count)
#define PerlZMQ_Context_ctxt(ctxt) (ctxt->ctxt)
#define PerlZMQ_Context_term(ctxt) (zmq_term(ctxt->ctxt))

static PerlZMQ_Context *
PerlZMQ_Context_init(int threads) {
    PerlZMQ_Context *ctxt;
    Newxz(ctxt, 1, PerlZMQ_Context);

    ctxt->ctxt = zmq_init(threads);
    ctxt->count = 1;

    return ctxt;
}

static int
PerlZMQ_Context_free(pTHX_ SV* const sv, MAGIC* const mg)
{
    PerlZMQ_Context* const ctxt = (PerlZMQ_Context *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
#ifdef USE_ITHREADS
    PerlZMQ_Context_dec(ctxt);
    if (PerlZMQ_Context_count(ctxt) == 0)  {
        PerlZMQ_Context_term( ctxt );
        Safefree( ctxt );
    }
#else
    PerlZMQ_Context_term( ctxt );
    Safefree( ctxt );
#endif
    return 1;
}

static int
PerlZMQ_Context_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
#ifdef USE_ITHREADS /* single threaded perl has no "xxx_dup()" APIs */
    PerlZMQ_Context *ctxt = (PerlZMQ_Context *) mg->mg_ptr;
    PerlZMQ_Context_inc(ctxt);
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
    PerlZMQ_Socket* const sock = (PerlZMQ_Socket *) mg->mg_ptr;
    if (sock != NULL) 
        zmq_close( sock );
    PERL_UNUSED_VAR(sv);
    return 1;
}

static int
PerlZMQ_Socket_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
#ifdef USE_ITHREADS /* single threaded perl has no "xxx_dup()" APIs */
    mg->mg_ptr = NULL;
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
    PerlZMQ_Message* const msg = (PerlZMQ_Message *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    zmq_msg_close(msg);
    Safefree(msg);
    return 1;
}

static int
PerlZMQ_Message_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
#ifdef USE_ITHREADS /* single threaded perl has no "xxx_dup()" APIs */
    PerlZMQ_Message* const msg = (PerlZMQ_Message *) mg->mg_ptr;
    if (msg != NULL) {
        PerlZMQ_Message *newmsg;

        Newxz(newmsg, 1, PerlZMQ_Message);
        zmq_msg_init_data( newmsg, zmq_msg_data(msg), zmq_msg_size(msg), NULL, NULL );
        mg->mg_ptr = (char *) newmsg;
    }
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

static void
simple_free_cb(void *data, void *hint) {
    PERL_UNUSED_VAR(hint);
    Safefree(data);
}

static void
PerlZMQ_serialize( const char *type, char **data, size_t *data_len, SV *input) {
    HV *serializers;
    SV **cvr;

    serializers = get_hv( "ZeroMQ::SERIALIZERS", 0 );
    cvr = hv_fetch( serializers, type, strlen(type), 0 );
    if (cvr == NULL)
        croak("Serializer for %s not found", type);

    if (SvTYPE(*cvr) == SVt_PVCV)
        croak("Serializer for %s not found", type);

    {
        dSP;
        int count;
        SV *serialized_sv;
        char *serialized;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs( input );
        PUTBACK;
        count = call_sv( *cvr,  G_SCALAR );
        SPAGAIN;

        if (count < 1) {
            croak("serialize did not return any values");
        }

        serialized_sv = POPs;
        serialized = SvPV( serialized_sv, *data_len );

        Newxz( *data, *data_len, char );
        Copy( serialized, *data, *data_len, char );

        PUTBACK;
        FREETMPS;
        LEAVE;
    }
}

static SV *
PerlZMQ_deserialize( const char *type, char *data, size_t data_len) {
    SV *input;
    HV *deserializers;
    SV *output;
    SV **cvr;

    input = sv_2mortal(newSVpv( data, data_len ));
    deserializers = get_hv( "ZeroMQ::DESERIALIZERS", 0 );

    cvr = hv_fetch( deserializers, type, strlen(type), 0 );
    if (cvr == NULL)
        croak("Deserializer for %s not found", type);

    if (SvTYPE(*cvr) == SVt_PVCV)
        croak("Deserializer for %s not found", type);

    {
        dSP;
        int count;
        SV *deserialized;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs( input );
        PUTBACK;
        count = call_sv( *cvr,  G_SCALAR );
        SPAGAIN;

        if (count < 1) {
            croak("deserialize did not return any values");
        }

        deserialized = POPs;
        output = newSVsv(deserialized);

        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    return output;
}

MODULE = ZeroMQ    PACKAGE = ZeroMQ           PREFIX = PerlZMQ_

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

void
PerlZMQ_version()
    PREINIT:
        int major, minor, patch;
        I32 gimme;
    PPCODE:
        gimme = GIMME_V;
        if (gimme == G_VOID) {
            /* WTF? you don't want a return value?! */
            XSRETURN(0);
        }

        zmq_version(&major, &minor, &patch);
        if (gimme == G_SCALAR) {
            XPUSHs( sv_2mortal( newSVpvf( "%d.%d.%d", major, minor, patch ) ) );
            XSRETURN(1);
        } else {
            mXPUSHi( major );
            mXPUSHi( minor );
            mXPUSHi( patch );
            XSRETURN(3);
        }

int
PerlZMQ_device(device, insock, outsock)
        int device;
        PerlZMQ_Socket *insock;
        PerlZMQ_Socket *outsock;
    CODE:
        RETVAL = zmq_device( device, insock, outsock );
    OUTPUT:
        RETVAL

MODULE = ZeroMQ    PACKAGE = ZeroMQ::Context   PREFIX = PerlZMQ_Context_

PROTOTYPES: DISABLE

PerlZMQ_Context *
PerlZMQ_Context_new(class_sv, threads = 1)
        SV *class_sv;
        int threads;
    CODE:
        RETVAL = PerlZMQ_Context_init(threads);
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

        RETVAL = zmq_socket(PerlZMQ_Context_ctxt(ctxt), socktype);
    OUTPUT:
        RETVAL

int
PerlZMQ_Socket_bind(socket, addr)
        PerlZMQ_Socket *socket;
        char *addr;
    CODE:
        RETVAL = zmq_bind(socket, addr);
        if (RETVAL != 0) {
            croak( "%s", zmq_strerror( zmq_errno() ) );
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
            croak( "%s", zmq_strerror( zmq_errno() ) );
        }
    OUTPUT:
        RETVAL

void
PerlZMQ_Socket_setsockopt(socket, option_name, option_value)
        PerlZMQ_Socket *socket;
        int option_name;
        SV *option_value;
    CODE:
        switch (option_name) {
        case ZMQ_HWM:
        case ZMQ_SWAP:
        case ZMQ_AFFINITY:
            {
                int64_t v = SvIV(option_value);
                zmq_setsockopt(socket, option_name, (void*)&v, sizeof(int64_t));
            }
            break;
        case ZMQ_IDENTITY:
        case ZMQ_SUBSCRIBE:
        case ZMQ_UNSUBSCRIBE:
            {
                size_t option_length;
                char *v = SvPV(option_value, option_length);
                zmq_setsockopt(socket, option_name, (void*)v, option_length);
            }
            break;
        case ZMQ_RATE:
        case ZMQ_RECOVERY_IVL:
        case ZMQ_MCAST_LOOP:
        case ZMQ_SNDBUF:
        case ZMQ_RCVBUF:
            {
                uint64_t v = SvUV(option_value);
                zmq_setsockopt(socket, option_name, (void*)&v, sizeof(uint64_t));
            }
            break;
        }

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

SV *
PerlZMQ_Socket_recv_as(socket, type, flags = 0)
        PerlZMQ_Socket *socket;
        char *type;
        int flags;
    PREINIT:
        PerlZMQ_Message *to_recv = NULL;
    CODE:
        if (type == NULL)
            croak("ZeroMQ::Socket::send_as() NULL serialization type passed");

        Newxz(to_recv, 1, PerlZMQ_Message);
        zmq_msg_init(to_recv);
        if (zmq_recv(socket, to_recv, flags) != 0) {
            zmq_msg_close( to_recv );
            Safefree(to_recv);
            XSRETURN(0);
        }

        RETVAL = PerlZMQ_deserialize( type, (char *) zmq_msg_data(to_recv), zmq_msg_size(to_recv) );
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
PerlZMQ_Socket_send_as(socket, type, message, flags = 0)
        PerlZMQ_Socket *socket;
        char *type;
        SV *message;
        int flags;
    PREINIT:
        char *data = NULL;
        size_t data_len = 0;
        PerlZMQ_Message *to_send = NULL;
    CODE:
        if (! SvOK(message))
            croak("ZeroMQ::Socket::send() NULL message passed");
        if (type == NULL)
            croak("ZeroMQ::Socket::send_as() NULL serialization type passed");

        PerlZMQ_serialize( type, &data, &data_len, message);
        Newxz(to_send, 1, PerlZMQ_Message);
        zmq_msg_init_data( to_send, data, data_len, &simple_free_cb, NULL );

        RETVAL = (zmq_send(socket, to_send, flags) == 0);

        zmq_msg_close( to_send );
        Safefree( to_send );
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

int
PerlZMQ_Socket_close(socket)
        PerlZMQ_Socket *socket;
    PREINIT:
        MAGIC *mg;
    CODE:
        RETVAL = zmq_close(socket);
        mg = PerlZMQ_Socket_mg_find(aTHX_ SvRV(ST(0)), &PerlZMQ_Socket_vtbl);
        if (mg != NULL)
            mg->mg_ptr = NULL;
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

int
PerlZMQ_Message_size(message)
        PerlZMQ_Message *message
    CODE:
        RETVAL = zmq_msg_size(message);
    OUTPUT:
        RETVAL
