#!/usr/bin/env perl

use utf8;
use autodie;
use Data::Printer;

use Encode qw/decode/;
use Font::FreeType;

my @font_list = map { (split /:/, $_)[0] } `fc-list`;
@font_list = grep(/\.(ttf|odf)$/i, @font_list);
my $char = @ARGV[0];
my $char_code_hex = sprintf "%04x", ord decode('UTF-8', $char);
my $char_code_dec = sprintf "%04d", ord decode('UTF-8', $char);

foreach my $font (@font_list) {
    my $face = Font::FreeType->new->face($font);
    next unless $face->is_scalable;
    $face->set_char_size(0,0,0,0);

    my $glyph = $face->glyph_from_char_code(ord decode('UTF-8', $char));

    print "Font has $char \(hex: $char_code_hex, dec: $char_code_dec\): $font\n" if $glyph && $glyph->has_outline;
}
