require 'rubygems'
require 'named_arguments'
require 'mysql_backup/entity/identifier'

module MysqlBackup; end
class MysqlBackup::Librarian; end

# A backup is a complete set of identifiers for each run of backup type (full or log).
# Each backup has multiple identifiers because a single backup can have multiple files.
# The mysql binary logs are tarred up and then split into smaller parts to fit on S3.
# The same for mysqldump files; they can be greater than the size you can store in one 
# S3 bucket.
class MysqlBackup::Librarian::Backup
  include Comparable
  include FactoryCreateMethod
  include NamedArguments
  
  # Returns an array of MysqlBackup::Entity::Identifier objects
  # that are the members of this group
  attr_accessor :identifiers
  attribute_defaults :identifiers => []
  
  create_class_settings_method :identifier_class
  
  def initialize args = {}
    super
    args[:identifier] or raise RuntimeError, "Must provide :identifier"
    identifiers << args[:identifier]
  end
  
  # True if this backup is the most recent of its type
  def most_recent?
  end
  
  
  # Write the files for this backup, untarring and unzipping
  # as required.
  def write_files directory
  end
  
  # Write the files for this backup without untarring and unzipping.
  def write_raw_files directory
  end
  
  # Returns true if the identifier was added to this group
  def add_identifier_to_group_if_the_identifier_should_be_in_this_group identifier
    is_part = is_part_of_this_group? identifier
    identifiers << identifier if is_part
    is_part
  end
  
  def is_part_of_this_group? identifier
    return false unless identifier_class?.first === identifier
    log_file == identifier.log_file && log_position == identifier.log_position
  end
  
  def log_file
    identifiers.first.log_file
  end
  
  def log_position
    identifiers.first.log_position
  end
  
  def each_identifier 
    identifiers.each {|i| yield i}  
  end
  
  def <=> rhs
    identifiers.first.log_file_number <=> rhs.log_file_number || identifiers.first.log_position <=> rhs.log_position
  end
  
  # The id string for a backup doesn't include the number of parts and the
  # part itself.  
  #
  # (Split on :, ignore the last two elements)
  def to_s
    identifiers.first.to_s.split(':').slice(0..-3).join(':')
  end
  
  def name_match rhs
    to_s == rhs
  end
  
  def self.new_if_class_match klass
    new_if_class klass, :identifier
  end
end

module MysqlBackup
  class Librarian::Backup::Full < Librarian::Backup
  end
  
  class Librarian::Backup::Full::Binary < Librarian::Backup::Full
    new_if_class_match Entity::Identifier::Full::Binary
    identifier_class Entity::Identifier::Full::Binary
  end
  
  class Librarian::Backup::Full::Mysqldump < Librarian::Backup::Full
    new_if_class_match Entity::Identifier::Full::Mysqldump
    identifier_class Entity::Identifier::Full::Mysqldump
  end
  
  class Librarian::Backup::Log < Librarian::Backup
    def to_s
      identifiers.first.to_s
    end
  end
  
  class Librarian::Backup::Log::Current < Librarian::Backup::Log
    new_if_class_match Entity::Identifier::Log::Current
    identifier_class Entity::Identifier::Log::Current
  end
  
  class Librarian::Backup::Log::Complete < Librarian::Backup::Log
    new_if_class_match Entity::Identifier::Log::Complete
    identifier_class Entity::Identifier::Log::Complete
    
    def is_part_of_this_group? identifier
      return false unless identifier_class?.first === identifier
      log_file == identifier.log_file
    end
    
    def log_position
      0
    end
  end
end
