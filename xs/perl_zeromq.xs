
#include "perl_zeromq.h"
#include "xshelper.h"

#if (PERLZMQ_TRACE > 0)
#define PerlZMQ_trace(...) warn(__VA_ARGS__)
#else
#define PerlZMQ_trace(...)
#endif

STATIC_INLINE void
PerlZMQ_set_bang(pTHX_ int err) {
    SV *errsv = get_sv("!", GV_ADD);
    PerlZMQ_trace("Set ERRSV ($!) to %d", err);
    sv_setiv(errsv, err);
}

STATIC_INLINE int
PerlZMQ_Raw_Message_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param) {
    PerlZMQ_Raw_Message *const src = (PerlZMQ_Raw_Message *) mg->mg_ptr;
    PerlZMQ_Raw_Message *dest;

    PerlZMQ_trace("Message -> dup");
    PERL_UNUSED_VAR( param );
 
    Newxz( dest, 1, PerlZMQ_Raw_Message );
    zmq_msg_init( dest );
    zmq_msg_copy ( dest, src );
    mg->mg_ptr = (char *) dest;
    return 0;
}

STATIC_INLINE int
PerlZMQ_Raw_Message_mg_free( pTHX_ SV * const sv, MAGIC *const mg ) {
    PerlZMQ_Raw_Message* const msg = (PerlZMQ_Raw_Message *) mg->mg_ptr;
    PerlZMQ_trace("Message_mg_free for SV = %p, zmq_msg_t = %p", sv, msg);
    PERL_UNUSED_VAR(sv);
    if ( msg != NULL ) {
        zmq_msg_close( msg );
    }
    return 1;
}

STATIC_INLINE MAGIC*
PerlZMQ_Raw_Message_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("ZeroMQ::Raw::Message: Invalid ZeroMQ::Raw::Message object was passed to mg_find");
    return NULL; /* not reached */
}

STATIC_INLINE int
PerlZMQ_Raw_Context_mg_free( pTHX_ SV * const sv, MAGIC *const mg ) {
    PerlZMQ_Raw_Context* const ctxt = (PerlZMQ_Raw_Context *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    if (ctxt != NULL) {
#ifdef USE_ITHREADS
        if ( ctxt->interp == aTHX ) { /* is where I came from */
            PerlZMQ_trace("Context_free for context wrapper %p with zmq context %p for thread %p", ctxt, ctxt->ctxt, aTHX);
            zmq_term( ctxt->ctxt );
            mg->mg_ptr = NULL;
            Safefree(ctxt);
        }
#else
        PerlZMQ_trace("Context_free for zmq context %p", ctxt);
        zmq_term( ctxt );
        mg->mg_ptr = NULL;
#endif
    }
    return 1;
}

STATIC_INLINE MAGIC*
PerlZMQ_Raw_Context_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("ZeroMQ::Raw::Context: Invalid ZeroMQ::Raw::Context object was passed to mg_find");
    return NULL; /* not reached */
}

STATIC_INLINE int
PerlZMQ_Raw_Context_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
    return 0;
}

STATIC_INLINE int
PerlZMQ_Raw_Socket_mg_free(pTHX_ SV* const sv, MAGIC* const mg)
{
    PerlZMQ_Raw_Socket* const sock = (PerlZMQ_Raw_Socket *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    if (sock) {
        PerlZMQ_trace("Socket_free %p", sock);
        zmq_close( sock );
    }
    return 1;
}

STATIC_INLINE int
PerlZMQ_Raw_Socket_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
#ifdef USE_ITHREADS /* single threaded perl has no "xxx_dup()" APIs */
    mg->mg_ptr = NULL;
    PERL_UNUSED_VAR(param);
#else
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#endif
    return 0;
}

STATIC_INLINE MAGIC*
PerlZMQ_Raw_Socket_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
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

STATIC_INLINE void 
PerlZMQ_free_string(void *data, void *hint) {
    PERL_UNUSED_VAR(hint);
    Safefree( (char *) data );
}

#include "mg-xs.inc"

MODULE = ZeroMQ    PACKAGE = ZeroMQ   PREFIX = PerlZMQ_

