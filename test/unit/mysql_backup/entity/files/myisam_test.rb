require File.dirname(__FILE__) + '/../../test_helper'
require 'mysql_backup/entity/files/myisam'

class MysqlBackup::Entity::Files::MyisamTest < Test::Unit::TestCase
  def test_required_paths
    paths = std_myisam.required_paths
    assert_equal ["/tmp/mock_myisam_database"].sort, (paths.map {|px| px.cleanpath.to_s}).sort
  end
  
  def test_myisam_database_dirs
    s = std_myisam
    assert_equal s.datadir, '/tmp'
    result = s.myisam_database_dirs
    assert_equal [Pathname.new('/tmp/mock_myisam_database')], result
  end
  
  protected
  
  def std_myisam
    MysqlBackup::Entity::Files::Myisam.new :datadir => @basedir
  end
  
  def setup
    @basedir = '/tmp'
    @basepath = Pathname.new @basedir
    p = @basepath + 'mock_myisam_database'
    p.mkdir
    q = p + 'foo.MYD'
    q.open 'w' do |qf|
      qf << 'testing'
    end
  end
  
  def teardown
    p = @basepath + 'mock_myisam_database'
    Pathname.glob(p + '*').each do |f|
      f.unlink
    end
    p.rmdir
    Pathname.glob(@basepath + 'fakeinnodb*').each {|pr| pr.delete}
  end
end
