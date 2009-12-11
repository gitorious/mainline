namespace :test do
  desc "Generate code coverage with rcov"
  task :rcov do
    rm_f "coverage/coverage.data"
    rm_rf "coverage"
    mkdir "coverage"
    rcov = %(rcov --rails --exclude '.gems/*,lib/tasks/*' --aggregate coverage/coverage.data --text-summary --html -o coverage -I"lib:test" test/**/*_test.rb)
    system rcov
  end
end
