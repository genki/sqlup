require 'rubygems'
require 'pathname'
require 'tempfile'

require 'mysql_backup/entity/identifier'

module MysqlBackup; end

class MysqlBackup::Entity
  attr_accessor :log

  # Create a set of tarred, gziped, and split files
  # for all the files given by required_path_strings.
  #
  # Return an array of Pathname objects for the 
  # split files.
  #
  # The caller is responsible for removing the files returned
  # from tar_files.
  def self.tar_files path_strings #:nodoc:
    result = []
    # Creating a tempfile to get a guaranteed unique filename.
    # We don't actually write to this tempfile, we just
    # use its name as the base name for the split.
    Tempfile.open 'mysqltarball' do |f|
      # We should never see existing files, but just in
      # case we'll need to remove any.
      Pathname.glob(f.path.to_s + 'xxx*').each {|e| e.unlink}
      
      paths = path_strings.map {|ps| ps.slice(1..-1)}.join(' ')
      five_gig = 1024 * 1024 * 1024 * 5
      tar_cmd = "( cd / ; tar cf - #{paths} | gzip | split --suffix-length=4 --bytes=#{five_gig} --numeric-suffixes - #{f.path}xxx )"
      do_tar :cmd => tar_cmd
      result = Pathname.glob(f.path.to_s + 'xxx*')
    end
    result
  end
end
