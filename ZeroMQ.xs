
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#undef do_open
#undef do_close
#ifdef __cplusplus
}
#endif

#include "zmq.hpp"

using namespace std;
using namespace zmq;

#include "const-c.inc"

MODULE = ZeroMQ	PACKAGE = ZeroMQ

INCLUDE: const-xs.inc

INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp ZeroMQ.xsp

