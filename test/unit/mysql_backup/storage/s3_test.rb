require File.dirname(__FILE__) + '/../test_helper'
require 'mysql_backup/storage/s3'
require 'ostruct'

class MysqlBackup::Storage::S3Test < Test::Unit::TestCase
  def test_save
    Pathname.any_instance.stubs(:readable?).returns(true)
    s = MysqlBackup::Storage::S3.new :bucket => 'banshee', :access_key_id => 'asdf', :secret_access_key => '332'
    AWS::S3::S3Object.expects(:store).with do |name, file, bucket|
      name == 'full:type_binary:log_file_log.0001:log_position_0000000012:n_parts_0000000002:part_number_0000000001'
    end
    p = Pathname.new '/tmp/log.0001'
    p.expects(:open)
    i = MysqlBackup::Entity::Identifier.create_object :category => :full, :log_file => 'tst', :log_file => 'log.0001', :log_position => 12, :type => :binary, :part_number => 1, :n_parts => 2 
    s.save :identifier => i, :file => p
  end
  
  def test_conditional_save
    s = MysqlBackup::Storage::S3.new :bucket => 'banshee', :access_key_id => 'asdf', :secret_access_key => '332'
    s.expects(:include?).returns(false)
    args = {:identifier => nil, :file => nil}
    s.expects(:save).with(args)
    s.conditional_save args
  end
  
  def test_include_eh?
    s = standard_s3
    s.include? 'foo'
  end
  
  def test_s3_object_to_identifier
    o = OpenStruct.new :key => 'full:type_binary:log_file_log.0001:log_position_12:n_parts_2:part_number_1', :last_modified => Time.now
    s = MysqlBackup::Storage::S3.new :no_connect => true
    i = s.s3_object_to_identifier o
  end
  
  def test_mark_as_existing
    s = standard_s3
    s.mark_as_existing 'foo'
  end
  
  def test_read_existing_objects
  end
  
  def test_yield_objets
    s = standard_s3
    expects(:must_call).with('a')
    expects(:must_call).with('b')
    s.bucket_obj = stubbed_bucket
    s.yield_objects(1) do |o|
      must_call o.key
    end
  end
  
  def test_bucket_obj
  end

  def standard_s3
    MysqlBackup::Storage::S3.new :access_key_id => 2, :secret_access_key => 'x'
  end
  
  def stubbed_bucket 
    fake_obj_a = stub(:key => 'a')
    fake_obj_b = stub(:key => 'b')
    b = stub("stubbed bucket")
    b.stubs(:objects).times(0..100).returns([fake_obj_a], [fake_obj_b], [])
    b
  end
end