class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options={})
    label(attribute, options[:label]) + super
  end

  def select(attribute, choices, options={})
    label(attribute, options[:label]) + super
  end

  def date_select(attribute, options={}, html_options={})
    label(attribute, options[:label]) + super
  end

  def collection_select(attribute, collection, value_method, text_method, options={}, html_options={})
    label(attribute, options[:label]) + super
  end
end
