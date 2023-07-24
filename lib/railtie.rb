require 'protobuf_transpiler'
require 'rails'

module ProtobufTranspiler
  class Railtie < Rails::Railtie
    railtie_name :protobuf_transpiler

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { |f| load f }
    end
  end
end
