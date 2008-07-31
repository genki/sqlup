require File.dirname(__FILE__) + '/../test_helper'
require 'mysql_backup/librarian/backup'

module MysqlBackup
  class Librarian::BackupTest < Test::Unit::TestCase
    def test_identifiers
    end
    
    def test_most_recent_eh
    end
    
    def test_write_files
    end
    
    def test_write_raw_files
    end
    
    def test_object_creation
      i = Entity::Identifier.create_object :category => :full, :type => :binary
      b = Librarian::Backup.create_object :identifier => i
      assert_kind_of Librarian::Backup::Full::Binary, b
      assert b.is_part_of_this_group?(i)
    end
  end
end