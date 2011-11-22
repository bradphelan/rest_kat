require 'kwalify'

module RestKat
  ## validator class for answers
  class Validator < Kwalify::Validator

    def schema
      @schema
    end

	def self.load_schema file
		Kwalify::Yaml.load_file file
	end

    def initialize type
      super (@resource_schema=type)
    end

    def self.find_resource resource, schema
      schema["resources"].find do |r|
        r["name"].to_s == resource.to_s
      end
    end

    def self.for_resource resource, file
		schema = load_schema file
		type = find_resource(resource, schema)["type"]
		raise Exception.new("Can't find resource '#{resource}'") unless type
		Validator.new type
    end

    def self.for_type type, file
		schema = load_schema file
		type = schema[type.to_s]
		raise Exception.new("Can't find resource '#{resource}'") unless type
		Validator.new type
	end

    def self.for_resource_collection resource, file
		schema = load_schema file
		type = find_resource(resource, schema)["type"]

		collection_type = {
			"type" => "seq",
			"sequence" => [ type ]
		}
		Validator.new collection_type
	end

  end

end
