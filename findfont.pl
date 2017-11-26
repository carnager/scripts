#!/usr/bin/env perl

use utf8;
use autodie;
use Data::Printer;
use Encode qw/decode encode/;
use Font::FreeType;
use charnames ();
use Pod::Usage qw(pod2usage);

my @font_list = map { (split /:/, $_)[0] } `fc-list`;
@font_list = grep(/\.(ttf|odf)$/i, @font_list);

sub print_fonts {
    my ($char, $hex, $char_name) = @_;
    $char = encode('UTF-8', $char);

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
    binmode(STDOUT, ":utf8");
    my ($hex) = @_;
    my $glyph = chr(hex($hex));
    my $char_name = charnames::viacode($hex);
    return($glyph, $hex, $char_name);
}

sub get_vars_from_glyph {
    my ($glyph) = @_;
    my $hex = sprintf "%04x", ord decode('UTF-8', $glyph);
    my $char_name = charnames::viacode(hex($hex));
    return($glyph, $hex, $char_name);
}
    
sub main {
    my ($glyph, $hex, $char_name);
    my ($mode, $input) = @_;

    if($mode eq "--hex") {
        ($glyph, $hex, $char_name) = get_vars_from_hex($input);
    }
    elsif($mode eq "--char") {
        ($glyph, $hex, $char_name) = get_vars_from_glyph($input);
        $glyph = decode('UTF-8', $glyph);
    }
    else {
        pod2usage(1);
    }
    print_fonts($glyph, $hex, $char_name);
}

main(@ARGV);

__END__
=head1 NAME

findfonts.pl - find fonts providing certain characters

=head1 SYNOPSIS

findfonts.pl [command] {hex,glyph}

  Commands:
    --hex         Search fonts by hex code.
    --char        Search fonts by glyph.

  Examples:
    findfonts.pl --hex 1f49f
    findfonts.pl --char 💟

findfonts.pl version 0.1

=cut
