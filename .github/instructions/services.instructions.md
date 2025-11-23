```instructions
applyTo:
  - "app/services/**/*.rb"
  - "engines/*/app/services/**/*.rb"

## Service Object Rules

### Service Object Pattern
- ALWAYS inherit from `ApplicationService`
- ALWAYS use the Result pattern (success/failure)
- ALWAYS encapsulate business logic in services
- NEVER put business logic in controllers or models

### Initialization Pattern
```ruby
# ALWAYS use this initialization pattern:
class CreatePostService < ApplicationService
  def initialize(account:, user:, attributes:)
    @account = account
    @user = user
    @attributes = attributes
  end
  
  private
  
  attr_reader :account, :user, :attributes
end
```

### Call Method Pattern
```ruby
# ALWAYS implement call method with Result pattern:
def call
  return failure(errors: 'Invalid input') unless valid?
  
  result = perform_operation
  return failure(errors: result.errors) unless result.persisted?
  
  trigger_side_effects(result)
  success(post: result)
end
```

### Result Pattern
```ruby
# ApplicationService base class provides:
class ApplicationService
  def success(data = {})
    Result.new(success: true, data: data)
  end
  
  def failure(errors:)
    Result.new(success: false, errors: errors)
  end
  
  class Result
    attr_reader :data, :errors
    
    def initialize(success:, data: {}, errors: [])
      @success = success
      @data = data
      @errors = errors
    end
    
    def success?
      @success
    end
    
    def failure?
      !@success
    end
    
    # Dynamic attribute access
    def method_missing(method_name, *args, &block)
      if @data.key?(method_name)
        @data[method_name]
      else
        super
      end
    end
  end
end
```

### Transaction Handling
- ALWAYS wrap multi-step operations in database transactions
- Use `ActiveRecord::Base.transaction do` for data consistency
- NEVER let partial failures leave data in inconsistent state

### Error Handling
- ALWAYS validate inputs before processing
- ALWAYS return meaningful error messages
- NEVER let exceptions bubble up unhandled
- Use rescue blocks for expected failures

### Cross-Engine Service Communication
- ALWAYS call other engines via their service objects
- NEVER access other engines' models directly
- Pass simple data types between engines (not AR objects)

### Background Job Integration
- 🤔 **UNDECIDED**: Job queue: Sidekiq vs. Solid Queue vs. GoodJob
- ALWAYS queue long-running operations
- ALWAYS handle job failures gracefully
- Use service objects for job processing logic

### Example Service Patterns

#### Simple CRUD Service
```ruby
module Publishing
  module Posts
    class CreatePostService < ApplicationService
      def initialize(account:, user:, attributes:)
        @account = account
        @user = user  
        @attributes = attributes
      end
      
      def call
        return failure(errors: validation_errors) unless valid?
        
        post = nil
        ActiveRecord::Base.transaction do
          post = create_post
          create_initial_revision(post)
          schedule_ai_enhancement(post) if auto_enhance?
        end
        
        success(post: post)
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
      
      private
      
      attr_reader :account, :user, :attributes
      
      def valid?
        # Validation logic
      end
      
      def create_post
        account.posts.create!(attributes.merge(
          author: user,
          status: 'draft'
        ))
      end
    end
  end
end
```

#### Cross-Engine Service
```ruby
module AiAssistant
  module Content
    class EnhancePostService < ApplicationService
      def initialize(post_public_id:, account:, enhancement_type:)
        @post_public_id = post_public_id
        @account = account
        @enhancement_type = enhancement_type
      end
      
      def call
        # Get post via publishing engine service
        post_result = Publishing::Posts::FindPostService.new(
          public_id: post_public_id,
          account: account
        ).call
        
        return failure(errors: 'Post not found') unless post_result.success?
        
        enhanced_content = generate_enhancement(post_result.post)
        
        # Update via publishing engine service
        Publishing::Posts::UpdatePostService.new(
          post_public_id: post_public_id,
          account: account,
          attributes: { content: enhanced_content }
        ).call
      end
      
      private
      
      attr_reader :post_public_id, :account, :enhancement_type
      
      def generate_enhancement(post_data)
        # AI processing logic
      end
    end
  end
end
```

### Testing Services
```ruby
# ALWAYS test services in isolation:
RSpec.describe Publishing::Posts::CreatePostService do
  describe '#call' do
    let(:account) { create(:account) }
    let(:user) { create(:user) }
    let(:attributes) { { title: 'Test Post', content: 'Content' } }
    
    subject(:service) { described_class.new(account: account, user: user, attributes: attributes) }
    
    context 'with valid attributes' do
      it 'creates a post' do
        result = service.call
        
        expect(result).to be_success
        expect(result.post).to be_persisted
        expect(result.post.title).to eq('Test Post')
      end
    end
    
    context 'with invalid attributes' do
      let(:attributes) { { title: nil } }
      
      it 'returns failure with errors' do
        result = service.call
        
        expect(result).to be_failure
        expect(result.errors).to include('Title can\'t be blank')
      end
    end
  end
end
```

### Service Naming Conventions
- Use verb-noun pattern: `CreatePostService`, `PublishPostService`
- Place in namespaced directories: `publishing/posts/create_post_service.rb`
- One service per file, one responsibility per service
```