PROTOTYPES: DISABLED

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

MODULE = ZeroMQ    PACKAGE = ZeroMQ::Constants 

INCLUDE: const-xs.inc

MODULE = ZeroMQ    PACKAGE = ZeroMQ::Raw  PREFIX = PerlZMQ_Raw_

PROTOTYPES: DISABLED

PerlZMQ_Raw_Context *
PerlZMQ_Raw_zmq_init( nthreads = 5 )
        int nthreads;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZeroMQ::Raw::Context", 20 ));
    CODE:
#ifdef USE_ITHREADS
        Newxz( RETVAL, 1, PerlZMQ_Raw_Context );
        RETVAL->interp = aTHX;
        RETVAL->ctxt   = zmq_init( nthreads );
        PerlZMQ_trace("context create context wrapper %p with zmq context %p for thread %p", RETVAL, RETVAL->ctxt, aTHX);
#else
        RETVAL = zmq_init( nthreads );
#endif
    OUTPUT:
        RETVAL

int
PerlZMQ_Raw_zmq_term( context )
        PerlZMQ_Raw_Context *context;
    CODE:
#ifdef USE_ITHREADS
        RETVAL = zmq_term( context->ctxt );
#else
        RETVAL = zmq_term( context );
#endif
        if (RETVAL == 0) {
            /* Cancel the SV's mg attr so to not call zmq_term automatically */
            MAGIC *mg =
                PerlZMQ_Raw_Context_mg_find( aTHX_ SvRV(ST(0)), &PerlZMQ_Raw_Context_vtbl );
            mg->mg_ptr = NULL;
        }
    OUTPUT:
        RETVAL

PerlZMQ_Raw_Message *
PerlZMQ_Raw_zmq_msg_init()
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZeroMQ::Raw::Message", 20 ));
        int rc;
    CODE:
        Newxz( RETVAL, 1, PerlZMQ_Raw_Message );
        rc = zmq_msg_init( RETVAL );
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
    OUTPUT:
        RETVAL

PerlZMQ_Raw_Message *
PerlZMQ_Raw_zmq_msg_init_size( size )
        IV size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZeroMQ::Raw::Message", 20 ));
        int rc;
    CODE: 
        Newxz( RETVAL, 1, PerlZMQ_Raw_Message );
        rc = zmq_msg_init_size(RETVAL, size);
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
    OUTPUT:
        RETVAL

PerlZMQ_Raw_Message *
PerlZMQ_Raw_zmq_msg_init_data( data, size = -1)
        SV *data;
        IV size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZeroMQ::Raw::Message", 20 ));
        STRLEN x_data_len;
        char *sv_data = SvPV(data, x_data_len);
        char *x_data;
        int rc;
    CODE: 
        if (size >= 0) {
            x_data_len = size;
        }
        Newxz( RETVAL, 1, PerlZMQ_Raw_Message );
        Newxz( x_data, x_data_len, char );
        Copy( sv_data, x_data, x_data_len, char );
        rc = zmq_msg_init_data(RETVAL, x_data, x_data_len, PerlZMQ_free_string, NULL);
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
        else {
            PerlZMQ_trace("zmq_msg_init_data created message %p", RETVAL);
        }
    OUTPUT:
        RETVAL

SV *
PerlZMQ_Raw_zmq_msg_data(message)
        PerlZMQ_Raw_Message *message;
    CODE:
        RETVAL = newSV(0);
        sv_setpvn( RETVAL, (char *) zmq_msg_data(message), (STRLEN) zmq_msg_size(message) );
    OUTPUT:
        RETVAL

size_t
PerlZMQ_Raw_zmq_msg_size(message)
        PerlZMQ_Raw_Message *message;
    CODE:
        RETVAL = zmq_msg_size(message);
    OUTPUT:
        RETVAL

int
PerlZMQ_Raw_zmq_msg_close(message)
        PerlZMQ_Raw_Message *message;
    CODE:
        RETVAL = zmq_msg_close(message);
    OUTPUT:
        RETVAL

