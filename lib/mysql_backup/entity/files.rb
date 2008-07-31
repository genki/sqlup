require 'pathname'
require 'tempfile'

require 'mysql_backup/entity'
require 'mysql_backup/entity/identifier'

# See MysqlBackup::Entity::Files::Innodb and MysqlBackup::Entity::Files::Myisam
# for implementations of this abstract base class.
class MysqlBackup::Entity::Files < MysqlBackup::Entity
  def initialize args = {}
    super()
  end
  
  # Create the tar files to back up a mysql instance.
  #
  # Takes the following:
  # 
  #   :mysql_server => a MysqlBackup::Server object
  #   :mysql_files => an array of MysqlBackup::Entity::Files objects
  # 
  # Yields a hash:
  #
  #   :identifier => a MysqlBackup::Entity::Identifier object
  #   :file => a Pathname object
  def self.create_tar_files args = {}, &block
    begin
      log_data = build_files args
      log_data[:files].each do |p|
        process_file(log_data.merge(:file => p), &block)
      end
    ensure
      #      files.each {|f| f.unlink if f.exist?}
    end
  end
  
  # Create the actual files in a 
  # <tt>with_lock</tt> block.
  def self.build_files args #:nodoc:
    log_data = nil
    args[:mysql_server].with_lock do |l|
      log_data = l
      mysql_file_objs = args[:mysql_files] 
      mysql_file_objs.each do |o|
        o.confirm_required_paths_are_readable
      end
      path_strings = (mysql_file_objs.map {|o| o.required_path_strings}).flatten.uniq
      log_data[:files] = tar_files path_strings
      log_data[:n_parts] = log_data[:files].length
    end
    log_data
  end
  
  # Process each file with the specified block
  def self.process_file args, &block #:nodoc:
    part_number = args[:file].to_s[/.*(\d+)$/, 1].to_i
    identifier = MysqlBackup::Entity::Identifier.create_object args.merge(:category => :full, :type => :binary, :part_number => part_number)
    block.call(:identifier => identifier, :file => args[:file])
  end
  
  def confirm_required_paths_are_readable
    required_paths.each do |p|
      raise RuntimeError, "Not readable: #{p}" unless p.readable?
    end
  end
  
  # Returns a list of path strings that need to be
  # backed up.
  def required_path_strings
    files = required_paths.map {|p| p.cleanpath.to_s}
  end
  
  def self.do_tar args #:nodoc:
    log = args[:log]
    log && log.info("running #{cmd}")
    system args[:cmd] or raise RuntimeError, "The command failed with status #{$?}"
  end
  
  # Given a set of variable names, create a 
  # set of matching Pathname objects with
  # <tt>_path</tt> appended to the name.
  def set_path_vars var_names, args = {} #:nodoc:
    args.each_pair do |k,v|
      send "#{k}=", v
    end
    var_names.each do |p|
      instance_var_name = "@#{p}"
      instance_var_value = instance_variable_get(instance_var_name)
      path_instance_var_name = "@#{p}_path"
      raise RuntimeError, "Must pass :#{p}" unless instance_var_value
      new_path = Pathname.new(instance_var_value)
      instance_variable_set path_instance_var_name, new_path
      raise RuntimeError, "Must provide a readable file for #{instance_var_name}" unless new_path.readable?
    end
  end
end
