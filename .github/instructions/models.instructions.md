
## ActiveRecord Model Rules

### ID Strategy

- ALWAYS use integer `id` as primary key (bigserial)
- ALWAYS include `public_id` (UUID) column with default: `gen_uuidv7()`
- NEVER expose integer `id` in APIs or serializers
- Use `find_by(public_id:)` for lookups from API requests

### Multi-Tenancy

- Add `acts_as_tenant :account` to all tenant-scoped models
- Include `belongs_to :account` association
- Models in `Core::User`, `Core::Account` are NOT tenant-scoped
- Everything in `Publishing::`, `AiAssistant::`, `Analytics::` IS tenant-scoped

### Validations

- Use Rails validations for business rules
- Validate presence of required associations
- Validate uniqueness within tenant scope: `validates :slug, uniqueness: { scope: :account_id }`
- Use custom validators for complex rules

### Associations

- Use explicit `class_name` for cross-engine associations
- Example: `belongs_to :author, class_name: 'Core::User'`
- Use `dependent: :destroy` or `dependent: :nullify` appropriately
- Always define inverse associations for bidirectional relationships

### Callbacks

- Minimize callbacks; prefer service objects for complex logic
- Use `before_validation` for normalization (slugify, downcase)
- Use `after_commit` for side effects (jobs, events)
- NEVER use `after_save` for external API calls

### Scopes

- Define reusable scopes for common queries
- Examples: `scope :published`, `scope :recent`, `scope :by_author`
- Keep scopes simple; complex queries go in Query objects

### Example Model

```ruby
module Publishing
  class Post < ApplicationRecord
    acts_as_tenant :account
    
    # Associations
    belongs_to :account
    belongs_to :blog
    belongs_to :author, class_name: 'Core::User'
    has_many :taggings, dependent: :destroy
    has_many :tags, through: :taggings
    
    # Validations
    validates :title, presence: true
    validates :slug, presence: true, uniqueness: { scope: [:account_id, :blog_id] }
    validates :status, inclusion: { in: %w[draft published scheduled] }
    
    # Enums
    enum status: { draft: 0, published: 1, scheduled: 2 }
    
    # Scopes
    scope :published, -> { where(status: :published) }
    scope :recent, -> { order(published_at: :desc) }
    
    # Callbacks
    before_validation :generate_slug, if: -> { slug.blank? }
    after_commit :generate_embedding, on: [:create, :update], if: :content_changed?
    
    private
    
    def generate_slug
      self.slug = title.parameterize
    end
    
    def generate_embedding
      AiAssistant::GenerateEmbeddingJob.perform_later(public_id)
    end
  end
end
```

## Common Patterns

### Polymorphic Associations

```ruby
belongs_to :embeddable, polymorphic: true
validates :embeddable_type, inclusion: { in: %w[Publishing::Post Publishing::Draft] }
```

### STI (Single Table Inheritance)

Prefer composition over inheritance. If using STI:
```ruby
class BasePost < ApplicationRecord
  self.abstract_class = true
end

class Post < BasePost
end
```

### JSON/JSONB Columns

```ruby
# Migration
t.jsonb :settings, default: {}, null: false

# Model
store_accessor :settings, :enable_comments, :featured

# Or use typed attributes
attribute :enable_comments, :boolean, default: true
```

## Testing Models

```ruby
RSpec.describe Publishing::Post, type: :model do
  let(:account) { create(:account) }
  let(:blog) { create(:blog, account: account) }
  
  before { ActsAsTenant.current_tenant = account }
  
  describe 'associations' do
    it { should belong_to(:account) }
    it { should belong_to(:blog) }
    it { should have_many(:tags) }
  end
  
  describe 'validations' do
    subject { build(:post, account: account, blog: blog) }
    
    it { should validate_presence_of(:title) }
    it { should validate_uniqueness_of(:slug).scoped_to(:account_id, :blog_id) }
  end
  
  describe 'scopes' do
    it 'returns published posts' do
      published = create(:post, :published, account: account)
      draft = create(:post, :draft, account: account)
      
      expect(described_class.published).to include(published)
      expect(described_class.published).not_to include(draft)
    end
  end
end
```
