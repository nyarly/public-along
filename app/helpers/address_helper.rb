module AddressHelper
  def address_for(employee)
    presenter =  AddressPresenter.new(employee.address)
    if block_given?
      yield presenter
    else
      presenter
    end
  end
end
