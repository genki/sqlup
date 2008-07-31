require File.dirname(__FILE__) + '/../../test_helper'
require 'mysql_backup/librarian/backup_collection'

module MysqlBackup
  class Librarian::BackupCollectionTest < Test::Unit::TestCase
    def test_add_backup_group
      i = Entity::Identifier.create_object :category => :full, :type => :binary
      c = Librarian::BackupCollection.new
      g = Librarian::Backup.create_object :identifier => i
      c.add_backup_group g
      assert_equal [g], c.groups
    end
    
    def test_add_identifier
      i = Entity::Identifier.create_object :category => :full, :type => :binary
      c = Librarian::BackupCollection.new
      g = Librarian::Backup.create_object :identifier => i
      c.add_identifier i
      assert_equal 1, c.groups.length
      assert_kind_of MysqlBackup::Entity::Identifier::Full, c.groups.first.identifiers.first
    end
    
    def test_find_group
      c = standard_collection
      backup_name = 'log:type_current:log_file_thelog.0000000006:log_position_0000000311'
      g = c.find_group backup_name
      assert_kind_of Librarian::Backup, g
      assert_equal g.to_s, backup_name
    end
    
    def test_groupsf
      strings = %w(log:type_complete:log_file_thelog.0000000006:log_position_0000000311)
      c = Librarian::BackupCollection.new
      strings.map do |str|
        i = MysqlBackup::Entity::Identifier.create_object :string => str
        c.add_identifier i
      end
    end
    
    def standard_collection
      strings = %w(log:type_current:log_file_thelog.0000000006:log_position_0000000311:n_parts_0000000001:part_number_0000000000
    full:type_mysqldump:log_file_thelog.0000000006:log_position_0000000382:n_parts_0000000001:part_number_0000000000
    full:type_binary:log_file_thelog.0000000006:log_position_0000000911:n_parts_0000000001:part_number_0000000000)
      c = Librarian::BackupCollection.new
      strings.map do |str|
        i = MysqlBackup::Entity::Identifier.create_object :string => str
        c.add_identifier i
      end
      c
    end
  end
end