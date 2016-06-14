
desc "Run tests"
task :default => [:test]

desc "Run tests"
task :test do
  sh 'bundle exec rspec --color --format documentation spec'
end
task :spec => :test
