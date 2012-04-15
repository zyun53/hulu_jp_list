use strict;
use warnings;
use utf8;
use Encode;
use WWW::Mechanize;
use Web::Scraper;
use DBI;

my $mech = new WWW::Mechanize( autocheck => 1 );

$mech->get('http://www2.hulu.jp/content');

my $s = scraper {
    process '.total', count => 'TEXT';
};

my $res = $s->scrape($mech->content);

my $result_count = $res->{count};

for (my $i = 0; $i < $result_count; $i++) {

    $s = scraper {
        process '.show-title-container', 'list[]' => scraper {
            process '.bold-link', title => 'TEXT';
            process '.bold-link', link => '@href';
            process 'span.season-episode-count' , append => 'TEXT';
        }
    };

    $res = $s->scrape($mech->content);

    foreach my $line (@{$res->{list}}) {
        print encode('utf-8', $line->{title} . ' ' . $line->{link} . ' ');
        if (defined($line->{append})) {
            print encode('utf-8', $line->{append});
        }
        print "\n";
    }

    $mech->follow_link(text => 'next');

}

