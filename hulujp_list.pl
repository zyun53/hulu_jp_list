use strict;
use warnings;
use utf8;
use Encode;
use WWW::Mechanize;
use Web::Scraper;
use DBI;

my $database = 'list.db';
my $dbh = DBI->connect("dbi:SQLite:dbname=list.db");
my $insert_sql = 'INSERT INTO content (url_name, title, season, episode, release, insert_date) values ( ?, ?, ?, ?, ?, ?);';
my $sth = $dbh->prepare($insert_sql);

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
            process 'span.decades', release => 'TEXT';
        }
    };

    $res = $s->scrape($mech->content);

    foreach my $line (@{$res->{list}}) {
        $line->{link} =~ /\.jp\/(.+)$/;
        my @insert_values = ( $1, $line->{title} ); #url_name, title

        if (defined($line->{append})) {
            $line->{append} =~ /(\d+).*\|\D+(\d+)\D/;
            push @insert_values, $1; #season
            push @insert_values, $2; #episode
        } else {
            push @insert_values, '0'; #season
            push @insert_values, '0'; #episode
        }


        $line->{release} =~ /(\d+)/;
        push @insert_values, $1;
        push @insert_values, "20120403";

        $sth->execute(@insert_values) or print "@insert_values";

    }

    $mech->follow_link(text => 'next');

}

