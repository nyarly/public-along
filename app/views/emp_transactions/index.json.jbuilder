json.array!(@emp_transactions) do |emp_transaction|
  json.extract! emp_transaction, :id, :kind, :user_id
  json.url emp_transaction_url(emp_transaction, format: :json)
end
