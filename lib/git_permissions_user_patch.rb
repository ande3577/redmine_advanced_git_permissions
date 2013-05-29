require_dependency 'user'


module UserPatch
  def self.included(base)
    
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      has_many :ref_members, :dependent => :destroy
    end
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
  end
end

User.send(:include, UserPatch)