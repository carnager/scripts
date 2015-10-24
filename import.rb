#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'
require 'set'
require 'date'

OPTIONS = {
  replaygain: ['-g', '--[no-]gain', 'apply replaygain'],
  tag: ['-t', '--[no-]tag', 'tag files'],
  rsync: ['-r', '--[no-]rsync', 'sync files with rsync'],
  update_caches: ['-u', '--[no-]update', 'update mpd/clerk caches'],
  html: ['-h', '--[no-]html', 'create musiclist html file'],
  html_sync: ['-s', '--[no-]html-sync', 'sync musiclist']
}

@actions = Hash[OPTIONS.keys.map { |opt| [opt, nil] }]

parser = OptionParser.new do |p|
  p.banner = "Usage: #{$0} [options] [basedir]"

  OPTIONS.each do |option, args|
    p.on(*args[0..-2], "(don't) #{args.last}") do |value|
      @actions[option] = value
    end
  end

  p.on('-h', '--help', 'show this message') do
    puts(p)
    exit
  end
end

parser.parse!

unless @actions.values.any? { |value| value == true }
  @actions = Hash[OPTIONS.keys.map { |opt| [opt, @actions[opt].nil?] }]
end

@basedir = ARGV[0] || Dir.pwd

FileUtils.cd @basedir

RG_COMMANDS = {
  mp3: 'caudec -g *.mp3',
  flac: 'metaflac --add-replay-gain *.flac',
  ogg: 'vorbisgain -a *.ogg'
}

def rg_for_dir(dir)
  FileUtils.cd(dir) do
    RG_COMMANDS.each do |format, command|
      next unless Dir["*.#{format}"].any?
      system(command)
      break
    end
  end
end

def replaygain
  puts 'Applying replaygain...'

  Dir['**/'].each(&method(:rg_for_dir))
end

def tag
  puts 'starting tagger...'
  system('picard', *Dir['**/*.*'], [:out, :err] => '/dev/null')
end

def relevant_dirs(base_dir, time = Date.today.prev_day.to_time)
  result = Set.new

  matcher = %r(#{Regexp.escape(base_dir)}.*?/)
  Dir[File.join(base_dir, '**', '*')].each do |file|
    next if File.directory?(file)
    dir = file.match(matcher)
    next if dir.nil? || File.mtime(file) < time
    result << File.join(dir[0])
  end

  result
end

def rsync
  puts 'syncing new music with homeserver...'

  rips_dir = '/mnt/wasteland/Audio/Rips'
  codecs = Dir[File.join(rips_dir, '*/')]

  codecs.each do |codec_dir|
    codec = File.basename(codec_dir)
    relevant_dirs(codec_dir).each do |dir|
      remote_path = File.join('/mnt', 'raid', 'Audio', 'Rips', codec, File.basename(dir))
      system('rsync', '-avxEAXHqs', '--delete', "#{dir}/", "tauron:#{remote_path}/")
    end
  end
end

def html
  puts 'creating musiclist html file...'
  File.write('index.html', `musiclist`)
end

def html_sync
  puts 'updating online music list...'
  system('scp', '-q', 'index.html', 'proteus:/srv/http/list')
  File.delete('index.html')
end

def update_caches
  puts 'updating mpd/clerk caches...'
  system('mpc', '--wait', 'update', [:out, :err] => '/dev/null')
  spawn('clerk', '--update')
end

@actions.each do |action, should_run|
  next unless should_run
  send(action)
end
