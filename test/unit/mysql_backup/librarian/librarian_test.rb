require File.dirname(__FILE__) + '/../../test_helper'
require 'mysql_backup/entity/mysqldump'
require 'mysql_backup/librarian'

class MysqlBackup::LibrarianTest < Test::Unit::TestCase
  def test_backup_data_files
    s3mock = mock('fakestorage')
    s3mock.expects(:conditional_save).at_least_once.with do |args|
      i = args[:identifier]
      i.log_file == 'foo.0001' && i.log_position == 10 && i.n_parts == 1 && i.part_number == 1
    end
    m = stubbed_librarian
    m.storage = s3mock
    MysqlBackup::Entity::Files.expects(:tar_files).at_least_once.returns([Pathname.new('/tmp/foo.0001')])
    m.backup_data_files
  end
  
  def test_backup_mysqldump
    s3mock = mock
    s3mock.expects(:conditional_save).with do |i|
      i = i[:identifier]
      assert_equal :full, i.category 
      assert_equal :mysqldump, i.type
      assert_match(/full/, i.to_s)
      i.log_file == 'foo.0001' && i.log_position == 10 && i.n_parts == 1 && i.part_number == 0
    end
    m = stubbed_librarian
    m.expects(:storage).returns(s3mock)
    dump = MysqlBackup::Entity::Mysqldump.new
    dump.log_position = 10
    dump.log_file = 'foo.0001'
    dump.expects(:system).returns(true)
    dump.expects(:get_log_position).returns(true)
    dump.expects(:compress_and_split).returns([Pathname.new('/tmp/a01')])
    MysqlBackup::Entity::Mysqldump.expects(:new).returns(dump)
    m.backup_mysqldump
  end
  
  def test_backup_binary_logs
    s3mock = mock
    s3mock.expects(:conditional_save).with do |args|
      i = args[:identifier]
      result = i.log_file == 'foo.0001' && i.log_position == 10 && i.n_parts == 1 && i.part_number == 0
      result &&= i.type == :current || i.type == :complete
    end
    m = stubbed_librarian
    m.expects(:storage).returns(s3mock)
    m.backup_binary_logs
  end
  
  def test_create_backup_group_collection_from_storage
    librarian = stubbed_librarian_with_files
    c = librarian.create_backup_group_collection_from_storage
  end
  
  def test_ls
    l = stubbed_librarian_with_files
    results = l.ls
    assert l.ls.grep(%r(log:type_current:log_file_thelog.0000000006:log_position_0000000311))
    assert l.ls.grep(%r(full:type_mysqldump:log_file_thelog.0000000006:log_position_0000000382))
    assert l.ls.grep(%r(full:type_binary:log_file_thelog.0000000006:log_position_0000000911))
  end
  
  def test_get
    l = stubbed_librarian
    stubbed_file = stub("a_temp_file", :path => 'a_temp_file')
    l.storage.expects(:retrieve_backup_and_then_yield_file).yields stubbed_file
    l.expects(:find_group).returns 0
    l.expects(:system).with {|v| v =~ /zcat.*a_temp_file/}
    Tempfile.open 'testing' do |f|
      p = Pathname.new f.to_s
      l.get_full_binary 'full:type_binary:log_file_thelog.0000000006:log_position_0000000911', p.dirname
    end
  end
  
  def stubbed_librarian
    connection_stub = stub_everything('connection stub')
    MysqlBackup::Librarian.any_instance.stubs(:create_connection).returns(connection_stub)
    m = MysqlBackup::Librarian.new :bucket => 'foo', :access_key_id => 'key', :secret_access_key => 'secret_key'
    m.mysql_server.stubs(:show_master_status).returns(:file => 'foo.0001', :position => 10)
    m.mysql_server.stubs(:datadir).returns('/tmp')
    m.mysql_server.stubs(:innodb_data_home_dir).returns('/tmp')
    m.mysql_server.stubs(:innodb_data_file_path).returns('/tmp')
    m
  end
  
  def stubbed_librarian_with_files
    strings = %w(log:type_current:log_file_thelog.0000000006:log_position_0000000311:n_parts_0000000001:part_number_0000000000
    full:type_mysqldump:log_file_thelog.0000000006:log_position_0000000382:n_parts_0000000001:part_number_0000000000
    full:type_binary:log_file_thelog.0000000006:log_position_0000000911:n_parts_0000000001:part_number_0000000000)
    identifiers = strings.map do |str|
      MysqlBackup::Entity::Identifier.create_object :string => str
    end
    librarian = stubbed_librarian  
    storage = mock('storage')
    storage.expects(:yield_identifiers).multiple_yields(*identifiers)
    librarian.storage = storage
    librarian
  end
end

# Number of errors detected: 34
