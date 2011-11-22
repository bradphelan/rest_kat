module RestKat
  class Resource
    attr_accessor :hash
    def initialize resource
      self.hash = resource
    end

    def objc_resource_type
      hash[:type][:name]
    end

    def objc_class
      "MSRestResource#{hash[:name].camelize}"
    end

    def permissions
      hash[:permissions]
    end

    def c_permission_for type
      if permissions.include? type
        "true"
      else
        "false"
      end
    end

    def singleton?
      @singleton ||= permissions.include? 's'
    end

    def create?
      @create ||= permissions.include? 'c'
    end

    def read?
      @read ||= permissions.include? 'r'
    end

    def update?
      @update ||= permissions.include? 'u'
    end

    def delete?
      @delete ||= permissions.include? 'd'
    end

    def queries &block
      if hash.has_key?("queries")
        if block_given?
          hash["queries"].each &block 
        else
          hash["queries"]
        end
      else
        []
      end
    end

    def c_bool r
      if r
        "true"
      else
        "false"
      end
    end

  end

  class ObjCProperty
    attr_accessor :klass
    attr_accessor :name
    def initialize(klass, name)
      raise Exception.new(":klass parameter cannot be nil") unless klass
      raise Exception.new(":name parameter cannot be nil") unless name
      self.klass = klass
      self.name = name
    end
  end

  class ObjCClass
    attr_accessor :properties
    attr_accessor :sequence_of
    attr_accessor :type
    attr_accessor :parent
    attr_accessor :json_type
    attr_accessor :node
    attr_accessor :resource

    def objc_super_class
      if resource
        "MSRestSerializableResource"
      else
        "MSRestSerializable"
      end
    end

    def complex?
      map? || seq?
    end

    def map?
      properties && (not properties.empty?)
    end

    def seq?
      !!sequence_of
    end

    def objc_class
      self.type
    end

    def enum?
      (node["type"] == "str") && node.has_key?("enum")
    end

    def enum
      node["enum"]
    end

    def objc_property_decl name
      "@property (nonatomic, strong) #{objc_class} * #{name}"
    end

    def objc_property_arg_decl name
      "#{name}: (#{objc_class} *) #{name}"
    end

    def objc_properites_arg_list_decl
      properties.reject{|p| p.name == 'id'}.map do |p|
        p.klass.objc_property_arg_decl p.name
      end.join "\n   "
    end

    def initialize type, json_type, node
      self.properties = nil
      self.type = type
      self.json_type = json_type
      self.node = node
    end

  end

  class IosMapping

    def initialize api_schema
        raise "#{api_schema} does not exist" unless File.exist?(api_schema)
        @schema_file = api_schema
    end

    def resources_from_schema
      schema[:resources]
    end

    def schema
      require 'kwalify'
      @schema ||= HashWithIndifferentAccess.new Kwalify::Yaml.load_file(@schema_file)
    end

    def classes
      @classes ||= []
    end

    def resources
      @resources ||= []
    end

    def template name
      require 'erb'
      ERB.new File.read(File.expand_path(File.join("..", name), __FILE__)), 0, '<>'
    end

    def h_template
      template "model.h.erb"
    end

    def m_template
      template "model.m.erb"
    end

    # Generate the required objective c class AST's for th +name+ resource in
    # the correct order so they can be written to code in the correct order in
    # the templates
    def generate_objective_c_classes
      @classes = []
      resources_from_schema.collect do |resource_hash|
        Resource.new(resource_hash).tap do |resource|
          # Generate the query classes first
          resource.queries.each do |query|
            to_objective_c_class query["type"]
          end
          # Generate the resource classes next
          klass = to_objective_c_class resource.hash[:type]
          # Mark this class as being a REST resource
          klass.resource = resource
        end
      end
    end

    # Generate the objective C header for +name+ resource
    def to_h name
      @resources = generate_objective_c_classes
      h_template.result binding
    end

    # Generate the objective C implementation file for +name+ resource
    def to_m name
      @resources = generate_objective_c_classes
      #TODO below 'header' must change
      header = (File.basename name, ".*") + ".h"
      m_template.result binding
    end

    def self.obj_c_type_for_property parent_node, property_name
      parent_type = parent_node[:name].gsub /MSRest/, ''
      "MSRest#{parent_type.camelize}#{property_name.camelize}"
    end

    def find_processed_class node
      classes.find{|c| c.type == node[:name]}
    end

    # Perform a depth first traversal of the type tree. The resulting
    # classes array will have the top level class last in the array. In
    # the code generation phase this classes will be injected last into
    # the code making sure the dependencies are define in the correct
    # order.
    def to_objective_c_class node
      unless node
        raise Exception.new("node is nil for name '#{name}'")
      end

      case node[:type]
      when "map"

        unless klass = find_processed_class(node)
          klass = ObjCClass.new(node[:name], node[:type], node)

          klass.properties = node[:mapping].collect do |property_name, property_node|
            if property_node[:type] == "map"
              property_node[:name] ||= IosMapping.obj_c_type_for_property(node, property_name)
            end
            ObjCProperty.new(to_objective_c_class(property_node), property_name)
          end

          self.classes << klass
        end

      when "seq"
        klass = ObjCClass.new(node[:name] || "NSArray", node[:type], node)
        if node[:sequence].length != 1
          raise "Only support sequence of map with one map type"
        end
        sequence_node = node[:sequence].first
        if sequence_node["type"] == "map"
          if not sequence_node["name"]
            raise Exception.new ("sequence of map nodes must have a :name to generate the objective C types")
          end
          klass.sequence_of = to_objective_c_class sequence_node
        end
      when "str", "text"
        klass = ObjCClass.new(node[:name] || "NSString", node[:type], node)
      when "int"
        klass = ObjCClass.new(node[:name] || "NSNumber", node[:type], node)
      when "float"
        klass = ObjCClass.new(node[:name] || "NSNumber", node[:type], node)
      when "bool"
        klass = ObjCClass.new(node[:name] || "NSNumber", node[:type], node)
      when "any"
        klass = ObjCClass.new(node[:name] || "NSObject", node[:type], node)
      else
        raise Exception.new("Unhandled type '#{node[:type]} for node with name #{node[:name]}")
      end

      raise Exception.new("klass cannot be nil") unless klass

      klass

    end
  end
