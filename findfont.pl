#!/usr/bin/env perl

use utf8;
use autodie;
use Data::Printer;
use Encode qw/decode/;
use Font::FreeType;
use charnames ();

my @font_list = map { (split /:/, $_)[0] } `fc-list`;
@font_list = grep(/\.(ttf|odf)$/i, @font_list);

sub print_fonts {
    my ($char) = @_;
    my $char_code_hex = sprintf "%04x", ord decode('UTF-8', $char);
    my $char_code_dec = sprintf "%04d", ord decode('UTF-8', $char);
    my $char_name = charnames::viacode(hex($char_code_hex));

    print STDERR "Glyph:   $char\n";
    print STDERR "Name:    $char_name\n";
    print STDERR "Hex:     $char_code_hex\n";
    print STDERR "Decimal: $char_code_dec\n\n";

    foreach my $font (@font_list) {
        my $face = Font::FreeType->new->face($font);
        next unless $face->is_scalable;
        $face->set_char_size(0,0,0,0);

        my $glyph = $face->glyph_from_char_code(ord decode('UTF-8', $char));

        print "$font\n" if $glyph && $glyph->has_outline;
    }
}

sub print_glyph {
    binmode(STDOUT, ":utf8");
    my ($code) = @_;
    my $glyph = chr(hex($code));
    system('findfont.pl', '--glyph', $glyph);
}

sub main {
    my ($mode, $input) = @_;
    if($mode eq "--code") {
        print_glyph($input);
    }
    elsif($mode eq "--glyph") {
        print_fonts($input);
    }
}

main(@ARGV);
