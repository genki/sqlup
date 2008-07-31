require File.dirname(__FILE__) + '/../../test_helper'
require 'mysql_backup/entity/logs'

class MysqlBackup::Entity::LogsTest < Test::Unit::TestCase
  def test_save
    l = MysqlBackup::Entity::Logs.new :log_file => 'foo.0001', :log_position => 3, :completed_logs => ['foo.0001'], :log_bin_dir => '/tmp'
    expects(:must_call).times(2)
    l.save do |i|
      must_call
      assert_equal 'foo.0001', i[:identifier].log_file
    end
  end
end