require 'named_arguments'
require 'mysql_backup/librarian/backup'

# A backup group collection is a list of all the backup groups held by 
# a MysqlBackup::Storage object.
#
# Backup group collections::  A collection of backup groups.  Usually contains all of the backup groups in an S3 bucket.
# Backup group::  A collection of identifiers for S3 buckets.  These identifiers point to a a single backup.
module MysqlBackup; end
class MysqlBackup::Librarian; end

class MysqlBackup::Librarian::BackupCollection
  include NamedArguments
  
  attr_accessor :groups
  attribute_defaults :groups => []
  
  def add_backup_group g
    groups << g
  end
  
  def add_identifier identifier
    result = nil
    result = groups.find do |g|
      g.add_identifier_to_group_if_the_identifier_should_be_in_this_group identifier
    end
    unless result
      result = MysqlBackup::Librarian::Backup.create_object :identifier => identifier
      groups << result
    end
    result
  end
  
  def groups_matching_type t
    each_group t    
  end
  
  def each_log
    each_group MysqlBackup::Librarian::Backup::Log do |g|
      yield g
    end
  end
  
  def each_group matching_type = Object
    result = []
    groups.select {|g| matching_type === g}.each do |gg|
      yield gg if block_given?
      result << gg
    end
    result
  end
  
  def find_group group_name
    each_group do |g|
      return g if group_name == g.to_s
    end
    nil
  end
  
  def types
    groups.map(&:class).uniq
  end
end