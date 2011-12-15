class Company
  include MongoMapper::Document

  key :name, String
  key :link, String
	many :updates
end
