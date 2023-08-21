# Protobuf Transpiler

A protobuf transpiler and annotator for Rails applications.

This gem provides a quick way to generate annotated ruby stubs for protobufs leveraging [Ruby gRPC Tools](https://github.com/grpc/grpc/tree/master/src/ruby/tools#ruby-grpc-tools), adopting an opinionated Rails oriented approach.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'protobuf_transpiler', '~> 1.0'
```

And then execute:

```bash
bundle
```


## Usage

This gem provides two rake tasks, `grpc_stubs:generate` and `grpc_stubs:annotate`. `generate` transpiles all `.proto` files nested in a `public` folder looking in the `$LOAD_PATH`, putting the generated ruby stubs in `app/stubs`, respecting the inner nesting. `annotate` annotates all the generated stubs with a comment section leveraging reflection.

Beware that at the moment this gem does not support nested messages definition.

### Generate
To generate the stubs simply run:
```bash
rake grpc_stubs:generate
```
The task accepts two optional positional arguments, `annotate` and `keep_require` which default respectively to `'yes'` and `'no'`.
This means that by default the `generate` task also runs the `annotate` one, and the behavior can be changed by specifying the first argument as `'no'`. Furthermore the default behavior of `generate` removes all the `require ...` generated by `grpc_tools_ruby_protoc`; if, for any reason, you may want to keep them, you need to specify the second argument as `'yes'` (which implies you need to explicitly state the first parameter, even if you want to keep the default behavior).
Finally, following the stubs generation, the task also creates a ruby file for all the proto packages, which corresponds to the created folders in `app/stubs`, containing `require_relative` instructions to the corresponding stubs. This allows `zeitwerk` to work properly despite `grpc_tools_ruby_protoc` not respecting the naming conventions.

For example if you have a gem defining proto files with this structure:
```
 public
 ├── mod1
 │   └── sample1.proto
 ├── mod2
 │   └── sample2.proto
```
you will get the following structure nested in `app/stubs`:
```
app/stubs
├── mod1
│   ├── sample1_pb.rb
│   └── sample1_services_pb.rb
├── mod1.rb
├── mod2
│   ├── sample2_pb.rb
│   └── sample2_services_pb.rb
├── mod2.rb

```

### Annotate
To annotate generated stubs simply run:
```bash
rake grpc_stubs:annotate
```
As stated in [generate](#generate) this task is executed automatically unless you opt out after the generation step. Leveraging reflection, Messages and Services are inspected and a comment summary is prepended in the corresponding stub file.

The annotations of messages follow these conventions:
- each message is reported with its fully qualified name
- fields are indented in the lines following the message name and are reported as `name: type`
- `repeated` fields are annotated with their type enclosed in brackets (`[type]`)
- `map` fields are annotated with angular brackets: `Map<key_type, value_type>`
- `oneof` fields are annotated with their wrapper name, then each possible variant placed on a new line, further indented and prepended with `| `.

Here's an example of annotations of some messages:
```
# ===== Protobuf Annotation =====
# Test::GetJobReq
# 	id: uint64
#   some_oneof_wrapper:
# 	  | alternative: string
# 	  | another: uint64
# Test::GetJobResp
# 	id: uint64
# 	name: string
# 	surname: string
#   notes: [string]
# ===== Protobuf Annotation =====
```
and some rpcs:
```
# ===== Protobuf Annotation =====
# Test::Jobs
# 	GetJob(Test::GetJobReq): Test::GetJobResp
# Test::Another
# 	GetNew(Test::GetJobReq): Test::GetJobResp
# ===== Protobuf Annotation =====
```


## Future extensions
- Support nested messages definition

## Version numbers

Protobuf Transpiler loosely follows [Semantic Versioning](https://semver.org/), with a hard guarantee that breaking changes to the public API will always coincide with an increase to the `MAJOR` number.

Version numbers are in three parts: `MAJOR.MINOR.PATCH`.

- Breaking changes to the public API increment the `MAJOR`. There may also be changes that would otherwise increase the `MINOR` or the `PATCH`.
- Additions, deprecations, and "big" non breaking changes to the public API increment the `MINOR`. There may also be changes that would otherwise increase the `PATCH`.
- Bug fixes and "small" non breaking changes to the public API increment the `PATCH`.

Notice that any feature deprecated by a minor release can be expected to be removed by the next major release.

## Changelog

Full list of changes in [CHANGELOG.md](CHANGELOG.md)


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/moku-io/protobuf_transpiler.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
