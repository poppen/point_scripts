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
只今のTポイント：$point
$expiration_date
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
