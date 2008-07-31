require 'mysql_backup/entity/files'

# Used to save all of the files for a MySQL Innodb database.
# 
# Normal use is:
#
#   i = Mysql::InnodbFiles.new
#   array_of_pathname_objects = i.tar_files
#
# The caller is responsible for removing the files returned
# from tar_files.
#
# See new for a description of the arguments used to create a Mysql::InnodbFiles object
# matching your mysql layout.
# 
# You can create instances of Mysql::InnodbFiles by hand, but normally
# you'd use MysqlBackup::Server to create them for you.  
# MysqlBackup::Server
# objects will detect where your data files are and fill in the correct options for
# Mysql::InnodbFiles.new.
#
# = What is backed up
#
# - Innodb data files.  Your innodb files must all start with the same string
#   and end with a sequence of digits.  +ibdata001+, +ibdata002+, etc. is fine,
#   but +firstfile+, +secondfile+ is not supported.
# - MyISAM files.
# - Log files.  You need to specify the directory where the log files are stored;
#   there's no way to extract this from a running server. 
# - +mysqladmindump+ files.
#
# For all of these, we track the log positions (the log file/log position pair).
class MysqlBackup::Entity::Files::Innodb < MysqlBackup::Entity::Files
  attr_accessor :datadir, :innodb_data_home_dir, :innodb_data_file_path

  # Takes the following arguments:
  #
  #   :datadir => The MySQL data directory.
  #   :innodb_data_home_dir => The directory for innodb files.
  #   :innodb_data_file_path => The root name for the innodb files.
  #   :log_bin_dir => The directory containing the log files.
  #   :log_bin => The prefix of the log files.
  # 
  # The following files will be backed up with the default base_dir and ib_basename:
  #
  #   /var/lib/mysql/ibdata*
  #   /var/lib/mysql/*/*.frm - all files in any directory that contain one or more *.frm files
  #   /var/lib/mysql/*/*.MYD - all files in any directory that contain one or more *.MYD files
  def initialize args = {}
    set_path_vars %w(datadir innodb_data_home_dir), args
  end
  
  # Returns a list of Pathname objects that need to be
  # backed up for a mysql server using innodb.
  def required_paths
    result = []
    result.concat innodb_files
    result.concat innodb_database_dirs
    result.uniq
  end
  
  # Returns an array of Pathnames for all databases
  # in the base directory.
  #
  # A database in this case is a directory containing 
  # any files matching *.frm.
  def innodb_database_dirs
    result = Pathname.glob(@innodb_data_home_dir_path + '*/*.frm')
    result = result.map {|d| d.dirname}
    result.uniq
  end
  
  def innodb_files
    ib = @innodb_data_home_dir_path + @innodb_data_file_path
    Pathname.glob ib.cleanpath.to_s + '*'
  end
end