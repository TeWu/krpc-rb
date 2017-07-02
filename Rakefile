
desc "Run tests"
task :default => [:test]

desc "Run tests"
task :test do
  sh 'bundle exec rspec'
end
task :spec => :test

desc "Regenerate documentation"
task :redoc do
  output_dir = 'doc'
  FileUtils.remove_dir(output_dir) if File.directory?(output_dir)
  sh %Q{rdoc -o #{output_dir} --markup markdown --format hanna --title "kRPC-rb API Docs" --main README.md README.md lib/**/*.rb}
  sh %Q{ruby -pi.bak -e "gsub('files/README_md.html', 'classes/KRPC/Client.html')" #{output_dir}/index.html && rm #{output_dir}/index.html.bak}
end
