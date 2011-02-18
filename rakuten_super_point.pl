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

my $rakuten_config = pit_get(
    "rakuten.co.jp",
    require => {
        "user" => "your username on rakuten",
        "pass" => "your password on rakuten",
    }
);

my $mech = WWW::Mechanize->new();

$mech->get('http://www.rakuten.co.jp/');
$mech->follow_link( url_regex => qr/login/i );
$mech->submit_form(
    fields => {
        u => $rakuten_config->{user},
        p => $rakuten_config->{pass},
    }
);
$mech->get('https://point.rakuten.co.jp/Top/TopDisplay/');

my $scraper = scraper {
    process(
        'id("pointAccount")//dl[@class="total"]/dd',
        'point' => 'TEXT'
    );

    process(
        'id("pointAccount")//div[@class="pointDetail"]/dl[@class="limitedBorder scroll"]/dt',
        'expiration_date[]' => 'TEXT'
    );

    process(
        'id("pointAccount")//div[@class="pointDetail"]/dl[@class="limitedBorder scroll"]/dd',
        'point_with_timelimit[]' => 'TEXT'
    );
};

my $result                = $scraper->scrape( $mech->content );
my $point                 = $result->{point};
my $point_with_timelimits = $result->{point_with_timelimit};
my $expiration_dates      = $result->{expiration_date};

my $body = $point . "\n";

if ($opt_expiration_date) {
    my $i = 0;
    while ( $i < @$point_with_timelimits ) {
        $body .= sprintf( "%d(%s)\n",
            $point_with_timelimits->[$i],
            $expiration_dates->[$i] );
        $i++;
    }
}

binmode(STDOUT, ":utf8");
print $body;
