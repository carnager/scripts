#!/usr/bin/perl

binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";
use v5.24;
use warnings;
use strict;
use utf8;
use Data::Printer;
use Data::Section::Simple qw(get_data_section);
use Encode qw(decode encode);
use Net::MPD;
use Scalar::Util qw(looks_like_number);
use Text::Markdown 'markdown';


my $audio_player = get_data_section('audioPlayer');
my $html_header = get_data_section('html_header');
my $html_footer = get_data_section('html_footer');
my $style = get_data_section('style');
my $music_root = "/mnt/wasteland/Audio/Rips";
my $year;
my $mpd //= Net::MPD->connect($ENV{MPD_HOST} // 'localhost');

sub check_for_year {
    $year = $ARGV[0];
    my $arg_check = looks_like_number( $year );
    if ($arg_check > 0) {
        my $num_args   = $#ARGV + 1;
        if ($num_args != 1) { print "\nUsage: toplist.pl YEAR\n"; exit; }
    }
}

sub get_items_from_playlist {
    my @album_ratings       = $mpd->sticker_find("song", "albumrating");
    my %album_ratings       = map {$_->{file} => $_->{sticker}} @album_ratings;
    my @playlist_items      = $mpd->list_playlist_info($year);

    my @rated_items = map {
        $_->{albumrating}   = $album_ratings{$_->{uri}};
        $_->{safe_filename} = get_safe_filename($_);
        $_->{info}          = markdown(get_info($_->{safe_filename}, "info"));
        $_->{review}        = markdown(get_info($_->{safe_filename}, "reviews"));
        $_->{songlist}      = get_song_list($_);
        $_->{tracklist_md}  = gen_tracklist_md($_->{songlist}, $_->{Title});
        +{$_->%{qw/Album Date AlbumArtist Track Title albumrating safe_filename info tracklist_md review uri/}}
    } @playlist_items;
}

sub gen_tracklist_md {
    my ($song_titles, $playlist_title) = @_; my @tracklist_markdown = map { "<li>$_</li>" } @$song_titles;
    my $tracklist_markdown = join "\n", @tracklist_markdown;
    $tracklist_markdown =~ s/<li>$playlist_title<\/li>/<li><a style='color:red'>$playlist_title<\/a><\/li>/;
    return $tracklist_markdown;
}

sub get_safe_filename {
    my $safe_uri        = $_[0]->{AlbumArtist};
    $safe_uri           =~ s/[^A-Za-z0-9\-\.]//g;
    $safe_uri           = substr($safe_uri, 0, 10);
    $safe_uri           = "$_[0]->{Date}-$safe_uri";
}

sub get_song_list {
    my @songlist;
    my @albumtracks     = $mpd->find('AlbumArtist', $_[0]->{AlbumArtist}, 'Date', $_[0]->{Date}, 'Album', $_[0]->{Album});
    foreach my $songtitle (@albumtracks) {
        push @songlist, $songtitle->{Title};
    }
    return (\@songlist);
}


sub get_info {
    my ($filename, $source) = @_;
    open(my $fh, '<:encoding(UTF-8)', "$source/${filename}.md") or die "cannot open file $filename"; {
        local $/;
        return <$fh>;
    }
}

sub set_files {

    unless (-e "css" or mkdir "css") {
        die "Unable to create Directory \"css\"\n";
    }
    unless (-e "songs" or mkdir "songs") {
        die "Unable to create Directory \"songs\"\n";
    }
    
    if (! -f "css/audioPlayer.js") {
        open my $fh, ">", "css/audioPlayer.js";
        print {$fh} $audio_player;
        close $fh;
    }

    if (! -f "css/style.css") {
        open my $fh, ">", "css/style.css";
        print {$fh} $style;
        close $fh;
    }
}

sub create_mp3 {
    my ($song) = @_;
    unless (-e "songs/$song->{safe_filename}.mp3") {
        system('flac', '-d', "$music_root/$song->{uri}", '-o', 'songs/temp.wav');
        system('lame', '-V6', '--quiet', 'songs/temp.wav', '-o', "songs/$song->{safe_filename}.mp3");
        system('rm', '-f', 'songs/temp.wav');
    }
}

