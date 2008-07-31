require File.dirname(__FILE__) + '/../../test_helper'
require 'mysql_backup/entity/files/innodb'

class MysqlBackup::Entity::Files::InnodbTest  < Test::Unit::TestCase
  def test_required_paths
    paths = std_innodb.required_paths
    assert_equal ["/tmp/fakeinnodb1", "/tmp/mock_database"].sort, (paths.map {|px| px.cleanpath.to_s}).sort
  end
  
  def test_innodb_database_dirs
    s = std_innodb
    result = s.innodb_database_dirs
    assert_equal [Pathname.new('/tmp/mock_database')], result
  end
  
  def test_innodb_files
    assert_equal [Pathname.new('/tmp/fakeinnodb1')], std_innodb.innodb_files
  end
  
  protected
  
  def std_innodb
    @innodb = MysqlBackup::Entity::Files::Innodb.new :datadir => @basedir, :innodb_data_home_dir => @basedir, :innodb_data_file_path => 'fakeinnodb'
  end
  
  def setup
    @basedir = '/tmp'
    @basepath = Pathname.new @basedir
    p = @basepath + 'mock_database'
    p.mkdir unless p.directory?
    q = p + 'foo.frm'
    q.open 'w' do |qf|
      qf << 'testing'
    end
    # Build fake innodb files
    i = @basepath + 'fakeinnodb1'
    i.open 'w' do |innofile|
      innofile << 'testing'
    end
  end
  
  def teardown
    p = @basepath + 'mock_database'
    Pathname.glob(p + '*').each do |f|
      f.unlink
    end
    p.rmdir
    Pathname.glob(@basepath + 'fakeinnodb*').each {|pr| pr.delete}
  end
end
