namespace :grpc_stubs do
  desc 'Generate stubs for all .proto files (looking into entire LOAD_PATH)'
  task :generate, [:annotate, :keep_require] do |_, args|
    args.with_defaults annotate: :yes, keep_require: :no
    require_relative '../protobuf_transpiler'
    ProtobufTranspiler.generate_stubs args[:keep_require].to_sym == :yes
    ProtobufTranspiler.annotate_stubs unless args[:annotate].to_sym == :no
  end

  desc 'Annotate generated stubs'
  task :annotate do
    require_relative '../protobuf_transpiler'
    ProtobufTranspiler.annotate_stubs
  end
end



