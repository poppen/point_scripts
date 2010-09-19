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

my $tsite_config = pit_get(
    "tsite.jp",
    require => {
        "username" => "your username on tsite.jp",
        "password" => "your password on tsite.jp",
    }
);

my $mech = WWW::Mechanize->new();

$mech->get('https://tsite.jp/');
$mech->submit_form(
    fields => {
        kaiin_no => $tsite_config->{username},
        password => $tsite_config->{password},
    },
    button => 'on_next',
);
$mech->get('https://tsite.jp/');

my $scraper = scraper {
    process 'strong.SideMyPoint', 'point'           => 'TEXT';
    process 'p.Period1',          'expiration_date' => 'TEXT';
};

my $result          = $scraper->scrape( $mech->content );
my $point           = $result->{point};
my $expiration_date = $result->{expiration_date};

my $body = <<"EOF";
只今のTポイント：$point
Tポイント有効期限：$expiration_date
EOF

my $email = Email::MIME->create(
    header => [
        From    => $email_config->{email},
        To      => $email_config->{mobile_email},
        Subject => encode( 'MIME-Header-ISO_2022_JP' => 'Tポイント' ),
    ],
    attributes => {
        content_type => 'text/plain',
        charset      => 'ISO-2022-JP',
        encoding     => '7bit',
    },
    body => encode( 'iso-2022-jp' => $body ),
);

sendmail($email);
