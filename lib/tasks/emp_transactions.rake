namespace :emp_transactions do
  desc 'update kind to new format'
  task :update_kinds => :environment do
    EmpTransaction.all.each do |emp_trans|
      new_kind = emp_trans.kind.gsub(' ', '').underscore
      emp_trans.kind = new_kind
      emp_trans.save
    end
  end
end
