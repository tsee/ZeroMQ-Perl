use strict;
use Config;
use File::Spec;
use File::Basename ();

write_constants_file( File::Spec->catfile('xs', 'const-xs.inc') );
write_typemap( File::Spec->catfile('xs', 'typemap') );
write_magic_file( File::Spec->catfile('xs', 'mg-xs.inc') );

sub write_magic_file {
    my $file = shift;

    open my $fh, '>', $file or
        die "Could not open objects file $file: $!";

    print $fh <<EOM;
STATIC_INLINE
int
PerlZMQ_mg_free(pTHX_ SV * const sv, MAGIC *const mg ) {
    PERL_UNUSED_VAR(sv);
    Safefree(mg->mg_ptr);
    return 0;
}

STATIC_INLINE
int
PerlZMQ_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param) {
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
    return 0;
}

EOM
    open my $src, '<', "xs/perl_zeromq.xs";
    my @perl_types = qw(
        ZeroMQ::Raw::Context
        ZeroMQ::Raw::Socket
        ZeroMQ::Raw::Message
        ZeroMQ::Raw::PollItem
    );
    foreach my $perl_type (@perl_types) {
        my $c_type = $perl_type;
        $c_type =~ s/::/_/g;
        $c_type =~ s/^ZeroMQ/PerlZMQ/;
        my $vtablename = sprintf '%s_vtbl', $c_type;

        # check if we have a function named ${c_type}_free and ${c_type}_mg_dup
        my ($has_free, $has_dup);
        seek ($src, 0, 0);
        while (<$src>) {
            $has_free++ if /^${c_type}_mg_free\b/;
            $has_dup++ if /^${c_type}_mg_dup\b/;
        }

        my $free = $has_free ? "${c_type}_mg_free" : "PerlZMQ_mg_free";
        my $dup  = $has_dup  ? "${c_type}_mg_dup"  : "PerlZMQ_mg_dup";
        print $fh <<EOM
static MGVTBL $vtablename = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    $free, /* free */
    NULL, /* copy */
    $dup, /* dup */
#ifdef MGf_LOCAL
    NULL  /* local */
#endif
};

EOM
    }

}

sub write_constants_file {
    my $file = shift;

    my $header = $ENV{ZMQ_H};
    if ( ! $header ) {
        my @locations = ('/usr/local', '/usr', File::Basename::dirname($^X) );
        foreach my $loc ( @locations ) {
            my $candidate = File::Spec->catfile( $loc, 'include', 'zmq.h' );
            if ( -f $candidate ) {
                $header = $candidate;
                last;
            }
        }
    }

    if (! $header) {
        die "Could not find zmq.h anywhere.";
    }
    print STDERR " + Using zmq.h from $header\n";

    open( my $in, '<', $header ) or
        die "Could not open file $header for reading: $!";

    open( my $out, '>', $file ) or
        die "Could not open file $file for writing: $!";
    print $out
        "# Do NOT edit this file! This file was automatically generated\n",
        "# by Makefile.PL on @{[scalar localtime]}. If you want to\n",
        "# regenerate it, remove this file and re-run Makefile.PL\n",
        "\n",
        "IV\n",
        "_constant()\n",
        "    ALIAS:\n",
    ;


    while (my $ln = <$in>) {
        if ($ln =~ /^\#define\s+(ZMQ_[A-Z0-9_]+)\s+/) {
            print $out "        $1 = $1\n";
        }
    }
    close $in;
    print $out
        "    CODE:\n",
        "        RETVAL = ix;\n",
        "    OUTPUT:\n",
        "        RETVAL\n"
    ;
    close $out;
}

sub write_typemap {
    my $file = shift;

    my @perl_types = qw(
        ZeroMQ::Raw::Context
        ZeroMQ::Raw::Socket
        ZeroMQ::Raw::Message
    );

    open( my $out, '>', $file ) or
        die "Could not open $file for writing: $!";

    my (@decl, @input, @output);
    foreach my $perl_type (@perl_types) {
        my $c_type = $perl_type;
        $c_type =~ s/::/_/g;
        $c_type =~ s/^ZeroMQ_/PerlZMQ_/;
        my $typemap_type = 'T_' . uc $c_type;

        push @decl, "$c_type* $typemap_type";
        push @input, <<EOM;
$typemap_type
    {
        MAGIC *mg;
        \$var = NULL;
        if (sv_isobject(\$arg)) {
            mg = ${c_type}_mg_find(aTHX_ SvRV(\$arg), &${c_type}_vtbl);
            if (mg) {
                \$var = ($c_type *) mg->mg_ptr;
            }
        }

        if (\$var == NULL)
            croak(\\"Invalid $perl_type object (perhaps you've already freed it?)\\");
    }
EOM
        push @output, <<EOM;
$typemap_type
        if (!\$var)          /* if null */
            SvOK_off(\$arg); /* then return as undef instead of reaf to undef */
        else {
            /* setup \$arg as a ref to a blessed hash hv */
            MAGIC *mg;
            HV *hv = newHV();
            const char *classname = \\"$perl_type\\";
            /* take (sub)class name to use from class_sv if appropriate */
            if (SvMAGICAL(class_sv))
                mg_get(class_sv);

            if (SvOK( class_sv ) && sv_derived_from(class_sv, classname ) ) {
                if(SvROK(class_sv) && SvOBJECT(SvRV(class_sv))) {
                    classname = sv_reftype(SvRV(class_sv), TRUE);
                } else {
                    classname = SvPV_nolen(class_sv);
                }
            }

            sv_setsv(\$arg, sv_2mortal(newRV_noinc((SV*)hv)));
            (void)sv_bless(\$arg, gv_stashpv(classname, TRUE));
            mg = sv_magicext((SV*)hv, NULL, PERL_MAGIC_ext, &${c_type}_vtbl, (char*) \$var, 0);
            mg->mg_flags |= MGf_DUP;
        }
EOM
    }

    print $out
        "# Do NOT edit this file! This file was automatically generated\n",
        "# by Makefile.PL on @{[scalar localtime]}. If you want to\n",
        "# regenerate it, remove this file and re-run Makefile.PL\n",
        "\n"
    ;
    print $out join( "\n",
        "TYPEMAP\n",
        join("\n", @decl), 
        "\n",
        "INPUT\n",
        join("\n", @input),
        "\n",
        "OUTPUT\n",
        join("\n", @output),
        "\n",
    );

    close $out;
}

