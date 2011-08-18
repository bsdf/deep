package App::deep;

use strict;
use warnings;
use File::Copy;
use File::Find;
use Getopt::Long;
use File::Basename;
use Term::ANSIColor;

# variables for commandline args
my $types;         # = qw(img);
my $skip             = "";
my $target           = ".";
my $output           = "./_deep";
my $keep_structure   = 0;
my $make_unique      = 0;
my $replace          = 0;
my $use_magic        = 0;
my $verbose          = 0;
my $quiet            = 0;
my $explore_archives = 0;

# variables for current file info
my $file_ext;
my $file_name;
my $file_path;

# file classes
# img, imgx, mov, mp3, txt, doc
my %file_classes = (
    img  => [qw<jpg jpeg gif png bmp>          ],
    imgx => [qw<xpm ico tiff>                  ],
    mov  => [qw<avi mpg mpeg ogm mkv mov>      ],
    mp3  => [qw<wav aiff mp3 m4a ogg flac mid> ],
    txt  => [qw<txt README TODO>               ],
    doc  => [qw<doc docx ppt pptx xls xlsx pdf>],
);

my $result = GetOptions(
    "t|type|types=s"     => \$types,
    "o|out=s"            => \$output,
    "x|skip=s"           => \$skip,
    "u|make-unique"      => \$make_unique,
    "R|replace"          => \$replace,
    "v|verbose"          => \$verbose,
    "q|quiet"            => \$quiet,
);
#    "k|keep-structure"   => \$keep_structure,
#    "m|magic|use-magic"  => \$use_magic,
#    "z|explore-archives" => \$explore_archives,

#print_dbg() if $verbose;

# consolidate all filetypes into one var
my @match_types = consolidate_types( $types ? $types : "img" );

# parse the --skips= option
my @skips = qw(_deep .git .svn);
@skips = ( @skips, split ( /\s*,\s*/, $skip ));

# create output folder if it doesnt already exist
mkdir $output if ! -e $output;

# options
my %opts = (
    wanted   => \&deep,
    no_chdir => 1,
);

# go 
find( \%opts, @ARGV ? @ARGV : '.' );

print_summary() if not $quiet;

sub deep {
    if ( check_skip($_) ) {
        nega( "skipping $_\n" ) if $verbose and $_ ne "_deep";
        $File::Find::prune = 1;
        return;
    }   

    #print "Got name = [$File::Find::name] dir = [$File::Find::dir]\n";
    if ( check_file($_) ) {
        store_file($_);
    }
}

sub store_file {
    my $file = shift;

    if ( $keep_structure ) {
        # TODO implement this
    }
    else {
        # process filename
        if ( $make_unique || (-e "$output/$file_name" && !$replace )) {
            # encode dir in filename:
            # ex: ./foo/bar/box.jpg becomes foo_bar_box.jpg
            $file =~ s/^\.\///g;    # remove ./
            $file =~ s/\//_/g;      # turn / into _
        }
        else {
            $file = $file_name;
        }

        copy $File::Find::name, "$output/$file"; #or die "$! $_";
    }

    posi( "moved $_ to $output/$file\n" ) if $verbose;
}

sub check_file {
    my $file = shift;

    # first check file extension
    ($file_name, $file_path, $file_ext) = fileparse($file, qr/([^.]*)$/) or return;
    # bleh.
    $file_name = "$file_name$file_ext";

    if ( $file_ext ~~ @match_types ) {
        # posi( "$_ matched by extension $file_ext\n" ) if $verbose;
        return 1;
    }
    # then try magic
    elsif ( $use_magic and check_magic($_) ) {
        posi( "$_ matched by ~*magic*~\n" ) if $verbose;
        return 1;
    }

    return 0;
}

sub check_magic {
    my $file = shift;
    # TODO
    return;
}

sub check_skip {
    s/^\.\///g;
    return $_ ~~ @skips;
}

sub consolidate_types {
    my $str   = shift;
    my @out;
    my @types = split ( /\s*,\s*/, $str );

    # uniqify
    @types = keys %{{ map { $_ => 1 } @types }};

    for my $key ( @types ) {
        if ( my $item = $file_classes{$key} ) {
            push @out, @{ $item };
        }
    }

    return @out;
}

sub posi {
    print '[';
    print colored ['green'], '~';
    print '] ';
    print @_;
}

sub nega {
    print '[';
    print colored ['red'], '-';
    print '] ';
    print @_;
}

sub print_summary {
    return;
    # prints a summary of files found
    # ascii graph too

    print <<END;

50 files found in ~/Desktop  [**********          ]
25 files found in ~/Pictures [*****               ]
25 files found in ~/pix      [*****               ]
1  file  found in ~/xxx      [*                   ]

END
}

sub print_dbg {
    print <<END;

        deep
     --types:\t$types
    --target:\t$target
    --kstrct:\t$keep_structure
     --magic:\t$use_magic
   --verbose:\t$verbose
     --quiet:\t$quiet

END
}

# deep --file-types=xpm,ico --out=~/pix ~/slackware-1.3.3.7
# deep --types=img,mov --keep-structure .
# deep --type=img --pipe ~/private_pix | tar -czvf xxx.tar.gz
# deep --type=img -0 ~/private_pix | tar -czvf xxx.tar.gz

__END__

=head1 NAME

deep - excavate computer artifacts


=head1 SYNOPSIS

"better than find -lsdkfj a;sld ajksjfl;jdflk {}\;"


=head1 DESCRIPTION

deep excavates interesting artifacts from complex folder trees.

deep will dive into a folder and return with all interesting files contained
within. 

.ini and .tmp files are boring, .gif and .mp3 files are interesting

=head1 USEAGE

    # find all pictures in ~/1997_backup 
    # and put em in ~/pix
    deep --type=img --out=~/pix ~/1997_backup

    # find all pictures and movies in ~/gnome-0.12
    # and put em in ./_deep
    deep --types=img,mov ~/gnome-0.12 --verbose

    # find all audio files in ~/old_hd
    # and put em in ~/audio with unique names.
    # ~/old_hd/wavs/duckjob.wav becomes old_hd_wavs_duckjob.wav
    deep --type=mp3 --out=~/audio ~/old_hd --make-unique


=head1 FILE CLASSES

deep categorizes interesting files into the following classes,
specified by the --type parameter:

    img, imgx, mov, mp3, txt, doc

the following sections list all file extensions in each class.

=head2 IMG

jpe?g, gif, png, bmp

=head2 IMGX

xpm, ico, tiff

=head2 MOV

avi, mpe?g, ogm

=head2 MP3

wav, aiff, mp3, m4a, ogg, flac, mid

=head2 TXT

txt, README, TODO

=head2 DOC

docx?, pdf, pptx?, xlsx?


=head1 AUTHOR

bEN ENGLISCH <EMAILBEN145@gmail.com>

=head1 COPYRIGHT AND LICENSE

copyright 2011 bEN ENGLISCH <EMAILBEN145@gmail.com>

this app is free software; u may redistribute it and/or modify
it under the same terms as perl itself.
