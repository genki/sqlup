require 'mysql_backup/entity/files'

# Used to save all of the files for a MySQL MyISAM database.
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
# - MyISAM files.
#
# For all of these, we track the log positions (the log file/log position pair).
class MysqlBackup::Entity::Files::Myisam < MysqlBackup::Entity::Files
  # Takes the following arguments:
  #
  #   :datadir => The MySQL data directory.
  # 
  # The following files will be backed up with the default base_dir and ib_basename:
  #
  #   /var/lib/mysql/*/*.MYD - all files in any directory that contain one or more *.MYD files
  
  attr_accessor :datadir
  
  def initialize args = {}
    super
    set_path_vars %w(datadir), args
  end
  
  # Returns a list of Pathname objects that need to be
  # backed up for a mysql server using innodb.
  def required_paths
    result = []
    result.concat myisam_database_dirs
    result.uniq
  end
  
  # Returns an array of Pathnames for all databases
  # in the base directory.
  #
  # A database in this case is a directory containing 
  # any files matching *.frm.
  def myisam_database_dirs
    result = Pathname.glob(@datadir_path + '*/*.MYD')
    result.concat Pathname.glob(@datadir_path + '*/*.MYI')
    result = result.map {|d| d.dirname}
    result.uniq
  end
end