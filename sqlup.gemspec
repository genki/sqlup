Gem::Specification.new do |s|
  s.name = %q{sqlup}
  s.version = "0.0.13.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["James Moore"]
  s.date = %q{2008-07-31}
  s.description = %q{sqlup is a set of libraries and utilities to automate backups of a MySQL server running on Amazon's EC2 service to Amazon's S3 storage service.}
  s.email = %q{banshee@restphone.com}
  s.executables = ["sqlup", "sqlup_control"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/sqlup", "bin/sqlup_control", "config/environment.rb", "lib/mysql_backup.rb", "lib/mysql_backup/entity.rb", "lib/mysql_backup/entity/files.rb", "lib/mysql_backup/entity/files/innodb.rb", "lib/mysql_backup/entity/files/myisam.rb", "lib/mysql_backup/entity/identifier.rb", "lib/mysql_backup/entity/logs.rb", "lib/mysql_backup/entity/mysqldump.rb", "lib/mysql_backup/librarian.rb", "lib/mysql_backup/librarian/backup.rb", "lib/mysql_backup/librarian/backup_collection.rb", "lib/mysql_backup/server.rb", "lib/mysql_backup/storage.rb", "lib/mysql_backup/storage/s3.rb", "lib/mysql_backup/utilities/factory_create_method.rb", "lib/sqlup.rb", "test/unit/mysql_backup/entity/files/files_test.rb", "test/unit/mysql_backup/entity/files/innodb_test.rb", "test/unit/mysql_backup/entity/files/myisam_test.rb", "test/unit/mysql_backup/entity/identifier_test.rb", "test/unit/mysql_backup/entity/logs_test.rb", "test/unit/mysql_backup/entity/mysqldump_test.rb", "test/unit/mysql_backup/librarian/backup_collection_test.rb", "test/unit/mysql_backup/librarian/backup_test.rb", "test/unit/mysql_backup/librarian/librarian_test.rb", "test/unit/mysql_backup/server_test.rb", "test/unit/mysql_backup/storage/s3_test.rb", "test/unit/mysql_backup/storage/test_helper.rb", "test/unit/mysql_backup/test_helper.rb", "test/unit/mysql_backup/utilities/test_helper.rb", "test/unit/test_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{sqlup is a set of libraries and utilities to automate backups of a MySQL server running on Amazon's EC2}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{sqlup}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{A backup tool for saving MySQL data to Amazon's S3 service}
  s.test_files = ["test/unit/mysql_backup/storage/test_helper.rb", "test/unit/mysql_backup/test_helper.rb", "test/unit/mysql_backup/utilities/test_helper.rb", "test/unit/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<named_arguments>, [">= 0.0.5"])
      s.add_runtime_dependency(%q<optiflag>, [">= 0.6.5"])
      s.add_runtime_dependency(%q<daemons>, [">= 1.0.6"])
      s.add_runtime_dependency(%q<aws-s3>, [">= 0.3.0"])
      s.add_runtime_dependency(%q<activerecord>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 1.7.0"])
    else
      s.add_dependency(%q<named_arguments>, [">= 0.0.5"])
      s.add_dependency(%q<optiflag>, [">= 0.6.5"])
      s.add_dependency(%q<daemons>, [">= 1.0.6"])
      s.add_dependency(%q<aws-s3>, [">= 0.3.0"])
      s.add_dependency(%q<activerecord>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 1.7.0"])
    end
  else
    s.add_dependency(%q<named_arguments>, [">= 0.0.5"])
    s.add_dependency(%q<optiflag>, [">= 0.6.5"])
    s.add_dependency(%q<daemons>, [">= 1.0.6"])
    s.add_dependency(%q<aws-s3>, [">= 0.3.0"])
    s.add_dependency(%q<activerecord>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 1.7.0"])
  end
end