end

module RestKat 

    class MySugrIphone
        class <<self
            def root
                ENV["MYSUGR_IPHONE_ROOT"]
            end
        end
    end

    def self.generate_item(api_location, schema_location, ext)
        deps = %w[
            model.h.erb
            model.m.erb
            rest_kat.rb
            validator.rb
        ].collect do |d|
            File.expand_path "../#{d}", __FILE__
        end

        deps << schema_location

        file = "#{api_location}.#{ext}"

        file_task = Rake::FileTask.define_task file => deps do
            File.open file, 'w' do |f|
                puts "Generating #{file}"
                f.write RestKat::IosMapping.new(schema_location).send("to_#{ext}", file)
            end
        end  
    end

    def self.generate_api(api_location, schema_location)

        api_src = File.join api_location, "MSRestApiAutoGen"
        m_file_task = generate_item(api_src, schema_location, "h")
        h_file_task = generate_item(api_src, schema_location, "m")

        src_path = File.expand_path "../../src", __FILE__

        src_h = File.join src_path, "MSRestSerializable.h"
        src_m = File.join src_path, "MSRestSerializable.m"

        tgt_h = File.join api_location, "MSRestSerializable.h"
        tgt_m = File.join api_location, "MSRestSerializable.m"


        t0 = file tgt_h, src_h do
            cp src_h, tgt_h, :verbose => true
        end

        t1 = file tgt_m, src_m do
            cp src_m, tgt_m, :verbose => true
        end

        Rake::Task.define_task :type => [m_file_task, h_file_task, t0, t1]
    end

end
