# 🏗️ baas — GitHub Copilot Instructions

**Backend API for an AI-powered blogging platform using Rails 8 + Hexagonal Architecture + Multi-Tenancy**

---

## 🎯 **Core Architectural Decisions (DECIDED)**

### **Framework & Structure**
- ✅ **Rails 8 API-only** mode
- ✅ **Hexagonal Architecture** with clear layer separation
- ✅ **Rails Engines** for bounded contexts (`core/`, `publishing/`, `ai_assistant/`, `analytics/`)
- ✅ **JSON:API v1.1** specification for all endpoints
- ✅ **PostgreSQL** with **pgvector** extension

### **Authentication & Authorization**
- ✅ **JWT tokens** with **refresh token rotation**
- ✅ **Pundit** for authorization policies
- ✅ **BCrypt** for password encryption

### **Multi-Tenancy**
- ✅ **Row-level tenancy** with `acts_as_tenant :account`
- ✅ **Account model** as tenant boundary
- ✅ **User can belong to multiple accounts** via `AccountMembership`

### **ID Strategy**
- ✅ **Integer PKs** (`bigserial`) for database performance
- ✅ **UUIDv7 public_ids** for API security (never expose integer IDs)
- ✅ **gen_uuidv7()** database function for UUID generation

---

## ⚠️ **Pending Decisions (UNDECIDED)**

### **Database & Infrastructure**
- 🤔 **Connection Pooling**: PgBouncer vs. built-in Rails pool vs. PgCat
- 🤔 **Caching Strategy**: Redis-only vs. Rails.cache multi-layer vs. Memcached
- 🤔 **Search Implementation**: Full-text search vs. PostgreSQL vs. Elasticsearch vs. Typesense
- 🤔 **File Storage**: AWS S3 vs. CloudFlare R2 vs. Google Cloud Storage

### **Background Jobs**
- 🤔 **Job Queue**: Sidekiq vs. Solid Queue vs. GoodJob vs. DelayedJob
- 🤔 **Scheduler**: sidekiq-cron vs. whenever vs. clockwork

### **AI Integration**
- 🤔 **LLM Provider**: OpenAI vs. Anthropic vs. Local (Ollama) vs. Multi-provider
- 🤔 **Embedding Strategy**: OpenAI embeddings vs. local models vs. Voyage AI

### **API Documentation**
- 🤔 **Documentation Tool**: rswag vs. grape-swagger vs. custom OpenAPI

### **Testing Strategy**
- 🤔 **HTTP Testing**: RSpec request specs vs. integration tests vs. Capybara
- 🤔 **Factory Strategy**: FactoryBot vs. fixtures vs. fabrication

### **Development Workflow**
- 🤔 **Code Quality**: RuboCop-only vs. StandardRB vs. RuboCop + custom rules
- 🤔 **Security**: Brakeman vs. bundler-audit vs. both

---

## 📋 **Mandatory Coding Patterns**

### **Model Layer**
```ruby
# ALWAYS use this pattern for models:
module Publishing
  class Post < ApplicationRecord
    acts_as_tenant :account
    
    # Associations first
    belongs_to :account
    belongs_to :blog
    belongs_to :author, class_name: 'Core::User'
    
    # Validations second
    validates :title, presence: true
    validates :slug, uniqueness: { scope: :account_id }
    
    # Enums third
    enum status: { draft: 0, published: 1, scheduled: 2 }
    
    # Scopes fourth
    scope :published, -> { where(status: :published) }
    
    # Methods last
    def published?
      status == 'published' && published_at&.past?
    end
  end
end
```

### **Controller Layer**
```ruby
# ALWAYS use this pattern for controllers:
module Api
  module V1
    class PostsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_post, only: [:show, :update, :destroy]
      
      def index
        @posts = authorize_collection(Post.all)
        render jsonapi: @posts, include: params[:include]
      end
      
      def show
        render jsonapi: @post, include: params[:include]
      end
      
      private
      
      def set_post
        @post = Post.find_by!(public_id: params[:id])
        authorize @post
      end
      
      def post_params
        params.require(:data).require(:attributes).permit(:title, :content)
      end
    end
  end
end
```

### **Service Layer**
```ruby
# ALWAYS use this pattern for services:
module Publishing
  module Posts
    class CreatePostService < ApplicationService
      def initialize(account:, user:, attributes:)
        @account = account
        @user = user
        @attributes = attributes
      end
      
      def call
        return failure(errors: 'Invalid attributes') unless valid?
        
        post = create_post
        return failure(errors: post.errors) unless post.persisted?
        
        success(post: post)
      end
      
      private
      
      attr_reader :account, :user, :attributes
      
      def valid?
        # Validation logic
      end
      
      def create_post
        account.posts.create(attributes.merge(author: user))
      end
    end
  end
end
```

