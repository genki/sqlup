require 'rubygems'
require 'active_record/vendor/mysql'
require 'named_arguments'
require 'mysql_backup/server'
require 'mysql_backup/storage/s3'
require 'mysql_backup/entity/files'
require 'mysql_backup/entity/files/innodb'
require 'mysql_backup/entity/files/myisam'
require 'mysql_backup/entity/logs'
require 'mysql_backup/entity/mysqldump'
require 'mysql_backup/librarian/backup_collection'

# backup_data_files:: Save the binary backups
# backup_mysqldump:: Send the mysqldump to s3
# backup_binary_logs:: Send the logs to S3
class MysqlBackup::Librarian
  include NamedArguments 
  
  # MySQL connection parameters
  attr_accessor :host, :user, :password, :db, :port, :sock, :flag
  
  # The logger.  Default is to log via STDERR.
  attr_accessor :log
  
  # A MysqlBackup::Storage object.
  attr_accessor :storage
  
  # The connection to MySQL
  attr_accessor :connection 
  
  # The MysqlBackup::Server object used to talk to MySQL.
  attr_writer :mysql_server
  
  # S3 parameters
  attr_accessor :access_key_id, :secret_access_key, :bucket
  
  # Takes a required argument to specify the location of the log files:
  #
  #   :log_bin_dir => '/var/lib/mysql'
  #
  # Takes required arguments for S3:
  #
  #   :access_key_id     => 'abc',
  #   :secret_access_key => '123'
  #   :bucket => 'name_of_the_backup_bucket'
  #
  # Takes these arguments for the connection to MySQL:
  #
  #   :host
  #   :user
  #   :password
  #   :db
  #   :port
  #   :sock
  #   :flag
  # 
  # Many installations just need to specify <tt>:host</tt> and <tt>:user</tt>.
  def initialize args = {}
    super
  end
  
  def backup_data_files
    MysqlBackup::Entity::Files.create_tar_files :log => log, :mysql_server => mysql_server, :mysql_files => [innodb_files, myisam_files] do |args|
      storage.conditional_save args
    end
  end
  
  def backup_mysqldump
    m = MysqlBackup::Entity::Mysqldump.new :log => log
    m.create do |args|
      storage.conditional_save args
    end
  end
  
  def backup_binary_logs
    logs_obj = mysql_server.create_logs_obj
    logs_obj.save do |args|
      storage.conditional_save args
    end
  end
  
  def innodb_files
    @innodb_files ||= mysql_server.create_innodb_files_obj
  end
  
  def myisam_files
    @myisam_files ||= mysql_server.create_myisam_files_obj
  end
  
  def log_files
    @log_files ||= mysql_server.create_logs_obj
  end
  
  def mysql_server
    @mysql_server ||= MysqlBackup::Server.new :connection => create_connection,
      :log => log, :log_bin_dir => @log_bin_dir
  end
  
  def create_backup_group_collection_from_storage
    unless @backups
      c = MysqlBackup::Librarian::BackupCollection.new
      storage.yield_identifiers do |i|
        c.add_identifier i
      end
      @backups = c
    end
    @backups
  end
  
  def ls klass = Object
    result = []
    create_backup_group_collection_from_storage.each_group(klass) do |g|
      result << g.to_s
    end
    result
  end
  
  def rm backup_name
    g = find_group backup_name
    g.each_identifier do |i|
      storage.rm i
    end
  end
  
  def get f, directory
    case f
    when /^full:type_binary/
      get_full_binary f, directory
    when /^full:type_mysqldump/
      get_mysqldump f, directory
    end
  end
  
  def get_full_binary f, destination_dir = '/tmp'
    get_backup f do |tempfile|
      run_cmd "( cd #{destination_dir}; zcat #{tempfile.path} | tar xf - )"
    end
  end
  
  def get_mysqldump f, destination_dir = '/tmp'
    get_backup f do |tempfile|
      run_cmd "( cd #{destination_dir}; zcat #{tempfile.path} > #{f})"
    end
  end
  
  def get_logs destination_dir = '/tmp'
    create_backup_group_collection_from_storage.each_log do |g|
      log && log.info("Looking at backup #{g.to_s}")
      storage.retrieve_backup_and_then_yield_file g do |tempfile|
        run_cmd "( cd #{destination_dir}; zcat #{tempfile.path} | tar xf - )"
      end
    end
  end
  
  def run_cmd cmd
    log && log.debug("Run command: #{cmd}")
    system cmd
  end
  
  # Always call this with a block that will do something
  # with the raw data retrieved from S3.
  def get_backup f, &block
    b = find_group f
    raise RuntimeError, "Failed to find backup for #{f}" unless b
    if b
      storage.retrieve_backup_and_then_yield_file(b, &block)
    end
  end
  
  def find_group f
    create_backup_group_collection_from_storage.find_group f
  end
  
  def create_connection 
    ENV["MYSQL_UNIX_PORT"] ||= '/var/lib/mysql/mysql.sock'
    @connection ||= Mysql.connect(@host, @user, @pass, @db, @port, @sock, @flag)
  end
end
