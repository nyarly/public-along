class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options={})
    label(attribute, options[:label]) + super
  end

  def select(attribute, options={})
    label(attribute) + super
  end

  def date_select(attribute, options={})
    label(attribute) + super
  end

  def collection_select(attribute, collection, value_method, text_method, options={})
    label(attribute, options[:label]) + super
  end
end
