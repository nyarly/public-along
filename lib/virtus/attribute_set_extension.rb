module Virtus
  class AttributeSet
    def self.create(descendant)
      if descendant.respond_to?(:superclass) && descendant.superclass.respond_to?(:attribute_set)
        parent = descendant.superclass.public_send(:attribute_set)
      elsif !descendant.is_a?(Module)
        if descendant.respond_to?(:attribute_set, true) && descendant.send(:attribute_set)
          parent = descendant.send(:attribute_set)
        elsif descendant.class.respond_to?(:attribute_set)
          parent = descendant.class.attribute_set
        end
      end
      descendant.instance_variable_set('@attribute_set', AttributeSet.new(parent))
    end
  end
end
