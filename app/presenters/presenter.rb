class Presenter < SimpleDelegator
  def initialize(model)
    @model = model
    super
  end
end
