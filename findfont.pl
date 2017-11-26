use utf8;
use autodie;

use Encode qw/decode/;
use Font::FreeType;

my ($font, $char) = @ARGV;

my $face = Font::FreeType->new->face($font);
$face->set_char_size(0,0,0,0);

my $glyph = $face->glyph_from_char_code(ord decode('UTF-8', $char));

print "Font has $char: $font\n" if $glyph && $glyph->has_outline;
