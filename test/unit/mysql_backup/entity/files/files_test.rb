require File.dirname(__FILE__) + '/../../test_helper'
require 'mysql_backup/entity/files'

class MysqlBackup::Entity::FilesTest < Test::Unit::TestCase
  def test_class_create_tar_files
    build_result = {:files => ['log.001'], :log_position => 12, :n_parts => 1, :log_file => 'log.001', :log_position => 0}
    MysqlBackup::Entity::Files.expects(:build_files).times(0..100).returns(build_result)
    expects(:must_call)
    MysqlBackup::Entity::Files.create_tar_files do |args|
      must_call
      assert_kind_of MysqlBackup::Entity::Identifier, args[:identifier]
    end
  end
  
  def test_class_build_files
    o1 = stub(:required_path_strings => ['/tmp/a'], :confirm_required_paths_are_readable => nil)
    o2 = stub(:required_path_strings => ['/tmp/b'], :confirm_required_paths_are_readable => nil)
    ms = stub('mysqlserver')
    ms.expects(:with_lock).yields(:log_file => 'snark', :log_position => 3)
     (MysqlBackup::Entity::Files.expects(:tar_files).with {|t| t == %w(/tmp/a /tmp/b)}).returns([])
    MysqlBackup::Entity::Files.build_files :mysql_server => ms, :mysql_files => [o1, o2] 
  end
  
  def test_class_do_tar
  end
  
  def test_class_tar_files
    MysqlBackup::Entity::Files.expects(:do_tar).with {|x| x[:cmd] =~ /tar.*tmp.a.*gzip.*split/}
    files = MysqlBackup::Entity::Files.tar_files ['/tmp/a']
  end
  
  def test_required_path_strings
    f = MysqlBackup::Entity::Files.new
    f.expects(:required_paths).returns([])
    f.required_path_strings
  end
  
  def test_set_path_vars
    f = MysqlBackup::Entity::Files.new
    f.expects(:foo=)
    Pathname.any_instance.expects(:readable?).returns true
    f.instance_variable_set(:@foo, '/tmp/foo')
    f.set_path_vars [:foo], :foo => '/tmp/foo'
  end
end