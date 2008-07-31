require 'rubygems'
require 'named_arguments'
require 'mysql_backup/entity'
require 'mysql_backup/entity/logs'
require 'mysql_backup/entity/files/innodb'
require 'mysql_backup/entity/files/myisam'

module MysqlBackup; end

# To get the current log position:
#
#   show_master_status => {:file => 'logfilename_0004', :position => 386}
#
# To get a list of the available log files:
#
#   show_binary_logs => %w(logfilename_0003 logfilename_0004)
# 
# To get a list of closed log files:
#
#   completed_logs => %w(logfilename_0003)
#
# To get a MysqlBackup::InnodbFiles object:
# 
#   
class MysqlBackup::Server
  include NamedArguments 
  
  # The MySQL connection
  attr_accessor :connection
  attr_accessor :log_bin_dir
  
  # Returns just the base element of innodb_data_file_path.
  # Given 
  #   ibdata1:10M:autoextend
  # Return 
  #   ibdata
  def innodb_data_file_path
    v = show_variables
    path = v[:innodb_data_file_path]
    path = path.split(':').first
    path =~ /(.*)\d+$/
    $1
  end
  
  def innodb_data_home_dir
    innodb_data_home_dir = show_variables[:innodb_data_home_dir]
    return innodb_data_home_dir unless innodb_data_home_dir.empty? 
    datadir
  end
  
  def datadir
    show_variables[:datadir]
  end
  
  def log_bin_dir
    @log_bin_dir || datadir
  end
  
  # Attempts to recreate the option passed
  # to log-bin.
  def log_bin
    logs = show_binary_logs
    logs.last =~ /(.*)\.\d+$/
    $1
  end
  
  # Returns an array of log file names.
  #
  # If you need the file sizes, call 
  # query_to_array 'show binary logs'
  # directly.
  #
  # Returns [] if there are no logs.
  def show_binary_logs
    query_to_list 'show binary logs', 'Log_name'
  end
  
  def create_innodb_files_obj
    MysqlBackup::Entity::Files::Innodb.new :datadir => datadir, :innodb_data_home_dir => innodb_data_home_dir, :innodb_data_file_path => innodb_data_file_path
  end
  
  def create_myisam_files_obj
    MysqlBackup::Entity::Files::Myisam.new :datadir => datadir
  end
  
  def create_logs_obj
    result = nil
    with_lock do |log_identifier|
      i = log_identifier.merge :log_bin_dir => log_bin_dir, :completed_logs => completed_logs
      result = MysqlBackup::Entity::Logs.new i
    end
    result
  end
  
  # Return a hash of the mysql system variables.
  # 
  # The keys are lower case symbols.
  def show_variables
    query_to_hash 'show variables', 'Variable_name', "Value"
  end
  
  # Returns a hash containing:
  #
  #   :file => the name of the current log file
  #   :position => the position in the current log file where the next entry will be written
  def show_master_status
    r = query_to_array_of_symbolic_hashes 'show master status'
    r.first
  end
  
  # Returns true if any entries have been written to the current log file.
  def current_log_has_entries?
    m = show_master_status
    return false if m.empty?
    m['Position'].to_i > 4
  end
  
  # Returns a list of all log files except the open log.
  def completed_logs
    result = show_binary_logs
    result.pop
    result
  end
  
  ######################
  # Internal methods below this point
  ######################
  
  # Call <tt>flush logs</tt>.
  def flush_logs!
    query_to_array 'flush logs'
  end
  
  def with_lock
    lock_tables
    m = show_master_status
    raise RuntimeError, "No results from show master status.  Is binary logging enabled?" unless m
    yield :log_file => m[:file], :log_position => m[:position]
  ensure
    unlock_tables
  end
  
  def lock_tables
    query_to_array 'FLUSH TABLES WITH READ LOCK'
  end
  
  def unlock_tables
    query_to_array 'UNLOCK TABLES'
  end
  
  # Required arguments:
  #
  #   :connection => The MySQL connection
  def initialize args = {}
    super
  end
  
  # Run the query given in +q+ and
  # return the value in the
  # result identified by +field+.
  # 
  # Return nil if no rows are returned.
  # There is no way to distinguish
  # between no rows and a nil
  # value.  Call query_to_list
  # if you need that functionality.
  def query_to_value q, field
    result = query_to_list q, 'Value'
    result.first
  end
  
  # Return a list of values
  # from the column +field+
  # from the query +q+. 
  #
  # Return [] if no rows
  # are returned.
  def query_to_list q, field
    r = query_to_array(q).map {|l| l[field.downcase.to_sym]}
    r
  end
  
  # Return the rows of the query as
  # an array of 
  def query_to_array q
    result = []
    a = @connection.query(q)
    a && a.each_hash do |l|
      result << hash_to_symbolic_hash(l)
    end
    result
  end
  
  def query_to_array_of_symbolic_hashes q #:nodoc:
    result = query_to_array q
    result.map {|r| hash_to_symbolic_hash r}
  end
  
  # Run the query and return all rows
  # as key/value pairs in a hash.
  def query_to_hash q, k_name, v_name #:nodoc:
    result = {}
    @connection.query(q).each_hash do |l|
      k = l[k_name]
      result[k.to_s.downcase.to_sym] = normalized_value l[v_name]
    end
    result
  end
  
  # Run the query given in +q+ and
  # return the first row as a hash.
  # 
  # Return nil if no rows are returned.
  def query_to_single_hash q #:nodoc:
    result = query_to_array q
    hash_to_symbolic_hash result.first
  end
  
  def hash_to_symbolic_hash h #:nodoc:
    result = {}
    h.each_pair do |k,v|
      result[k.to_s.downcase.to_sym] = normalized_value v
    end
    result
  end
  
  def normalized_value v #:nodoc:
    i = v.to_i
    v = i if i.to_s == v.to_s
    v = case v
    when /^(on|yes)$/i: true
    when /^(off|no)$/i: nil
    else v
    end
    v
  end
end
