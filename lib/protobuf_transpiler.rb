# frozen_string_literal: true

require_relative "protobuf_transpiler/version"

module ProtobufTranspiler
  require_relative 'railtie'

  class << self
    def generate_stubs(keep_require = false)
      paths       = $LOAD_PATH.map { |p| "#{p}/**/public/**/*.proto" }
      proto_files = Dir[*paths].join ' '
      proto_paths = proto_files
                      .split.map { |p| p.sub %r{(?<=public).*}, '' }
                      .uniq.join ' '
      out_path = "#{Rails.root}/app/stubs/"
      FileUtils.mkdir_p out_path
      `grpc_tools_ruby_protoc --ruby_out=#{out_path} --grpc_out=#{out_path} #{proto_files} -I #{proto_paths}`

      # remove possibly useless require from stub file
      unless keep_require
        Dir['app/stubs/**/*.rb'].each do |fp|
          f = File.read fp
          File.write fp, (f.sub /\n(require.*?'\n)+/, '')
        end
      end

      # make zeitwerk happy
      Dir['app/stubs/**']
        .filter { |f| File.directory? f }
        .each { |dir|
          requires = Dir.chdir dir do
            curr_dir = Dir.pwd.split('/').last
            Dir['*.rb'].map { |s| "require_relative './#{curr_dir}/#{s.sub(/.rb$/, '')}'" }
          end
          File.write "#{dir}.rb", requires.join("\n")
        }
    end

    def annotate_stubs
      require 'active_support/core_ext/string/inflections'

      Dir['app/stubs/**/*.rb']
        .map { |s| File.absolute_path s }
        .each { |f| require f }

      stubs_modules = Dir['app/stubs/*.rb']
                        .map { |s| s.sub('app/stubs/', '') }
                        .map { |s| s.sub '.rb', '' }
                        .uniq
                        .map { |c| Object.const_get c.camelize }

      stubs_modules.each do |m|
        out                       = m
                                      .constants
                                      .map { |c| m.const_get c }
                                      .each_with_object({ messages: [], services: [] }) { |c, acc|
                                        if c.is_a? Class
                                          acc[:messages] << class_annotations(c)
                                        else
                                          acc[:services] << module_annotations(c)
                                        end
                                      }
        types_file, services_file = Dir["app/stubs/#{m.name.downcase}/*.rb"]
                                      .sort_by { |s| s.scan('services').count }
        [types_file, services_file]
          .zip([out[:messages], out[:services]])
          .each { |file, content| annotate_file file, content }
      end
    end

    private

    ANNOTATE_DELIMITER = '===== Protobuf Annotation ====='

    def class_annotations c
      c
        .descriptor.entries.map { |d| "\t#{d.name}: #{d.type}" }
        .prepend("#{c.name}")
        .join "\n"
    end

    def module_annotations m
      m
        .const_get('Service')
        .rpc_descs.map { |_, d| "\t#{d.name}(#{d.input}): #{d.output}" }
        .prepend("#{m.name}")
        .join "\n"
    end

    def annotate_file file, content
      old_content = File.read file
      content     = content.join("\n").gsub(%r{^}, '# ')
      new_content = if old_content.match? ANNOTATE_DELIMITER
                      # replace annotation content
                      old_content.sub %r{(?<=#{ANNOTATE_DELIMITER})(.|\n)*?(?=##{ANNOTATE_DELIMITER})}, "\n#{content}\n"
                    else
                      # find first spot after comments
                      # add and fill annotation
                      old_content.sub %r{^[^#]}, "\n# #{ANNOTATE_DELIMITER}\n#{content}\n# #{ANNOTATE_DELIMITER}\n\n"
                    end
      File.write file, new_content
    end
  end
end
