require 'rubygems'
require File.dirname(__FILE__) + '/../test_helper'
require 'mysql_backup/entity/identifier'

class MysqlBackup::Entity::IdentifierTest < Test::Unit::TestCase
  def test_initialize
    n = MysqlBackup::Entity::Identifier.create_object :category => :full, :type => :mysqldump
    assert_kind_of MysqlBackup::Entity::Identifier, n
    assert_equal "full:type_mysqldump:log_file_:log_position_0000000000:n_parts_0000000000:part_number_0000000000", n.to_s
  end
  
  def test_object_creation
    n = MysqlBackup::Entity::Identifier.create_object :category => :full, :type => :binary
    assert_kind_of MysqlBackup::Entity::Identifier::Full::Binary, n
  end
  
  def test_create_object_with_string
    # Current files
    s = 'log:type_current:log_file_thelog.0000000006:log_position_0000000311:n_parts_0000000001:part_number_0000000000'
    n = MysqlBackup::Entity::Identifier.create_object :string => s
    assert_equal 'log:type_current:log_file_thelog.0000000006:log_position_0000000311', n.to_s
    assert_kind_of MysqlBackup::Entity::Identifier::Log::Current, n
    assert_no_match(/n_parts/, n.to_s)
    
    # Complete files
    s = 'log:type_complete:log_file_thelog.0000000006'
    n = MysqlBackup::Entity::Identifier.create_object :string => s
    assert_equal s, n.to_s
    assert_kind_of MysqlBackup::Entity::Identifier::Log::Complete, n
  end
  
  def test_class_string_to_args
    a = MysqlBackup::Entity::Identifier.string_to_args('log:type_complete:log_file_thelog.000001')
    assert_equal :log, a[:category]
    assert_equal :complete, a[:type]
    assert_equal 'thelog.000001', a[:log_file]

    a = MysqlBackup::Entity::Identifier.string_to_args('log:type_current:log_file_thelog.0000000006:log_position_0000000311:n_parts_0000000001:part_number_0000000000')
    assert_equal 311, a[:log_position]
    assert_equal 0, a[:part_number]

    # log:type_current:log_file_thelog.0000000006:log_position_0000000311:n_parts_0000000001:part_number_0000000000
    # full:type_mysqldump:log_file_thelog.0000000006:log_position_0000000382:n_parts_0000000001:part_number_0000000000
    # full:type_binary:log_file_thelog.0000000006:log_position_0000000311:n_parts_0000000001:part_number_0000000000
  end
  
  def test_log_file_number
    t = MysqlBackup::Entity::Identifier.new :log_file => 'testing.003'
    assert_equal 3, t.log_file_number
  end
end
