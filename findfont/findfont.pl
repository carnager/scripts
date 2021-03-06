#!/usr/bin/env perl

use utf8;
use autodie;
use strict;
use warnings;
use autodie;
#use Data::Printer;
use Encode qw/decode encode/;
use Font::FreeType;
use Getopt::Long;
use charnames ();
use Pod::Usage qw(pod2usage);

my @font_list = map { (split /:/, $_)[0] } `fc-list`;
@font_list = grep(/\.(ttf|odf)$/i, @font_list);

my ($opt_hex, $opt_help, $opt_char);

GetOptions ("x|hex=s"  => \$opt_hex,
            "c|char=s" => \$opt_char,
            "h|help"   => \$opt_help)
or die("Invalid option. Try --help\n");

sub print_fonts {
    my ($char, $hex, $char_name) = @_;
    $char                        = encode('UTF-8', $char);

    print STDERR "Glyph:   $char\n";
    print STDERR "Name:    $char_name\n";
    print STDERR "Hex:     $hex\n\n";

    foreach my $font (@font_list) {
        my $face = Font::FreeType->new->face($font);
        next unless $face->is_scalable;
        $face->set_char_size(0,0,0,0);

        my $glyph = $face->glyph_from_char_code(ord decode('UTF-8', $char));
        print "$font\n" if $glyph && $glyph->has_outline;
    }
}

sub get_vars_from_hex {
    my ($hex)     = @_;
    my $glyph     = chr(hex($hex));
    my $char_name = charnames::viacode($hex);

    return($glyph, $hex, $char_name);
}

sub get_vars_from_glyph {
    my ($glyph)   = @_;
    my $hex       = sprintf "%04x", ord decode('UTF-8', $glyph);
    my $char_name = charnames::viacode(hex($hex));

    return($glyph, $hex, $char_name);
}
    
sub main {
    my ($glyph, $hex, $char_name);

    if   (defined $opt_hex)  { ($glyph, $hex, $char_name) = get_vars_from_hex($opt_hex); }
    elsif(defined $opt_char) { ($glyph, $hex, $char_name) = get_vars_from_glyph($opt_char); $glyph = decode('UTF-8', $glyph); }
    else                     { pod2usage(1); die unless(defined $opt_help)}

    print_fonts($glyph, $hex, $char_name);
}

main();

__END__
=head1 NAME

findfonts.pl - find fonts providing certain characters

=head1 SYNOPSIS

findfonts.pl [command] [hex,glyph]

  Commands:
    -x, --hex         Search fonts by hex code.
    -c, --char        Search fonts by glyph.
    -h, --help        Show this help.

  Examples:
    findfonts.pl --hex 1f49f
    findfonts.pl --char 💟

findfonts.pl version 0.1

=cut