sub main {
    set_files();
    check_for_year();
    my @items = get_items_from_playlist();
    my @html;
    my @playlist_songs;

    push @playlist_songs, "<ol id=\"playlist\">\n<li class=\"current-song\">";

    foreach my $song (@items) {
        my $track = get_safe_filename($song);
        create_mp3($song);
        push @playlist_songs, "<li><a href='songs/${track}.mp3'>$song->{AlbumArtist} - $song->{Title}<\/a><\/li>";
    }

    push @playlist_songs, "<\/ol>";
    push @html, $html_header;
    foreach my $album (@items) {
        push @html, "# $album->{AlbumArtist} - $album->{Album}";
        push @html, "<div markdown='1' class='cover'>";
        push @html, "<div markdown='1' class='info-wrapper'>";
        push @html, "<img src='images/$album->{safe_filename}.jpg' alt='$album->{AlbumArtist}'>";
        push @html, "<div markdown='1' class='release-details'><dl>";
        push @html, $album->{info};
        push @html, "<\/dl><\/div><\/div>";
        push @html, "<div markdown='1' class='tracklist'>";
        push @html, "<ul style='list-style-type:none'>";
        push @html, "$album->{tracklist_md}";
        push @html, "<\/ul><\/div><\/div><div class='cf'><\/div><div class='review'>\n";
        push @html, $album->{review};
        push @html, "<\/div><br><div class='customHr'><br><\/div>\n";
    }
    push @html, "<\/div><\/div>";
    push @html, "<div markdown='1' id='sidebar'>";
    push @html, "<h2>Playlist<\/h2>";
    push @html, "<ol id='playlist'>";
    foreach my $playlist_item (@playlist_songs) {
        push @html, $playlist_item;
    }
    push @html, $html_footer;
    my $markdown = join "\n", @html;
    my $html = markdown($markdown);
    print "$html\n";
}


main()

__DATA__

@@ html_header
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Toplist 2017</title>
<link rel="stylesheet" href="css/style.css">
</head>
<body>
<div markdown='1' id="wrap">
<div markdown='1' id="nav">
<audio src="" controls id="audioPlayer" controls controlsList="nodownload">
Sorry, your browser doesn't support html5!
</audio>
</div>
<div markdown='1' id="main">
<div markdown='1' id="albumwrap">

@@ html_footer
<script src="css/jquery-2.2.0.js"></script>
<script src="css/audioPlayer.js"></script>
<script>
// loads the audio player
audioPlayer();
</script>
</div>
</div>
</body>
</html>

@@ audioPlayer
function audioPlayer(){
    var currentSong = 0;
    $("#audioPlayer")[0].src = $("#playlist li a")[0];
    $("#playlist li a").click(function(e){
       e.preventDefault();
       $("#audioPlayer")[0].src = this;
       $("#audioPlayer")[0].play();
       $("#playlist li").removeClass("current-song");
        currentSong = $(this).parent().index();
        $(this).parent().addClass("current-song");
    });

    $("#audioPlayer")[0].addEventListener("ended", function(){
       currentSong++;
        if(currentSong == $("#playlist li a").length)
            currentSong = 0;
        $("#playlist li").removeClass("current-song");
        $("#playlist li:eq("+currentSong+")").addClass("current-song");
        $("#audioPlayer")[0].src = $("#playlist li a")[currentSong].href;
        $("#audioPlayer")[0].play();
    });
}

@@ style
@import url('https://fonts.googleapis.com/css?family=Open+Sans');

* {
	border-box: none;
	padding: 0;
	margin: 0;
}

body {
	padding: 1em;
	font-family: 'Open Sans', sans-serif;
	font-size: 14px;
}

#wrap {
	max-width: 60em;
	margin: 0 auto;
}

#nav {
	z-index: 2;
	width: 60em;
	position: fixed;
}

#nav:before {
	width: 100%;
	height: 4.5em;
	background: rgba(0,0,0,.75);
	display: block;
	position: fixed;
	top: 0;
	left: 0;
	content: '';
}

audio {
	width: 100%;
	transition: all 0.2s ease-in-out;
}

audio:hover, audio:focus, audio:active {
	transform: scale(1.05);
}

#main, #sidebar {
	margin-top: 2em;
}

#main {
	background: ;
	max-width: 36em;
	float: left;
}

a,

a:active,

a:visited {
	color: #3F51B5;
	text-decoration: none;
	transition: color 0.2s ease-in-out;
}

h1 {
	font-size: 1.5em;
	margin-bottom: 1em;
}

.cf {
	clear: both;
}

.info-wrapper {
	width: 15em;
	float: right;
}

.info-wrapper img {
	max-width: 100%;
	margin-bottom: 1em;
	border-radius: .5em;
	box-shadow: 0 5px 20px #bbb;
}

dt {
	font-weight: bold;
	float: left;
	clear:both;
}

dd {
	float: right
}

.tracklist ul li {
	margin-bottom: 1em;
}

.review {
	margin-top: 3em;
	line-height: 1.5em;
}

.review h3 {
	font-size: 1.25em;
	margin-bottom: .5em;
}

.customHr {
	margin: 3em 0;
}

#main, #sidebar {
	position: relative;
	top: 3em;
}

#sidebar, #playlist {
	width: 20em;
	height:90%;
}

#sidebar {
	float: right;
}

#playlist {
 	position: fixed;
 	margin-top: 2.5em;
	overflow: scroll;
	overflow-x: hidden;
}

h2 {
	font-size: 1em;
	margin-bottom: 1em;
	color: #999;
	position: fixed;
}



#playlist {
	list-style-type: none;
/* 	overflow: scroll;
	height: 100%; */
}

#playlist li {
	margin-bottom: 1em;
}

#playlist li a {
	color: inherit;
}

#playlist li a:hover {
	color: #3F51B5;
	font-weight: bold;
}

.current-song {
	font-weight: bold;
	font-size: 1.25em;
}
