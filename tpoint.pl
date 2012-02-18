#!/usr/bin/env perl

use warnings;
use strict;

use Getopt::Long;
use Config::Pit;
use WWW::Mechanize;
use Web::Scraper;

my $opt_expiration_date = 0;
GetOptions(
    expire => \$opt_expiration_date
);

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
$mech->follow_link( url => 'https://tsite.jp/tm/pc/login/STKIp0001001.do' );

$mech->form_name('form1')->action( $url . '/tm/pc/login/STKIp0001010.do' );
$mech->field('LOGIN_ID', $tsite_config->{user});
$mech->field('PASSWORD', $tsite_config->{pass});
my $response = $mech->submit();

my $scraper = scraper {
    process 'p.point > span.number', 'point'           => 'TEXT';
    process 'ul.c_period > li',      'expiration_date' => 'TEXT';
};

my $result          = $scraper->scrape( $mech->content );
my $point           = $result->{point};
my $expiration_date = $result->{expiration_date};

my $body = $point . "\n";
if ($opt_expiration_date) {
    $body .= $expiration_date . "\n";
}

binmode(STDOUT, ":utf8");
print $body;