---

## 🚫 **Code Constraints**

### **NEVER Do These:**
- ❌ Never expose integer `id` in APIs or serializers
- ❌ Never bypass tenant scoping with `unscoped` unless explicitly required
- ❌ Never put business logic in controllers (use services)
- ❌ Never use `after_save` callbacks for external API calls
- ❌ Never hardcode tenant/account references
- ❌ Never use `find()` with integer IDs in controllers (use `find_by(public_id:)`)

### **ALWAYS Do These:**
- ✅ Always authorize every controller action with Pundit
- ✅ Always use `public_id` for external references
- ✅ Always wrap database operations in transactions for multi-step operations
- ✅ Always add database indexes for query performance
- ✅ Always validate uniqueness within tenant scope
- ✅ Always use service objects for complex business logic

---

## 🧩 **Rails Engine Boundaries**

```
engines/
├── core/                    # User, Account, Auth (✅ DECIDED)
├── publishing/              # Blog, Post, Draft, Tag (✅ DECIDED)
├── ai_assistant/            # LLM, Embedding, Generation (✅ DECIDED)
└── analytics/               # Metrics, Views, Reports (✅ DECIDED)
```

### **Engine Communication Rules**
- ✅ **Decided**: Engines communicate via service objects
- ✅ **Decided**: No direct model references across engines (use explicit `class_name`)
- 🤔 **Undecided**: Domain events vs. direct service calls vs. pub/sub pattern

---

## 📊 **Database Patterns**

### **Required Schema Conventions**
```ruby
# ALWAYS include these columns:
t.bigserial :id, primary_key: true        # Integer PK
t.uuid :public_id, null: false, default: 'gen_uuidv7()' # Public UUID
t.bigint :account_id, null: false         # Tenant FK (if tenant-scoped)
t.timestamps                              # created_at, updated_at

# ALWAYS add these indexes:
add_index :table_name, :public_id, unique: true
add_index :table_name, :account_id        # If tenant-scoped
```

### **Tenant Scoping**
```ruby
# Models that ARE tenant-scoped:
Publishing::Blog, Publishing::Post, Publishing::Draft
AiAssistant::Embedding, Analytics::PageView

# Models that are NOT tenant-scoped:
Core::User, Core::Account, Core::RefreshToken
```

---

## 🔐 **Security Requirements**

### **Authentication Flow**
- ✅ **Decided**: JWT access tokens (15 min expiry) + refresh tokens (30 days)
- ✅ **Decided**: Automatic token rotation on refresh
- ✅ **Decided**: Device-based refresh token storage

### **Authorization Context**
```ruby
# ALWAYS use this authorization pattern:
def authorize_collection(scope)
  policy_scope(scope.where(account: current_account))
end

def authorize_record(record)
  authorize record, policy_class: "#{record.class}Policy"
end
```

---

## 🧪 **Testing Requirements**

### **Test Structure** (✅ DECIDED)
```ruby
# ALWAYS follow this RSpec structure:
RSpec.describe Publishing::Posts::CreatePostService do
  describe '#call' do
    context 'with valid attributes' do
      it 'creates a post' do
        # Arrange
        account = create(:account)
        user = create(:user, account: account)
        
        # Act
        result = described_class.new(
          account: account,
          user: user,
          attributes: { title: 'Test' }
        ).call
        
        # Assert
        expect(result).to be_success
        expect(result.post).to be_persisted
      end
    end
  end
end
```

### **Factory Pattern** (✅ DECIDED)
- Use FactoryBot with tenant-aware factories
- Always create with proper `account` association

---

## 📝 **Code Style**

### **File Naming**
- ✅ **Controllers**: `api/v1/posts_controller.rb`
- ✅ **Services**: `publishing/posts/create_post_service.rb`
- ✅ **Policies**: `publishing/post_policy.rb`
- ✅ **Serializers**: `api/v1/post_serializer.rb`

### **Module Namespacing**
```ruby
# ALWAYS use explicit module namespacing:
module Api
  module V1
    class PostsController < ApplicationController
      # Implementation
    end
  end
end
```

---

## 📖 **Documentation Standards**

- ✅ **OpenAPI 3.1** for all endpoints
- ✅ **Inline code comments** for complex business logic
- ✅ **README** for each Rails engine
- 🤔 **YARD docs**: Yes vs. No vs. Selective documentation

When implementing features, always check if there are pending decisions that affect your implementation and note them in your code or ask for clarification.