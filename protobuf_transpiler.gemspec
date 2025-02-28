# frozen_string_literal: true

require_relative 'lib/protobuf_transpiler/version'

Gem::Specification.new do |spec|
  spec.name    = 'protobuf_transpiler'
  spec.version = ProtobufTranspiler::VERSION
  spec.authors = ['Moku S.r.l.', 'Nicolò Greggio']
  spec.email   = ['info@moku.io']

  spec.summary               = 'A protobuf transpiler and annotator for Rails applications.'
  spec.description           = 'This gem provides a quick way to generate annotated ruby stubs for protobufs leveraging Ruby gRPC Tools, adopting an opinionated Rails oriented approach.'
  spec.homepage              = 'https://github.com/moku-io/protobuf_transpiler'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/moku-io/protobuf_transpiler'
  spec.metadata['changelog_uri']   = 'https://github.com/moku-io/protobuf_transpiler/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'google-protobuf', '~> 3.23', '>= 3.23.3'
  spec.add_dependency 'grpc', '~> 1.56'
  spec.add_dependency 'grpc-tools', '~> 1.56'
  spec.add_dependency 'rails'
end
