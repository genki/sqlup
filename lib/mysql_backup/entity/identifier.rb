require 'rubygems'
require 'named_arguments'
require 'mysql_backup/utilities/factory_create_method'

module MysqlBackup; end
class MysqlBackup::Entity; end;

# There are four different kinds of things you store for MySQL backups.
# 
# - Completed logs.
# - The current log (the log file that MySQL is writing to)
# - mysqldump files (output from the mysqldump command)
# - binary files (tar | gzip | split of the files in the mysql data directory)
#
# They're stored using the following name schemes:
#
#   :log:type_complete:thelog.000005
#     A completed log file.
#
#   :log:type_current:log_file_thelog.0000000006:log_position_0000000311:n_parts_0000000001:part_number_0000000000
#     A current log file.  The position is 311 (that's where mysql will write the next statement).
#     There's only one part, and this is it.  (Part numbers start with 0.)
#     In this release, log files can only have one part - no attempt is made to split them
#     into chunks small enough to fit in S3.  Don't let your log files grow larger than 5G.
#   :full:type_mysqldump:log_file_thelog.0000000006:log_position_0000000382:n_parts_0000000001:part_number_0000000000
#     A full mysqldump file.  The current log file is thelog.0000000006, and the position in
#     that log is 382.  Since we don't flush logs, anything written after 382 might not be
#     complete.
#   :full:type_binary:log_file_thelog.0000000006:log_position_0000000311:n_parts_0000000001:part_number_0000000000
#     A full copy of the MySQL data files, created by tarring up all the data files,
#     then passing them through gzip and split to make sure they'll fit in S3 objects that
#     can only hold 5G.
class MysqlBackup::Entity::Identifier
  include NamedArguments
  include FactoryCreateMethod
  
  # category is one of
  #   :full => a full backup of the mysql files
  #   :log_current => the mysql binary log file that's being written to
  #   :log_complete => mysql binary log files that are complete
  attr_accessor :category
  
  # type depends on the category.
  # 
  # for category +full+, type is one of 
  #   :binary, :mysqldump
  attr_accessor :type
  
  # The name of the log file
  attr_accessor :log_file
  
  # The numeric position in the log file
  attr_accessor :log_position
  
  # For multipart storage units, the part number
  attr_accessor :part_number
  
  # For multipart storage units, the total number of parts
  attr_accessor :n_parts
  
  # Time the object was created
  attr_accessor :timestamp
  
  def initialize args
    super
    
    part_number ||= 0
    part_number = sprintf "%06d", part_number.to_i
    
    n_parts ||= 1
    n_parts = sprintf "%06d", n_parts.to_i
    
    throw :bad if log_file == 'foo'
  end
  
  def merge new_values_hash
    to_hash.merge new_values_hash
  end
  
  def to_hash
    result = {}
    [:category, :type, :log_file, :log_position, :n_parts, :part_number].each do |i|
      result[i] = send i
    end
    result
  end
  
  def to_s
    pos = n_digits log_position
    np = n_digits n_parts
    pn = n_digits part_number
    return "#{category}:type_#{@type}:log_file_#{log_file}:log_position_#{pos}:n_parts_#{np}:part_number_#{pn}"
  end
  
  def n_digits x
    sprintf "%010d", x
  end
  
  # Get the sequence number from the log file name.
  #
  #   mylogfile.000034 => 34
  def log_file_number
    log_file[/\.(\d+)$/, 1].to_i
  end
  
  # Examples of the four identifiers:
  #
  # log/type_complete/thelog.000001
  # log/type_current/log_file_thelog.0000000006/log_position_0000000311/n_parts_0000000001/part_number_0000000000
  # full/type_mysqldump/log_file_thelog.0000000006/log_position_0000000382/n_parts_0000000001/part_number_0000000000
  # full/type_binary/log_file_thelog.0000000006/log_position_0000000311/n_parts_0000000001/part_number_0000000000
  def self.string_to_args s
    parts = s.split(':')
    args = {}
    args[:category] = parts.shift.to_sym
    args[:type] = (parts.shift)[/^type_(.*)/, 1].to_sym
    args[:log_file] = (parts.shift)[/log_file_(.*)/, 1]
    unless parts.empty?
      args[:log_position] = (parts.shift)[/log_position_(.*)/, 1].to_i
    end
    unless parts.empty?
      args[:n_parts] = (parts.shift)[/n_parts_(.*)/, 1].to_i
      args[:part_number] = (parts.shift)[/part_number_(.*)/, 1].to_i
    end
    args
  end
  
  def [] x
    send x  
  end
  
  def <=> rhs
    category <=> rhs.category || self[:type] <=> rhs[:type] || log_file <=> rhs.log_file || log_position <=> rhs.log_position
  end
  
  append_factory_method do |args|
    result = args[:string] && create_object(string_to_args(args[:string]))
    if result
      result.timestamp = args[:timestamp]
    end
    result
  end
end

class MysqlBackup::Entity::Identifier::Full < MysqlBackup::Entity::Identifier
end

class MysqlBackup::Entity::Identifier::Full::Binary < MysqlBackup::Entity::Identifier::Full
  append_factory_method {|args| args[:category] == :full && args[:type] == :binary && new(args)}
end

class MysqlBackup::Entity::Identifier::Full::Mysqldump < MysqlBackup::Entity::Identifier::Full
  append_factory_method {|args| args[:category] == :full && args[:type] == :mysqldump && new(args)}
end

class MysqlBackup::Entity::Identifier::Log < MysqlBackup::Entity::Identifier
end

class MysqlBackup::Entity::Identifier::Log::Current < MysqlBackup::Entity::Identifier::Log
  def to_s
    pos = n_digits log_position
    return "#{category}:type_#{@type}:log_file_#{log_file}:log_position_#{pos}"
  end
  
  append_factory_method {|args| args[:category] == :log && args[:type] == :current && new(args)}
end

class MysqlBackup::Entity::Identifier::Log::Complete < MysqlBackup::Entity::Identifier::Log
  def to_s
    return "#{category}:type_#{@type}:log_file_#{log_file}"
  end
  append_factory_method {|args| args[:category] == :log && args[:type] == :complete && new(args)}
end

class Pathname
  def path
    to_s
  end
end
