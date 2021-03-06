#!/usr/bin/env perl

#020622

$|++;
use GD;
use Image::Size;
use HTML::Entities 'encode_entities';
use Getopt::Long;

$start = "";
$end = "";
GetOptions(
    "start|s=i" => \$start,
    "end|e=i" => \$end,
);

@years=();
for $year (grep {(-d) and /^(19|20)\d\d$/} <*>) {
    @albums=();
    chdir $year or die "Can't chdir to $year: $!\n";
    for $dir (grep {(-d) and /^\d{8}(-[A-Za-z])?$/} <*>) {
        chdir $dir or die "Can't chdir to $year/$dir: $!\n";
        $process_images = not($start and $dir lt $start or $end and $dir gt $end);
        
        $album_title = '';
        @album = ();
        open F,"titles.txt" or do { warn "dir $dir doesn't have titles.txt, skipped.\n"; next};

        print "+ $dir...\n";
        while (<F>) {
            s/\r|\n//g;
            next unless /\S/;
            if (/^\[(.+)\]/) {$album_title=$1; next}
            if (/^(\S+):(.*)/) {
                $filename = $1; $pic_title = $2 ? $2 : "(no picture title)";
                
                if ($process_images) {
                    # generate thumbnail if not already exists
                    if (-f $filename) {
                        ($tnname = $filename) =~ s/\.jpg$//i; $tnname .= ".tn.png";
                        ($x,$y) = imgsize($filename);
                        if (!-f $tnname) {
                            print "+ generating thumbnail $dir/$tnname...\n";
                            $image = GD::Image->newFromJpeg($filename);
                            $x2 = 120; $y2 = int($y/$x*$x2);
                            $image2 = GD::Image->new($x2, $y2);
                            $image2->copyResized($image, 0, 0, 0, 0, $x2, $y2, $x, $y);
                            open F2, ">$tnname";
                            print F2 $image2->png;
                            close F2 or die "Can't write $dir/$tnname: $!\n";
                        }
                    } else {
                        #warn "$year/$dir/$filename: doesn't exist\n";
                    }
                }

                push @album,[$filename, $tnname, $pic_title, "${x}x$y", sprintf("%.0fK",(-s $filename)/1024)];
                next;
            }
            warn "$year/$dir/titles.txt: syntax error at line $.: $_\n";
        }
        close F;
        $album_title ||= "(no album title)";
        
        if ($process_images) {
            open F,">index.html";
            print F "<title>${\( encode_entities $album_title )}</title><h3>${\( encode_entities $album_title )}</h3>";
            print F "<a href=../index.html>up</a>";
            print F "<table border cellpadding=10>\n";
        
            $col=0;
            for (@album) {
                print F "<tr>" if $col++==0;
                print F "<td valign=top><a href=$_->[0]><img width=120 src=$_->[1]></a><small><br>${\( encode_entities $_->[2] )}<p><small>$_->[0], $_->[3], $_->[4]</small></small></td>";
                do{print F "</tr>";$col=0} if $col==5;
            }
            print F "</tr>" if $col==0;
            print F "</table>\n";
            print F "<a href=../index.html>up</a>";
            close F or die "Can't write $year/$dir/index.html: $!\n";
        }
        
        push @albums, [$dir, $album_title, scalar @album];
        chdir ".." or die "Can't chdir back: $!\n";
    }

    open F,">index.html";
    print F "<title>$year Albums</title><h2>$year</h2>";
    print F "<a href=../index.html>up</a>\n";
    print F "<ol>";
    for (@albums) {
        print F "<li>$_->[0] - <a href=$_->[0]/index.html>$_->[1]</a>, $_->[2] picture(s)\n";
    }
    print F "</ol>\n";
    print F "<a href=../index.html>up</a>\n";
    close F or die "Can't write to $year/index.html: $!\n";

    $totpic = 0; $totpic += $_->[2] for @albums;
    push @years, [$year, scalar(@albums), $totpic];
    chdir ".." or die "Can't chdir back: $!\n";
}

open F,">index.html";
print F "<title>All Albums</title><h1>All albums</h1>\n";
print F "<ol>";
for (@years) {
    print F "<li><a href=$_->[0]/index.html>$_->[0]</a>, $_->[1] album(s), $_->[2] picture(s)\n";
}
print F "</ol>\n";
close F or die "Can't write to index.html: $!\n";
                                            