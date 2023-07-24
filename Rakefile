# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: :rubocop

import(*Dir[File.join(File.dirname(__FILE__), 'lib/tasks', '**/*.rake')])
