# A sample Guardfile
# More info at https://github.com/guard/guard#readme

require 'guard/minitest'

unless Minitest::Runner.private_instance_methods.include?(:ruby_command_without_include)
  class Minitest::Runner
    alias :ruby_command_without_include :ruby_command

    def ruby_command(paths)
      command = ruby_command_without_include(paths)
      include_folders = @options[:include]
      command[1...1] = include_folders.map{|f| %Q[-I"#{f}"] } 
      command
    end
  end
end

guard :minitest, include: %w(. app app/presenters lib test), test_folders: %w(test/micro) do
  watch(%r{^(app|lib).*\.rb}) { "test/micro" }
  watch(%r{^test/micro.*\.rb}) { "test/micro" }
  watch(%r{^test/fast_test_helper\.rb}) { "test/micro" }
end

guard :minitest, zeus: true, include: %w(. app app/presenters lib test), 
  test_folders: %w(test/unit test/functional test/integration) do
  watch(%r{^test/test_helper\.rb}) { ['test/unit', 'test/functional', 'test/integration'] }
  watch(%r{^test/.+_test\.rb})
  watch(%r{^app/controllers/(.*)\.rb}) { |m| "test/functional/#{m[1]}_test.rb" }
  watch(%r{^app/models/(.*)\.rb})      { |m| "test/unit/#{m[1]}_test.rb" }
  watch(%r{^app/use_cases/(.*)\.rb})      { |m| "test/unit/use_cases/#{m[1]}_test.rb" }
end
