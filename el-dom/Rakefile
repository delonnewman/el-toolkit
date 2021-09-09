require "bundler/gem_tasks"

task :default => :spec

desc "Run spec"
task :spec do
  sh "bundle exec rspec"
end

desc "Build documentation"
file :doc do
  sh "bundle exec yardoc"
end

desc "Remove generated files"
task :clean do
  sh "rm -rf doc"
end
