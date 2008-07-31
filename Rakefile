require 'rubygems'
require 'hoe'
require './lib/mysql_backup'

Hoe.new('sqlup', MysqlBackup::VERSION) do |p|
  p.rubyforge_name = 'sqlup'
  p.author = 'James Moore'
  p.email = 'banshee@restphone.com'
  p.summary = "A backup tool for saving MySQL data to Amazon's S3 service"
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << ['named_arguments', '>= 0.0.5']
  p.extra_deps << ['optiflag', '>= 0.6.5']
  p.extra_deps << ['daemons', '>= 1.0.6']
  p.extra_deps << ['aws-s3', '>= 0.3.0']
  p.extra_deps << 'activerecord'
  p.remote_rdoc_dir = ''
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end
