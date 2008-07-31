require File.dirname(__FILE__) + '/../test_helper'
require 'mysql_backup/server'

class MysqlBackup::ServerTest < Test::Unit::TestCase
  def test_connection
  end
  
  def test_current_log_has_entries_eh
    r = [{"Position"=>"98",
  "Binlog_Do_DB"=>"",
  "Binlog_Ignore_DB"=>"",
  "File"=>"James-PC-bin.000002"}]
    @repl.expects(:query_to_array).returns r
    
    assert ! @repl.current_log_has_entries?
    
    r = [{"Position"=>"98",
  "Binlog_Do_DB"=>"",
  "Binlog_Ignore_DB"=>"",
  "File"=>"James-PC-bin.000002"}]
    @repl.expects(:query_to_array).returns r
    
    assert ! @repl.current_log_has_entries?
  end
  
  def test_completed_logs
    @repl.expects(:query_to_list).returns(["James-PC-bin.000001", "James-PC-bin.000002"]) 
    assert_equal ["James-PC-bin.000001"], @repl.completed_logs
  end
  
  def test_flush_logs_bang
    @repl.expects(:query_to_array).with('flush logs')
    @repl.flush_logs!
  end
  
  def test_query_to_array
  end
  
  def test_show_master_status
    r = [{"Position"=>"98",
  "Binlog_Do_DB"=>"",
  "Binlog_Ignore_DB"=>"",
  "File"=>"James-PC-bin.000002"}]
    @repl.expects(:query_to_array).returns r
    s = @repl.show_master_status
    
    expected = {:position=>98,
      :binlog_do_db=>"",
      :file=>"James-PC-bin.000002",
      :binlog_ignore_db=>""}
    assert_equal expected, s
  end
  
  def test_innodb_data_file_path
    x = 'ibdatad1:10M:autoextend'
    @repl.expects(:show_variables).returns({:innodb_data_file_path => x})
    assert_equal 'ibdatad', @repl.innodb_data_file_path
  end
  
  def setup
    @repl = MysqlBackup::Server.new :host => 'localhost', :user => 'root'
  end
end