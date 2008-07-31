require 'rubygems'
require 'named_arguments'
require 'mysql_backup/entity/files'

class MysqlBackup::Entity::Logs < MysqlBackup::Entity::Files
  include NamedArguments
  
  attr_accessor :log_bin_dir
  attr_accessor :completed_logs
  attr_accessor :log_position
  attr_accessor :log_file
  
  # Takes the following arguments:
  #
  #   :log_bin_dir => The prefix of the log files
  #   :completed_logs => All the logs before the one being written
  #   :log_file => The current log
  #   :log_position => The position in the log file
  def initialize args = {}
    super
    @log_bin_dir = Pathname.new(args[:log_bin_dir])
  end
  
  def completed_logs_paths
    completed_logs.map {|l| Pathname.new(log_bin_dir) + l}
  end
  
  def log_file_path
    Pathname.new(log_bin_dir) + log_file
  end
  
  def save args = {}
    # Do the complete logs
    completed_logs_paths.each do |p|
      i = MysqlBackup::Entity::Identifier.create_object :category => :log, :type => :complete, :log_file => p.basename.to_s, :n_parts => 1, :part_number => 0
      files = self.class.tar_files [p.to_s]
      yield :identifier => i, :file => files.first
    end
    
    # Do the current log
    i = MysqlBackup::Entity::Identifier.create_object :category => :log, :type => :current, :log_file => log_file, :log_position => log_position, :n_parts => 1, :part_number => 0
    yield :identifier => i, :file => log_file_path
  end
end