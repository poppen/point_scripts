#!/usr/bin/env perl

use warnings;
use strict;

use Config::Pit;
use WWW::Mechanize;
use Web::Scraper;

my $rakuten_config = pit_get(
    "rakuten.co.jp",
    require => {
        "username" => "your username on rakuten",
        "password" => "your password on rakuten",
    }
);

my $mech = WWW::Mechanize->new();

$mech->get('http://www.rakuten.co.jp/');
$mech->follow_link( url_regex => qr/login/i );
$mech->submit_form(
    fields => {
        u => $rakuten_config->{username},
        p => $rakuten_config->{password},
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

my $body = <<"EOF";
Total: $point
Limited:
EOF

my $i = 0;
while ( $i < @$point_with_timelimits ) {
    $body .= sprintf( "%d(%s)\n",
        $point_with_timelimits->[$i],
        $expiration_dates->[$i] );
    $i++;
}

binmode(STDOUT, ":utf8");
print $body, "\n";
