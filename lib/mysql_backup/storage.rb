require 'rubygems'
require 'named_arguments'

require 'mysql_backup/entity/identifier'

module MysqlBackup; end

class MysqlBackup::Storage
  include NamedArguments
  
  # The Logger object
  attr_accessor :log
end
