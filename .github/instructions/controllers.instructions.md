```instructions
applyTo:
  - "app/controllers/**/*.rb"
  - "engines/*/app/controllers/**/*.rb"

## API Controller Rules

### Authentication & Authorization
- ALWAYS use `before_action :authenticate_user!` on all controllers except health checks
- ALWAYS use `before_action :set_resource, only: [:show, :update, :destroy]`
- ALWAYS authorize every action with Pundit: `authorize @resource`
- ALWAYS use `authorize_collection()` for index actions with tenant scoping

### JSON:API Compliance
- ALWAYS use `render jsonapi:` for responses
- ALWAYS support `include` parameter for relationships
- ALWAYS use proper HTTP status codes: 200, 201, 204, 400, 401, 403, 404, 422, 500
- NEVER render raw JSON objects

### Public ID Lookups
- ALWAYS use `find_by!(public_id: params[:id])` for resource lookups
- NEVER use `find(params[:id])` with integer IDs
- ALWAYS use UUID public_id in URL parameters

### Error Handling
- ALWAYS use `rescue_from` for common exceptions
- ALWAYS return JSON:API error format
- NEVER leak internal error details to API responses

### Parameter Handling
- ALWAYS use strong parameters with JSON:API structure:
  ```ruby
  def resource_params
    params.require(:data).require(:attributes).permit(:title, :content)
  end
  ```
- ALWAYS validate relationships in the :data :relationships structure

### Pagination & Filtering
- 🤔 **UNDECIDED**: Kaminari vs. Pagy vs. custom pagination
- 🤔 **UNDECIDED**: Filtering strategy: ransack vs. custom filters vs. GraphQL-style
- ALWAYS implement pagination for collection endpoints
- ALWAYS support sorting with multiple fields

### Example Controller Pattern
```ruby
module Api
  module V1
    module Publishing
      class PostsController < ApplicationController
        before_action :authenticate_user!
        before_action :set_post, only: [:show, :update, :destroy]
        
        def index
          @posts = authorize_collection(
            current_account.posts.includes(:author, :blog)
          )
          
          render jsonapi: @posts, 
                 include: params[:include],
                 meta: pagination_meta(@posts)
        end
        
        def show
          render jsonapi: @post, include: params[:include]
        end
        
        def create
          result = Publishing::Posts::CreatePostService.new(
            account: current_account,
            user: current_user,
            attributes: post_params
          ).call
          
          if result.success?
            render jsonapi: result.post, status: :created
          else
            render jsonapi_errors: result.errors, status: :unprocessable_entity
          end
        end
        
        private
        
        def set_post
          @post = current_account.posts.find_by!(public_id: params[:id])
          authorize @post
        end
        
        def post_params
          params.require(:data).require(:attributes).permit(
            :title, :content, :excerpt, :status
          )
        end
        
        def authorize_collection(scope)
          policy_scope(scope)
        end
      end
    end
  end
end
```

### Serializer Integration
- ALWAYS use JSON:API serializers (not ActiveModel serializers)
- ALWAYS define relationships in serializers
- NEVER include sensitive data (passwords, tokens, internal IDs)

### Service Object Integration
- ALWAYS delegate business logic to service objects
- NEVER put business logic in controllers
- ALWAYS handle service result patterns (success/failure)

### Performance Considerations
- ALWAYS eager load associations with `includes()`
- ALWAYS add database indexes for filtered/sorted fields
- 🤔 **UNDECIDED**: Query optimization strategy: N+1 detection vs. manual optimization
- 🤔 **UNDECIDED**: Caching strategy: controller-level vs. service-level vs. model-level
```
