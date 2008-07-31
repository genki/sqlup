require 'aws/s3'
require 'mysql_backup/storage'

class MysqlBackup::Storage::S3 < MysqlBackup::Storage
  # The name of the bucket storing backup objects
  attr_accessor :bucket
  
  # The AWS::S3::Bucket object
  attr_writer :bucket_obj
  
  # Takes:
  #
  #   :access_key_id     => 'abc',
  #   :secret_access_key => '123'
  #   :bucket => 'name_of_the_backup_bucket'
  def initialize args = {}
    super
    connect! args unless args[:no_connect]
  end
  
  # +identifier+ is a MysqlBackup::Entity::Identifier
  # object.
  def save args
    identifier = args[:identifier]
    log && log.info("saving to S3(#{@bucket}): #{identifier}")
    AWS::S3::S3Object.store identifier.to_s, args[:file].open, @bucket
    mark_as_existing identifier.to_s
  end
  
  # +identifier+ is a MysqlBackup::Entity::Identifier
  # object.
  def conditional_save args
    identifier = args[:identifier]
    if include? identifier
      log && log.info("not saving; object exists in (#{@bucket}): #{identifier}")
    else
      save args
    end
  end
  
  def rm identifier
    AWS::S3::S3Object.delete identifier.to_s, bucket
  end
  
  def include? key
    @existing_objects ||= {}
    @existing_objects.include? key.to_s
  end
  
  def mark_as_existing key
    @existing_objects ||= {}
    @existing_objects[key.to_s] = nil
  end
  
  def read_existing_objects
    yield_objects do |o|
      mark_as_existing s3_object_to_identifier(o).to_s
      true
    end
  end
  
  def yield_objects n_keys = 1000 #:nodoc:
    objs = []
    while objs
      objs = bucket_obj.objects :max_keys => n_keys, :marker => (objs.empty? ? nil : objs.last.key)
      objs.each do |o|
        yield o
      end
      objs = nil if objs.empty? || objs.length < n_keys
    end
  end
  
  def yield_backup_objects
    yield_objects do |o|
      i = MysqlBackup::Entity::Identifier.build_object :string
      yield o if i
    end
  end
  
  def yield_identifiers
    yield_objects do |o|
      i = s3_object_to_identifier o
      yield i if i
    end
  end
  
  def retrieve_backup_and_then_yield_file group
    Tempfile.open 'backup_retrieval' do |f|
      group.identifiers.each do |i|
        AWS::S3::S3Object.stream i.to_s, bucket do |chunk|
          f.write chunk
        end
      end
      f.seek 0
      yield f
    end
  end
  
  def s3_object_to_identifier o
    MysqlBackup::Entity::Identifier.build_object :string => o.key, :timestamp => o.last_modified
  end
  
  def bucket_obj
    @bucket_obj ||= AWS::S3::Bucket.find bucket
  end
  
  def connect! args
    AWS::S3::Base.establish_connection! :access_key_id => args[:access_key_id], :secret_access_key => args[:secret_access_key]
  end
end
