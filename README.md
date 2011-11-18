RestKat
=======

We have all heard the mantra that REST does not require a schema because it is
just JSON. However when I found myself writing hundreds of lines of objective C
binding code with [RestKit](http://restkit.org) I thought that there must be
a better way of doing the boring bits.

Now there is RestKat.

You just have to declare your API in a YAML file using an extension to the
[kwalify](http://www.kuwata-lab.com/kwalify/) schema validator.

A schema looks like the following

    configuration_type: &configuration_type
        type: map
        name: XXConfiguration
        mapping:
            name:
                type: str
                required: yes
            email:
                type: str
                required: yes

    log_type: &todo_type
        type: map
        name: XXTodo
        mapping:
            id:
                type:int
                required: yes
            due:
                type: str
                name: NSDate
            desc:
                type: str
                name: NSString

    search_type: &search_type
        type: map
        name: XXTodoSearch
        mapping:
            desc:
                type: str
                required: yes
                
            
        
    
    ##########################################
    #  REQUEST TYPES
    ##########################################

    # permissions and generated routes. A 's' singleton
    # modifier can be added to indicate that the resource
    # does not represent a collection
    #
    #   s  - singleton modifier
    #
    #   c  - POST "/resource"
    #   sc - invalid
    #
    #   r  - GET  "/resource/:id" 
    #        GET  "/resource" 
    #   sr - GET "/resource" 
    #
    #   u  - adds PUT "/resource/:id"
    #   su - adds PUT "/resource"
    #
    #   d  - adds PUT "/resource/:id"
    #   sd - adds PUT "/resource"
    #
    resources:

      # singletons
      - name: configuration
        type: *configuration_type
        resource: /configuration
        permissions: sru

      # collections
      - name: todo
        type: *todo_type
        resource: /todo
        queries:
            - name: search
              type: *search_type
        permissions: crud

The resources section defines the RESTful resources and
thier methods. The type of each resource refers to types
defined further up the file. The name of each type must
refer to the desired objective C class name for each
type.

Resources can be interfaced with through the generated
subclasses via this interface.

    @interface MSRestSerializableResource : MSRestSerializable

    #pragma mark methods to be overridden

    + (Class) classForResource;

    // The resource path. If this 
    + (NSString *) resourcePath;

    // Is the resource a singleton or a collection
    + (bool) isSingleton;

    // Can the client create resources
    + (bool) canCreate;

    // Can the client read resources
    + (bool) canRead;

    // Can the client update resources
    + (bool) canUpdate;

    // Can the client delete resources
    + (bool) canDelete;

    #pragma mark helpers

    // The router for this class
    + (RKObjectRouter *) router;

    // Intialize the routing module. Must
    // be called from +initialize in a 
    // subclass or the logic will not
    // work.
    + (void) initializeRouting;


    // save the object
    -(void) saveWithDelegate:(id<RKObjectLoaderDelegate>)delegate;

    // Find an instance by id
    + (void) find:(NSNumber *)id 
     withDelegate:(id<RKObjectLoaderDelegate>)delegate;

    // Load collection
    + (void) loadCollectionWithDelegate:(id<RKObjectLoaderDelegate>)delegate;

    // Load collection with query
    + (void) loadCollectionThroughQuery:(MSRestSerializable *)mappableQueryObject 
                           withDelegate:(id<RKObjectLoaderDelegate>)delegate;

    @end

Standard types of int, float, str are mapped to
NSNumber, NSNumber and NSString respectively unless
a specialized class is given.

There is a helper for your custom rake task to do
the building of the source code for you. For example
you could do

    require 'rest_kat'

    namespace :iphone do
      namespace :api do
        ApiLocation = File.expand_path "src/AutoGen", __FILE__
        SchemaLocation = File.expand_path "api_schema.yml", __FILE__

        task :_generate => RestKat::generate_api(ApiLocation, SchemaLocation)

        desc "Generate iPhone API to #{ApiLocation}"
        task :generate => :_generate
      end
    end

The class heirarchy for the generated classes is

    MSRestSerializable 
            ^
            |
    MSRestSerializableResource

All types that are also are resource derive from MSRestSerializableResource
and all helper or nested types derive from MSRestSerializable.

Refer to MSRestSerializable.h for more details and the [restKit documentation](http://restkit.org)



