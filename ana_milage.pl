#!/usr/bin/env perl

use warnings;
use strict;

use Encode;
use Config::Pit;
use WWW::Mechanize;
use Web::Scraper;

my $ana_config = pit_get(
    "ana.co.jp",
    require => {
        "user" => "your username on ana",
        "pass" => "your password on ana",
    }
);

my $mech = WWW::Mechanize->new();

$mech->get('https://www.ana.co.jp/');
$mech->submit_form(
    form_name => 'loginForm',
    fields => {
        custno => $ana_config->{user},
        password => $ana_config->{pass},
    }
);
$mech->submit();
$mech->get('https://stmt.cam.ana.co.jp/psz/amcj/jsp/renew/mile/reference.jsp');

my $scraper = scraper {
    process(
        'id("gaiyoubox")//table[1]//strong',
        'total_mile' => 'TEXT'
    );

    process(
        'id("gaiyoubox")//table[@class="mile-tbl bold"]/tr[position() > 1]',
            'items[]' => scraper {
                process('th', 'date' => 'TEXT');
                process('td', 'mile' => 'TEXT');
            }
    );
};

my $result =
    $scraper->scrape( encode('utf8' =>decode('euc-jp' => $mech->content)) );
my $total_mile = $result->{total_mile};
my @items      = @{$result->{items}};

my $body = <<"EOF";
Total:$total_mile
Expire:
EOF
$body = encode('utf8' => $body);

for my $item (@items) {
    $body .= sprintf( "%s: %s\n" => $item->{date}, $item->{mile} );
}

print $body, "\n";