int
PerlZMQ_Raw_zmq_msg_move(dest, src)
        PerlZMQ_Raw_Message *dest;
        PerlZMQ_Raw_Message *src;
    CODE:
        RETVAL = zmq_msg_move( dest, src );
    OUTPUT:
        RETVAL

int
PerlZMQ_Raw_zmq_msg_copy (dest, src);
        PerlZMQ_Raw_Message *dest;
        PerlZMQ_Raw_Message *src;
    CODE:
        RETVAL = zmq_msg_copy( dest, src );
    OUTPUT:
        RETVAL

PerlZMQ_Raw_Socket *
PerlZMQ_Raw_zmq_socket (ctxt, type)
        PerlZMQ_Raw_Context *ctxt;
        IV type;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZeroMQ::Raw::Socket", 19 ));
    CODE:
#ifdef USE_ITHREADS
        RETVAL = zmq_socket( ctxt->ctxt, type );
#else
        RETVAL = zmq_socket( ctxt, type );
#endif
        PerlZMQ_trace( "created socket %p", RETVAL );
    OUTPUT:
        RETVAL

int
PerlZMQ_Raw_zmq_close(socket)
        PerlZMQ_Raw_Socket *socket;
    CODE:
        RETVAL = zmq_close(socket);
        if (RETVAL == 0) {
            /* Cancel the SV's mg attr so to not call zmq_term automatically */
            MAGIC *mg =
                PerlZMQ_Raw_Socket_mg_find( aTHX_ SvRV(ST(0)), &PerlZMQ_Raw_Socket_vtbl );
            mg->mg_ptr = NULL;
        }
    OUTPUT:
        RETVAL

int
PerlZMQ_Raw_zmq_connect(socket, addr)
        PerlZMQ_Raw_Socket *socket;
        char *addr;
    CODE:
        RETVAL = zmq_connect( socket, addr );
        if (RETVAL != 0) {
            croak( "%s", zmq_strerror( zmq_errno() ) );
        }
    OUTPUT:
        RETVAL

int
PerlZMQ_Raw_zmq_bind(socket, addr)
        PerlZMQ_Raw_Socket *socket;
        char *addr;
    CODE:
        RETVAL = zmq_bind( socket, addr );
        if (RETVAL != 0) {
            croak( "%s", zmq_strerror( zmq_errno() ) );
        }
    OUTPUT:
        RETVAL

PerlZMQ_Raw_Message *
PerlZMQ_Raw_zmq_recv(socket, flags = 0)
        PerlZMQ_Raw_Socket *socket;
        int flags;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZeroMQ::Raw::Message", 20 ));
        int rv;
        zmq_msg_t msg;
    CODE:
        RETVAL = NULL;
        zmq_msg_init(&msg);
        rv = zmq_recv(socket, &msg, flags);
        PerlZMQ_trace("zmq recv with flags %d", flags);
        PerlZMQ_trace("zmq_recv returned with rv '%d'", rv);
        if (rv != 0) {
            SET_BANG;
            zmq_msg_close(&msg);
            PerlZMQ_trace("zmq_recv got bad status, closing temporary message");
        } else {
            Newxz(RETVAL, 1, PerlZMQ_Raw_Message);
            zmq_msg_init(RETVAL);
            zmq_msg_copy( RETVAL, &msg );
            zmq_msg_close(&msg);
            PerlZMQ_trace("zmq_recv created message %p", RETVAL );
        }
    OUTPUT:
        RETVAL

