require 'mysql_backup/entity'

# Mysqldump files are stored gzipped and split
class MysqlBackup::Entity::Mysqldump
  include NamedArguments
  
  attr_accessor :log
  attr_accessor :log_file
  attr_accessor :log_position
  
  # Create a mysqldump file and yield 
  # a hash with a MysqlBackup::Entity::Identifier.
  def create 
    Tempfile.open 'mysqldump' do |f|
      cmd = "mysqldump --opt --all-databases --single-transaction --master-data=2 > #{f.path}"
      log && log.info("running #{cmd}")
      system cmd or raise RuntimeError, "failed to run command: #{cmd}"
      f.flush
      get_log_position f or raise RuntimeError, "could not get log position"
      f.seek 0
      compressed_files = compress_and_split f
      identifier = MysqlBackup::Entity::Identifier.create_object :category => :full, :type => :mysqldump, :n_parts => compressed_files.length, :log_position => log_position, :log_file => log_file
      compressed_files.each_with_index do |cf, n|
        i = identifier.dup
        i.part_number = n
        yield :identifier => i, :file => cf  
      end
    end
  end
  
  # Search through a mysqldump file looking for a line like
  #   CHANGE MASTER TO MASTER_LOG_FILE='thelog.000005', MASTER_LOG_POS=1163;
  #
  # Set log_position and log_file to the corresponding values.
  def get_log_position file_obj
    result = {}
    n = 0
    file_obj.each_line do |l|
      if l =~ /CHANGE MASTER TO MASTER_LOG_FILE='(.*)', MASTER_LOG_POS=(\d+)/i
        @log_file = $1
        @log_position = $2.to_i
        return true
      end
      n += 1
      break if n > 100
    end
    false
  end
  
  def compress_and_split file_obj
    destination_name = "#{file_obj.path}xxx"
    cmd = "cat #{file_obj.path} | gzip | split --suffix-length=4 --bytes=10240000 --numeric-suffixes - #{destination_name}"
    log && log.info("running " + cmd)
    system cmd
    Pathname.glob destination_name + "*"
  end
end