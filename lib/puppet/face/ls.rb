# encoding: utf-8

require 'puppet/face'
require 'puppet/resource/catalog'

Puppet::Face.define(:ls, '1.0.0') do
  extend Puppet::Util::Colors

  license "Apache-2.0"
  copyright "Erik Dalén", 2016
  author "Erik Dalén <erik.gustav.dalen@gmail.com>"

  summary "List files managed by Puppet"
  action :list do
    default
    summary "List files and directories"
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
    arguments "[<path>]"
    option "--recursive", "-r" do
      summary 'Recursively list files and directories'
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
        rel_path = filepath[path.length + 1 .. - 1]
        if not options[:recursive]
          next if rel_path.nil?
          next if rel_path.split(File::SEPARATOR).length > 1
        end
        if filepath.start_with? path
          if file[:ensure] == 'absent'
            description = 'GETS REMOVED'
          else
            source = file[:source]
            source = 'a "content" parameter' if source.nil? or source.empty?
            description = "content from #{source}"
          end

          puts "#{rel_path}\n  declared in #{file.file}:#{file.line}\n  #{description}"
        end
      end
    nil
    end
  end
end