int
PerlZMQ_Raw_zmq_send(socket, message, flags = 0)
        PerlZMQ_Raw_Socket *socket;
        SV *message;
        int flags;
    PREINIT:
        PerlZMQ_Raw_Message *msg = NULL;
    CODE:
        if (! SvOK(message))
            croak("ZeroMQ::Socket::send() NULL message passed");

        if (sv_isobject(message) && sv_isa(message, "ZeroMQ::Raw::Message")) {
            MAGIC *mg = PerlZMQ_Raw_Context_mg_find(aTHX_ SvRV(message), &PerlZMQ_Raw_Message_vtbl);
            if (mg) {
                msg = (PerlZMQ_Raw_Message *) mg->mg_ptr;
            }

            if (msg == NULL) {
                croak("Got invalid message object");
            }
            
            RETVAL = zmq_send(socket, msg, flags);
        } else {
            STRLEN data_len;
            char *x_data;
            char *data = SvPV(message, data_len);
            zmq_msg_t msg;

            Newxz(x_data, data_len, char);
            Copy(data, x_data, data_len, char);
            zmq_msg_init_data(&msg, x_data, data_len, PerlZMQ_free_string, NULL);
            RETVAL = zmq_send(socket, &msg, flags);
            zmq_msg_close( &msg ); 
        }
    OUTPUT:
        RETVAL

SV *
PerlZMQ_Raw_zmq_getsockopt(sock, option)
        PerlZMQ_Raw_Socket *sock;
        int option;
    PREINIT:
        char     buf[256];
        int      i;
        uint64_t u64;
        int64_t  i64;
        uint32_t i32;
        size_t   len;
        int      status = -1;
    CODE:
        switch(option){
            case ZMQ_TYPE:
            case ZMQ_LINGER:
            case ZMQ_RECONNECT_IVL:
            case ZMQ_BACKLOG:
            case ZMQ_FD:
                len = sizeof(i);
                status = zmq_getsockopt(sock, option, &i, &len);
                if(status == 0)
                    RETVAL = newSViv(i);
                break;

            case ZMQ_RCVMORE:
            case ZMQ_SWAP:
            case ZMQ_RATE:
            case ZMQ_RECOVERY_IVL:
            case ZMQ_MCAST_LOOP:
                len = sizeof(i64);
                status = zmq_getsockopt(sock, option, &i64, &len);
                if(status == 0)
                    RETVAL = newSViv(i64);
                break;

            case ZMQ_HWM:
            case ZMQ_AFFINITY:
            case ZMQ_SNDBUF:
            case ZMQ_RCVBUF:
                len = sizeof(u64);
                status = zmq_getsockopt(sock, option, &u64, &len);
                if(status == 0)
                    RETVAL = newSVuv(u64);
                break;

            case ZMQ_EVENTS:
                len = sizeof(i32);
                status = zmq_getsockopt(sock, option, &i32, &len);
                if(status == 0)
                    RETVAL = newSViv(i32);
                break;

            case ZMQ_IDENTITY:
                len = sizeof(buf);
                status = zmq_getsockopt(sock, option, &buf, &len);
                if(status == 0)
                    RETVAL = newSVpvn(buf, len);
                break;
        }
        if(status != 0){
        switch(_ERRNO) {
            SET_BANG;
            case EINTR:
                    croak("The operation was interrupted by delivery of a signal");
            case ETERM:
                croak("The 0MQ context accociated with the specified socket was terminated");
            case EFAULT:
                croak("The provided socket was not valid");
                case EINVAL:
                    croak("Invalid argument");
            default:
                croak("Unknown error reading socket option");
        }
    }
    OUTPUT:
        RETVAL

int
PerlZMQ_Raw_zmq_setsockopt(sock, option, value)
        PerlZMQ_Raw_Socket *sock;
        int option;
        SV *value;
    PREINIT:
        STRLEN len;
        const char *ptr;
        uint64_t u64;
        int64_t  i64;
    CODE:
        switch(option){
            case ZMQ_IDENTITY:
            case ZMQ_SUBSCRIBE:
            case ZMQ_UNSUBSCRIBE:
                ptr = SvPV(value, len);
                RETVAL = zmq_setsockopt(sock, option, ptr, len);
                break;

            case ZMQ_SWAP:
            case ZMQ_RATE:
            case ZMQ_RECOVERY_IVL:
            case ZMQ_MCAST_LOOP:
                i64 = SvIV(value);
                RETVAL = zmq_setsockopt(sock, option, &i64, sizeof(int64_t));
                break;

            case ZMQ_HWM:
            case ZMQ_AFFINITY:
            case ZMQ_SNDBUF:
            case ZMQ_RCVBUF:
                u64 = SvUV(value);
                RETVAL = zmq_setsockopt(sock, option, &u64, sizeof(uint64_t));
                break;

            default:
                warn("Unknown sockopt type %d, assuming string.  Send patch", option);
                ptr = SvPV(value, len);
                RETVAL = zmq_setsockopt(sock, option, ptr, len);
        }
    OUTPUT:
        RETVAL

