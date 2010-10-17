#!/usr/bin/env perl

use warnings;
use strict;

use Config::Pit;
use WWW::Mechanize;
use Web::Scraper;

use utf8;
use Email::MIME;
use Email::MIME::Creator;
use Encode;

use Email::Sender::Simple 'sendmail';

my $email_config = pit_get(
    "personal.server",
    require => {
        "email"        => "your email address",
        "mobile_email" => "your mobile email address",
    }
);

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
        '/html/body/div/div[2]/div/div/div[2]/div[2]/div/div/dl/dd',
        'point' => 'TEXT'
    );
};

my $result                = $scraper->scrape( $mech->content );
my $point                 = $result->{point};
my $point_with_timelimits = $result->{point_with_timelimit};
my $expiration_dates      = $result->{expiration_date};

my $body = <<"EOF";
総保有ポイント：$point
EOF

my $email = Email::MIME->create(
    header => [
        From    => $email_config->{email},
        To      => $email_config->{mobile_email},
        Subject => encode(
            'MIME-Header-ISO_2022_JP' => '楽天スーパーポイント'
        ),
    ],
    attributes => {
        content_type => 'text/plain',
        charset      => 'ISO-2022-JP',
        encoding     => '7bit',
    },
    body => encode( 'iso-2022-jp' => $body ),
);

sendmail($email);
