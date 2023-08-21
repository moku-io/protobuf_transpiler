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
      out_path    = "#{Rails.root}/app/stubs/"
      FileUtils.mkdir_p out_path
      `grpc_tools_ruby_protoc --ruby_out=#{out_path} --grpc_out=#{out_path} #{proto_files} -I #{proto_paths}`

      # remove possibly useless require from stub file
      unless keep_require
        Dir['app/stubs/**/*.rb'].each do |fp|
          f = File.read fp
          File.write fp, (f.sub %r{\n(require.*?'\n)+}, '')
        end
      end

      # make zeitwerk happy
      Dir['app/stubs/**']
        .filter { |f| File.directory? f }
        .each { |dir|
          requires = Dir.chdir dir do
            curr_dir = Dir.pwd.split('/').last
            Dir['*.rb'].map { |s| "require_relative './#{curr_dir}/#{s.sub %r{.rb$}, ''}'" }
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
                                      .sort
                                      .map { |c| m.const_get c }
                                      .each_with_object({ messages: [], services: [] }) { |c, acc|
                                        if c.is_a? Class
                                          acc[:messages] << class_annotations(c)
                                        else
                                          acc[:services] << module_annotations(c)
                                        end
                                      }
        types_file, services_file = Dir["app/stubs/#{m.name.underscore}/*.rb"]
                                      .sort_by { |s| s.scan('services').count }
        [types_file, services_file]
          .zip([out[:messages], out[:services]])
          .each { |file, content| annotate_file file, content }
      end
    end

    private

    ANNOTATE_DELIMITER = '# ===== Protobuf Annotation ====='

    def class_annotations klass
      oneof_fields, oneof_annotations = lambda do |descriptor|
        [
          descriptor.each_oneof
                    .flat_map { |o| o.entries.map(&:name) },
          descriptor.each_oneof
                    .map { |o| ["#{o.name}:", o.entries.map { |e| "\t| #{e.name}: #{type_handler e}" }].join("\n") }
                    .map { |s| s.gsub(%r{\t}, "\t\t").prepend("\t") + "\n" }
        ]
      end.call(klass.descriptor)

      map_fields = lambda do |descriptor, instance|
        descriptor.entries
                  .map(&:name)
                  .filter { |n| instance[n].class == Google::Protobuf::Map }
      end.call(klass.descriptor, klass.new)

      [
        klass.name.to_s,
        klass.constants(false).sort
             .map { |msg| klass.const_get msg }
             .map { |msg_class| class_annotations(msg_class) }
             .map { |s| s.gsub(%r{\t}, "\t\t").prepend("\t") }
             .prepend("\n"),
        oneof_annotations,
        klass.descriptor.entries
             .reject{|d|oneof_fields.include? d.name}
             .map { |d|
               "\t#{d.name}: "+
               type_handler(d, map_fields)
             }
             .join("\n"),
        "\n"

      ].join('')
    end

    def type_handler d, map_fields = []
        case
        when d.is_a?(Symbol)
          d
        when map_fields.include?(d.name)
          d.subtype.entries.then { |k,v| "Map<#{k.type}, #{type_handler(v)}>" }
        when d.type == :message
          d.subtype.msgclass.then{|t| d.label == :repeated ? "[#{t}]" : t}
        else
          d.type.then{|t| d.label == :repeated ? "[#{t}]" : t}
        end.to_s
    end

    def module_annotations mod
      mod
        .const_get('Service')
        .rpc_descs.sort
        .map { |_, d| "\t#{d.name}(#{d.input}): #{d.output}" }
        .prepend(mod.name.to_s)
        .join "\n"
    end

    def annotate_file file, content
      old_content = File.read file
      content     = content.join("\n").gsub(%r{^}, '# ')
      new_content = if old_content.match? ANNOTATE_DELIMITER
                      # replace annotation content
                      old_content.sub %r{(?<=#{ANNOTATE_DELIMITER}\n)(.|\n)*?(?=\n#{ANNOTATE_DELIMITER})}, "\n#{content}"
                    else
                      # find first spot after comments
                      # add and fill annotation
                      old_content.sub %r{^[^#]}, "\n#{ANNOTATE_DELIMITER}\n\n#{content}\n#{ANNOTATE_DELIMITER}\n\n"
                    end
      File.write file, new_content
    end
  end
end

class GRPC::RpcDesc::Stream

  def to_s
    "stream #{type}"
  end
end

monkey_patch_descriptor = Module.new do
  def each_oneof(&)
    return super if block_given?

    Enumerator.new do |y|
      super do |d|
        y << d
      end
    end
  end
end
Google::Protobuf::Descriptor.prepend monkey_patch_descriptor
