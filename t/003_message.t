use strict;
use Test::More;
use Test::Exception;
BEGIN {
    use_ok "ZeroMQ::Raw", qw(
        zmq_msg_init
        zmq_msg_init_data
        zmq_msg_init_size
        zmq_msg_data
        zmq_msg_size
        zmq_msg_copy
        zmq_msg_move
    );
}

subtest "sane allocation / cleanup for message" => sub {
    lives_ok {
        my $msg = ZeroMQ::Raw::zmq_msg_init();
        isa_ok $msg, "ZeroMQ::Raw::Message";
        is zmq_msg_data( $msg ), '', "no message data";
        is zmq_msg_size( $msg ), 0, "data size is 0";
    } "code lives";
};

subtest "sane allocation / cleanup for message (init_data)" => sub {
    lives_ok {
        my $data = "TESTTEST";
        my $msg = zmq_msg_init_data( $data );
        isa_ok $msg, "ZeroMQ::Raw::Message";
        is zmq_msg_data( $msg ), $data, "data matches";
        is zmq_msg_size( $msg ), length $data, "data size matches";
    } "code lives";
};

subtest "sane allocation / cleanup for message (init_size)" => sub {
    lives_ok {
        my $msg = zmq_msg_init_size(100);
        isa_ok $msg, "ZeroMQ::Raw::Message";

        # don't check data(), as it will be populated with garbage
        is zmq_msg_size( $msg ), 100, "data size is 100";
    } "code lives";
};

subtest "copy / move" => sub {
    lives_ok {
        my $msg1 = zmq_msg_init_data( "foobar" );
        my $msg2 = zmq_msg_init_data( "fogbaz" );
        my $msg3 = zmq_msg_init_data( "figbun" );

        is zmq_msg_copy( $msg1, $msg2 ), 0, "copy returns 0";
        is zmq_msg_data( $msg1 ), zmq_msg_data( $msg2 ), "msg1 == msg2";
        is zmq_msg_data( $msg1 ), "fogbaz", "... and msg2's data is in msg1";
    } "code lives";
};

done_testing;