Gem::Specification.new do |s|
  s.name     = "localized_templates"
  s.version  = "0.3.1"
  s.date     = "2008-12-18"
  s.summary  = "Templates localization for Rails 2.2"
  s.email    = "jose.valim@gmail.com"
  s.homepage = "http://github.com/josevalim/localized_templates"
  s.description = "Templates localization for Rails 2.2"
  s.has_rdoc = true
  s.authors  = [ "José Valim" ]
  s.files    = [
    "MIT-LICENSE",
    "README",
    "Rakefile",
    "lib/localized_templates.rb",
    "lib/localized_rescue/README",
    "lib/localized_rescue/actioncontroller/rescue.rb",
    "lib/localized_templates/README",
    "lib/localized_templates/actioncontroller/base.rb",
    "lib/localized_templates/actioncontroller/layout.rb",
    "lib/localized_templates/actionview/base.rb",
    "lib/localized_templates/actionview/partials.rb"
  ]
  s.test_files = [
    "test/localized_rescue_test.rb",
    "test/localized_templates_test.rb",
    "test/setup.rb",
    "test/fixtures/en-US.yml",
    "test/fixtures/pt-BR.yml",
    "test/fixtures/layouts/default.html.erb",
    "test/fixtures/projects/index.html.erb",
    "test/fixtures/projects/index.rss.builder",
    "test/fixtures/en-US/projects/index.rss.builder",
    "test/fixtures/pt-BR/projects/index.html.erb",
    "test/fixtures/pt-BR/layouts/default.html.erb",
    "test/fixtures/public/500.html",
    "test/fixtures/public/en-US/404.html",
    "test/fixtures/public/pt-BR/404.html"
  ]
  s.rdoc_options = ["--main", "README"]
  s.extra_rdoc_files = ["README"]
end
