module FactoryCreateMethod
  def self.included target
    target.class_eval do
      include NamedArguments::MethodExtensions
      extend ClassMethods
      define_method_with_value :factory_create_base_class, target
    end
  end
  
  class NoMatchingFactory < NoMethodError; end
  
  module ClassMethods
    # Creates the appropriate object.
    # 
    # Throws NoMethodError if no factory method
    # responded to the arguments.
    # 
    # Use build_object to return nil instead
    # of throwing an exception.
    def create_object args = {}
      factory_create_base_class.factory_methods.each do |f|
        result = f.call args
        return result if result
      end
      raise FactoryCreateMethod::NoMatchingFactory, "No factory method matched #{args.inspect}"
    end
    
    # Note that this method will be replaced on the
    # first call to append_factory_method.
    def factory_methods # nodoc
      return []
    end
    
    def build_object args = {}
      create_object args
    rescue
      nil
    end
    
    def append_factory_method &block
      orig = factory_create_base_class
      orig.define_method_with_value :factory_methods, [block] + factory_methods
    end
    
    def new_if_class klass, field
      append_factory_method do |args|
        klass === args[field] && new(args)
      end
    end
  end
end
