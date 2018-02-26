namespace :concur do
  desc 'upload concur lists and employee changes'
  task daily_upload: :environment do
    upload = ConcurImporter::Upload.new
    upload.all
  end
end
