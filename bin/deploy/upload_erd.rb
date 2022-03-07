require "google_drive"

config_file = File.expand_path("erd-service-account.json", __dir__)
session = GoogleDrive::Session.from_config(config_file)

pdf_file = File.expand_path("../../doc/erd.pdf", __dir__)
# Skip this, nothing exceptional about Measurements API
# exceptional_names_file = File.expand_path("../../doc/exceptional_names.txt", __dir__)

folder = session.collection_by_id("1jJxr2i4jYzjisbhYdgNh2iQOBizpP-eh")
pdf_file_name = "measurements_api_erd.pdf"
existing_pdf_file = folder.file_by_name(pdf_file_name)
if existing_pdf_file
  existing_pdf_file.update_from_file(pdf_file)
else
  folder.upload_from_file(pdf_file, pdf_file_name, convert: false)
end
puts "Uploaded #{pdf_file_name} successfully"

# Skip this, nothing exceptional about Measurements API
# en_file_name = "measurements_api_exceptional_names.txt"
# existing_en_file = folder.file_by_name(en_file_name)
# if existing_en_file
#   existing_en_file.update_from_file(exceptional_names_file)
# else
#   folder.upload_from_file(exceptional_names_file, en_file_name, convert: false)
# end
# puts "Uploaded #{en_file_name} successfully"
