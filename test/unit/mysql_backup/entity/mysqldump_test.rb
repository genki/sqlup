require File.dirname(__FILE__) + '/../../test_helper'
require 'mysql_backup/entity/mysqldump'

class MysqlBackup::Entity::MysqldumpTest < Test::Unit::TestCase
  def test_create
    mysqldump_obj = MysqlBackup::Entity::Mysqldump.new
     (mysqldump_obj.expects(:system).with {|m| m =~ /mysqldump --opt/ && m !~ /#</}).returns true
    mysqldump_obj.expects(:get_log_position).returns(true)
    mysqldump_obj.expects(:compress_and_split).returns([stub])
    expects(:must_call)
    mysqldump_obj.create do |args|
      must_call
      i = args[:identifier]
      assert_equal 0, i.part_number
      assert_equal 1, i.n_parts
    end
  end
  
  def test_get_log_position
    m = MysqlBackup::Entity::Mysqldump.new
    m.get_log_position mysqldump_sample_data
    assert_equal 'thelog.000005', m.log_file
    assert_equal 1234, m.log_position
  end
  
  def mysqldump_sample_data
    StringIO.new <<-EOS
-- MySQL dump 10.10
--
-- Host: localhost    Database: test
-- ------------------------------------------------------
-- Server version       5.0.27-standard-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0
*/;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Position to start replication or point-in-time recovery from
--

-- CHANGE MASTER TO MASTER_LOG_FILE='thelog.000005', MASTER_LOG_POS=1234;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2007-06-05  0:53:56
EOS
  end
end
