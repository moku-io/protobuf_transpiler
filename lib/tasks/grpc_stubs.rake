namespace :grpc_stubs do
  desc 'Generate stubs for all .proto files (looking into entire LOAD_PATH)'
  task :generate, [:annotate, :keep_require, :path, :create_initializer] => :environment do |_, args|
    args.with_defaults annotate: :yes, keep_require: :no, path: 'app/stubs', create_initializer: :yes
    require_relative '../protobuf_transpiler'
    ProtobufTranspiler.generate_stubs args[:keep_require].to_sym == :yes, args[:path]
    ProtobufTranspiler.generate_initializer args[:path] unless args[:create_initializer].to_sym == :no
    ProtobufTranspiler.annotate_stubs args[:path] unless args[:annotate].to_sym == :no
  end

  desc 'Annotate generated stubs'
  task :annotate, [:path, :create_initializer] => :environment do |_, args|
    args.with_defaults path: 'app/stubs', create_initializer: :no
    require_relative '../protobuf_transpiler'
    ProtobufTranspiler.generate_initializer args[:path] unless args[:create_initializer].to_sym == :no
    ProtobufTranspiler.annotate_stubs args[:path]
  end
end



