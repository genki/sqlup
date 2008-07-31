$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'active_record/vendor/mysql'
require 'mysql_backup/librarian'
require 'mysql_backup/storage/s3'

module MysqlBackup
  VERSION = '0.0.13.2'
end
