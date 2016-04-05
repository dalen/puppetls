# encoding: utf-8

require 'puppet/face'
require 'puppet/resource/catalog'
require 'puppet/util/colors'

Puppet::Face.define(:ls, '1.0.0') do
  extend Puppet::Util::Colors

  license 'Apache-2.0'
  copyright 'Erik Dalén', 2016
  author 'Erik Dalén <erik.gustav.dalen@gmail.com>'

  summary 'List files managed by Puppet'
  action :list do
    default
    summary 'List files and directories'
    description <<-'EOT'
      Reads and lists file resources from the catalog.
      The source of the catalog can be managed with the `--catalog_terminus` and
      the `--catalog_cache_terminus` option.
    EOT
    notes <<-'EOT'
      To be able to specify the -r option without a path you need to specify the
      subcommand as well: `puppet ls list -r`
    EOT
    returns <<-'EOT'
      Nothing.
    EOT
    arguments '[<path>]'
    option '--recursive', '-r' do
      summary 'Recursively list files and directories'
    end
    option '--quiet', '-q' do
      summary 'Limits output to just the path of the managed resource'
    end
    when_invoked do |*args|
      options = args.pop
      if args.empty?
        path = Dir.pwd
      else
        path = File.expand_path args.pop
      end
      path = path[0..-2] if path.end_with? File::SEPARATOR
      catalog = Puppet::Resource::Catalog.indirection.find(Puppet[:certname])

      catalog.filter { |r| r.type != 'File' }.resources.sort do |x,y|
        (x[:path] || x.title) <=> (y[:path] || y.title)
      end.each do |file|
        filepath = (file[:path] || file.title)
        next unless filepath.start_with? path
        rel_path = filepath[path.length + 1 .. - 1]
        next if rel_path.split(File::SEPARATOR).length > 1 && !options[:recursive]

        description = nil
        case file[:ensure]
        when 'directory'
          color = :blue
          description = "content from #{file[:source]}" unless file[:source].nil?
        when 'link'
          color = :cyan
          description = "link target: #{file[:target]}"
        when 'absent'
          color = :red
          description = 'GETS REMOVED'
        else
          color = :reset
          source = file[:source]
          source = 'a "content" parameter' if file[:content]
          description = "content from #{source}" unless source.nil?
        end

        puts colorize(color, rel_path)
        unless options[:quiet]
          puts "  #{file.file}:#{file.line}\n"
          puts "  #{file[:owner]||'undef'}:#{file[:group]||'undef'} #{file[:mode]}"
          puts "  #{description}" if description
        end
      end
    nil
    end
  end
end
