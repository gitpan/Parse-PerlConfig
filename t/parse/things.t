# parse() Thing_Order argument test
# $Id: things.t,v 1.3 2000/07/19 23:57:03 mfowler Exp $

# Verifies parse() handles its Thing_Order argument as advertised.


use Parse::PerlConfig;

use lib qw(t);
use parse::testconfig qw(ok);

use strict;
use vars qw(
    $tconf
    @scalars        @hashes_not_scalars             @io
    @not_scalars    @not_hashes_not_scalars         @not_io
);


$tconf = parse::testconfig->new('test.conf');


@scalars     = $tconf->symbols(Type => 'SCALAR');
@not_scalars = $tconf->symbols(NotType => 'SCALAR');

@hashes_not_scalars     = $tconf->symbols(Type => 'HASH', NotType => 'SCALAR');
@not_hashes_not_scalars = $tconf->symbols(NotType => [qw(SCALAR HASH)]);

@io     = $tconf->symbols(Type    => 'IO');
@not_io = $tconf->symbols(NotType => 'IO');


$tconf->tests(
    @scalars * 2    +       @hashes_not_scalars     +       @io     +
    @not_scalars    +       @not_hashes_not_scalars +       @not_io +
    $tconf->verify_parsed() * 3
);



# verify it pulls out only specified things, and nothing else
{
    my $parsed = Parse::PerlConfig::parse(
        File            =>      $tconf->file_path,
        Thing_Order     =>      '$'
    );


    $tconf->verify_parsed($parsed);

    verify_symbols_are_reftype  ($tconf, $parsed, "", \@scalars);
    verify_symbols_are_undefined($tconf, $parsed,     \@not_scalars);
}



# now, verify it pulls out multiple specified things
{
    my $parsed = Parse::PerlConfig::parse(
        File            =>      $tconf->file_path,
        Thing_Order     =>      '$%'
    );


    $tconf->verify_parsed($parsed);

    verify_symbols_are_reftype(
        $tconf, $parsed, "",     \@scalars
    );
    verify_symbols_are_reftype(
        $tconf, $parsed, "HASH", \@hashes_not_scalars
    );

    verify_symbols_are_undefined($tconf, $parsed, \@not_hashes_not_scalars);
}



# verify IO handles can be pulled out successfully
{
    my $parsed = Parse::PerlConfig::parse(
        File            =>      $tconf->file_path,
        Thing_Order     =>      'i',
    );


    $tconf->verify_parsed($parsed);

    # This is where it gets a little hairy.  ref on an IO thing
    # doesn't give 'IO', but usually IO::Handle.  We make our
    # check a little more liberal than the others.
    foreach my $symbol (@io) {
        $tconf->ok(
            ref($$parsed{$symbol}) =~ /IO/,
            "symbol $symbol is an IO handle"
        );
    }


    verify_symbols_are_undefined($tconf, $parsed, \@not_io);
}




# More tests could be added, and if the need arises, they will be.
# However, due to lack of tuits, they will be left as an exercise
# either for later, or for someone else.





sub verify_symbols_are_reftype {
    my($tconf, $parsed, $type, $symbols) = splice(@_, 0, 4);

    my $pretty_type;
    if ($type eq '') {
        $pretty_type = 'SCALAR';
    } else {
        $pretty_type = $type;
    }


    foreach my $symbol (@$symbols) {
        $tconf->ok(
            ref($$parsed{$symbol}) eq $type,
            "symbol $symbol is type $pretty_type"
        );
    }
}



sub verify_symbols_are_undefined {
    my($tconf, $parsed, $symbols) = splice(@_, 0, 3);

    foreach my $symbol (@$symbols) {
        $tconf->ok(
            !defined($$parsed{$symbol}),
            "symbol $symbol is undefined"
        );
    }
}
