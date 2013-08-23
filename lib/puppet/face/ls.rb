# encoding: utf-8

require 'puppet/face'

Puppet::Face.define(:ls, '0.0.1') do
  license "Apache 2"
  copyright "Erik Dalén", 2013
  author "Erik Dalén <erik.gustav.dalen@gmail.com>"
  summary "List files managed by Puppet"
  action :list do
    default
    summary "List files and directories"
    description <<-'EOT'
      Reads and lists file resources from the catalog.
      The source of the catalog can be managed with the `--terminus` option.
    EOT
    returns <<-'EOT'
      Nothing.
    EOT
    arguments "[<path>]"
    option "--recursive", "-r"
    option "--terminus"
    when_invoked do |*args|
      if args.length > 1
        path = File.expand_path args[0]
        options = args[1]
      else
        path = Dir.pwd
        options = args[0]
      end
      path = path[0..-2] if path.end_with? File::SEPARATOR
      catalog = Puppet::Face[:catalog, '0.0.1'].find(Puppet[:certname], {:terminus => options[:terminus] || :json})

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
