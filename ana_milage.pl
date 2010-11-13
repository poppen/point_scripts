#!/usr/bin/env perl

use warnings;
use strict;

use Config::Pit;
use Getopt::Long;
use Pod::Usage;

use WWW::Mechanize;
use Web::Scraper;

use utf8;
use Email::MIME;
use Email::MIME::Creator;
use Encode;

use Email::Sender::Simple 'sendmail';

my $options = {
    from    => 'nobody@example.com',
    subject => "ANAマイル"
};

GetOptions(
    $options,
    'from=s',
    'subject=s',
    'help'
) or pod2usage();
pod2usage() if $options->{help};

pod2usage() unless $ARGV[0];
$options->{to} = $ARGV[0];

my $ana_config = pit_get(
    "ana.co.jp",
    require => {
        "username" => "your username on ana",
        "password" => "your password on ana",
    }
);

my $mech = WWW::Mechanize->new();

$mech->get('https://www.ana.co.jp/');
$mech->submit_form(
    form_name => 'loginForm',
    fields => {
        custno => $ana_config->{username},
        password => $ana_config->{password},
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
マイル口座残高：$total_mile
直近のマイル有効期限：
EOF
$body = encode('utf8' => $body);

for my $item (@items) {
    $body .= sprintf( "%s: %s\n" => $item->{date}, $item->{mile} );
}

my $email = Email::MIME->create(
    header => [
        From    => $options->{from},
        To      => $options->{to},
        Subject => encode(
            'MIME-Header-ISO_2022_JP' => $options->{subject}
        ),
    ],
    attributes => {
        content_type => 'text/plain',
        charset      => 'ISO-2022-JP',
        encoding     => '7bit',
    },
    body => encode( 'iso-2022-jp' => decode('utf8', $body) ),
);

sendmail($email);

__END__

=head1 NAME

ana_milage.pl - emailing ana milage

=head1 SYNOPSIS

ana_milage.pl [options] address

 Options:
   -f, --from      From address
   -s, --subject   Subject
   -h, --help      This help message

=cut

