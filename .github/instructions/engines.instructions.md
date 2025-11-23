```instructions
applyTo:
  - "engines/**/*.rb"
  - "engines/**/lib/**/*.rb"

## Rails Engine Rules

### Engine Boundaries
- ✅ **DECIDED**: Use engines for bounded contexts: `core`, `publishing`, `ai_assistant`, `analytics`
- ✅ **DECIDED**: Each engine has its own namespace and models
- ✅ **DECIDED**: Cross-engine communication via service objects only
- 🤔 **UNDECIDED**: Domain events vs. direct service calls vs. pub/sub pattern

### Namespace Isolation
- ALWAYS use proper module namespacing within engines:
  ```ruby
  module Publishing
    class Post < ApplicationRecord
      # Implementation
    end
  end
  ```
- NEVER reference models from other engines directly
- ALWAYS use explicit `class_name` for cross-engine associations

### Engine Communication
- ALWAYS use service objects for cross-engine operations
- NEVER include models from other engines directly
- ALWAYS pass simple data types (not ActiveRecord objects) between engines

### Core Engine (Authentication & Multi-Tenancy)
- Contains: User, Account, AccountMembership, RefreshToken
- Provides authentication and authorization primitives
- NOT tenant-scoped (these are the tenant boundaries)
- ALWAYS use `Core::User` for user references from other engines

### Publishing Engine (Content Management)
- Contains: Blog, Post, Draft, Revision, Tag, Category
- ALL models are tenant-scoped with `acts_as_tenant :account`
- Handles content creation, editing, publishing workflows
- References `Core::User` for authors with `class_name: 'Core::User'`

### AI Assistant Engine (LLM Integration)
- Contains: Embedding, AiRequest, AiResponse
- ALL models are tenant-scoped
- 🤔 **UNDECIDED**: LLM provider abstraction: OpenAI vs. Anthropic vs. multi-provider
- Handles content generation, rewriting, SEO optimization

### Analytics Engine (Metrics & Reporting)
- Contains: PageView, EngagementMetric, Report
- ALL models are tenant-scoped
- Tracks user behavior and content performance
- 🤔 **UNDECIDED**: Real-time vs. batch processing for analytics

### Engine Dependencies
```ruby
# In engine gemspec files:

# core.gemspec - NO dependencies on other engines
spec.add_dependency 'rails'
spec.add_dependency 'bcrypt'
spec.add_dependency 'jwt'

# publishing.gemspec - depends on core
spec.add_dependency 'rails'
spec.add_dependency 'core', path: '../core'

# ai_assistant.gemspec - depends on core and publishing
spec.add_dependency 'rails'
spec.add_dependency 'core', path: '../core'
spec.add_dependency 'publishing', path: '../publishing'

# analytics.gemspec - depends on core and publishing
spec.add_dependency 'rails'
spec.add_dependency 'core', path: '../core'
spec.add_dependency 'publishing', path: '../publishing'
```

### Service Object Patterns for Cross-Engine Communication
```ruby
# Good: Service in ai_assistant engine calling publishing
module AiAssistant
  module Content
    class RewritePostService < ApplicationService
      def initialize(post_public_id:, style:, account:)
        @post_public_id = post_public_id
        @style = style
        @account = account
      end
      
      def call
        # Fetch post via service, not direct model access
        post_result = Publishing::Posts::FindPostService.new(
          public_id: post_public_id,
          account: account
        ).call
        
        return failure(errors: 'Post not found') unless post_result.success?
        
        # Process the post content
        rewrite_content(post_result.post)
      end
      
      private
      
      attr_reader :post_public_id, :style, :account
      
      def rewrite_content(post_data)
        # AI processing logic here
      end
    end
  end
end
```

### Engine Configuration
```ruby
# engines/publishing/lib/publishing/engine.rb
module Publishing
  class Engine < ::Rails::Engine
    isolate_namespace Publishing
    
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
    end
    
    # Engine-specific initializers
    initializer "publishing.acts_as_tenant" do
      ActiveSupport.on_load(:active_record) do
        extend ActsAsTenant
      end
    end
  end
end
```

### Testing Engine Isolation
- ALWAYS test engines in isolation
- Use engine-specific test setup
- Mock cross-engine dependencies in tests
- NEVER load other engines' models in engine tests

### Migration Strategies
- Each engine manages its own migrations
- Use engine-specific migration paths
- 🤔 **UNDECIDED**: Shared migrations vs. engine-specific vs. both

### Engine Development Workflow
- Start features in the appropriate engine
- Keep business logic within engine boundaries
- Use main app only for routing and global configuration
- Extract common functionality to shared concerns
```
