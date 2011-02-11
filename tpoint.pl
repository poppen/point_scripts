#!/usr/bin/env perl

use warnings;
use strict;

use Config::Pit;
use WWW::Mechanize;
use Web::Scraper;

my $tsite_config = pit_get(
    "tsite",
    require => {
        "user" => "your username on tsite.jp",
        "pass" => "your password on tsite.jp",
    }
);

my $url = 'https://tsite.jp';

my $mech = WWW::Mechanize->new();

$mech->get($url);
$mech->follow_link( id => 'SideLoginBtn' );

$mech->form_name('form1')->action( $url . '/tm/pc/login/STKIp0001010.do' );
$mech->field('LOGIN_ID', $tsite_config->{user});
$mech->field('PASSWORD', $tsite_config->{pass});
my $response = $mech->submit();

my $scraper = scraper {
    process 'strong.SideMyPoint', 'point'           => 'TEXT';
    process 'p.Period1',          'expiration_date' => 'TEXT';
};

my $result          = $scraper->scrape( $mech->content );
my $point           = $result->{point};
my $expiration_date = $result->{expiration_date};

my $body = <<"EOF";
$point($expiration_date)
EOF

binmode(STDOUT, ":utf8");
print $body, "\n";