int
PerlZMQ_Raw_zmq_poll( list, timeout = 0 )
        AV *list;
        long timeout;
    PREINIT:
        I32 list_len;
        zmq_pollitem_t *pollitems;
        CV **callbacks;
        int i;
    CODE:
        list_len = av_len( list ) + 1;
        if (list_len <= 0) {
            XSRETURN(0);
        }

        Newxz( pollitems, list_len, zmq_pollitem_t);
        Newxz( callbacks, list_len, CV *);

        /* list should be a list of hashrefs fd, events, and callbacks */
        for (i = 0; i < list_len; i++) {
            SV **svr = av_fetch( list, i, 0 );
            HV  *elm;
            if (svr == NULL || ! SvOK(*svr) || ! SvROK(*svr) || SvTYPE(SvRV(*svr)) != SVt_PVHV) {
                Safefree( pollitems );
                Safefree( callbacks );
                croak("Invalid value on index %d", i);
            }
            elm = (HV *) SvRV(*svr);

            callbacks[i] = NULL;
            pollitems[i].revents = 0;
            pollitems[i].events  = 0;
            pollitems[i].fd      = 0;
            pollitems[i].socket  = NULL;

            svr = hv_fetch( elm, "socket", 6, NULL );
            if (svr != NULL) {
                MAGIC *mg;
                if (! SvOK(*svr) || !sv_isobject( *svr) || ! sv_isa(*svr, "ZeroMQ::Raw::Socket")) {
                    Safefree( pollitems );
                    Safefree( callbacks );
                    croak("Invalid 'socket' given for index %d", i);
                }
                mg = PerlZMQ_Raw_Socket_mg_find( aTHX_ SvRV(*svr), &PerlZMQ_Raw_Socket_vtbl );
                pollitems[i].socket = mg->mg_ptr;
            } else {
                svr = hv_fetch( elm, "fd", 2, NULL );
                if (svr == NULL || ! SvOK(*svr) || SvTYPE(*svr) != SVt_IV) {
                    Safefree( pollitems );
                    Safefree( callbacks );
                    croak("Invalid 'fd' given for index %d", i);
                }
                pollitems[i].fd = SvIV( *svr );
            }

            svr = hv_fetch( elm, "events", 6, NULL );
            if (svr == NULL || ! SvOK(*svr) || SvTYPE(*svr) != SVt_IV) {
                Safefree( pollitems );
                Safefree( callbacks );
                croak("Invalid 'events' given for index %d", i);
            }
            pollitems[i].events = SvIV( *svr );

            svr = hv_fetch( elm, "callback", 8, NULL );
            if (svr == NULL || ! SvOK(*svr) || ! SvROK(*svr) || SvTYPE(SvRV(*svr)) != SVt_PVCV) {
                Safefree( pollitems );
                Safefree( callbacks );
                croak("Invalid 'callback' given for index %d", i);
            }
            callbacks[i] = (CV *) SvRV( *svr );
        }

        /* now call zmq_poll */
        RETVAL = zmq_poll( pollitems, list_len, timeout );
        for ( i = 0; i < list_len; i++ ) {
            if (pollitems[i].revents & pollitems[i].events) {
                dSP;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                PUTBACK;

                call_sv( (SV*)callbacks[i], G_SCALAR );
                SPAGAIN;

                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        }
        Safefree(pollitems);
        Safefree(callbacks);
    OUTPUT:
        RETVAL

int
PerlZMQ_Raw_zmq_device( device, insocket, outsocket )
        int device;
        PerlZMQ_Raw_Socket *insocket;
        PerlZMQ_Raw_Socket *outsocket;
    CODE:
        RETVAL = zmq_device( device, insocket, outsocket );
    OUTPUT:
        RETVAL


