require 'kwalify'

module RestKat
  ## validator class for answers
  class Validator < Kwalify::Validator
    ## load schema definition
    @@schema = Kwalify::Yaml.load_file(  File.join Rails.root, "lib/rest_kit/api_schema.yml" )
    def self.schema
      @@schema
    end

    def resource_schema
      @resource_schema
    end

    def initialize type
      super (@resource_schema=type)
    end

    def self.find_resource resource
      Validator.schema["resources"].find do |r|
        r["name"].to_s == resource.to_s
      end
    end

    def self.for_resource resource
      type = find_resource(resource)["type"]
      raise Exception.new("Can't find resource '#{resource}'") unless type
      pp type
      Validator.new type
    end

    def self.for_type type
      type = Validator.schema[type.to_s]
      raise Exception.new("Can't find resource '#{resource}'") unless type
      pp type
      Validator.new type
    end

    def self.for_resource_collection resource
      type = find_resource(resource)["type"]
      raise Exception.new("Can't find resource '#{resource}'") unless type
      collection_type = {
        "type" => "seq",
        "sequence" => [ type ]
      }

      Validator.new collection_type
    end

  end

end
