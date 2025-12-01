# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Draft, type: :model) do
  describe "validations" do
    subject { create(:draft) }

    it { is_expected.to(validate_length_of(:title).is_at_most(255)) }
  end

  describe "associations" do
    it { is_expected.to(belong_to(:account)) }
    it { is_expected.to(belong_to(:blog)) }
    it { is_expected.to(belong_to(:author).class_name("User")) }
    it { is_expected.to(belong_to(:post).optional) }
    it { is_expected.to(have_many(:taggings).dependent(:destroy)) }
    it { is_expected.to(have_many(:tags).through(:taggings)) }
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:blog) { create(:blog, account: account) }
    let(:author) { create(:user) }

    describe ".ordered" do
      let!(:older_draft) { create(:draft, account: account, blog: blog, author: author, updated_at: 1.day.ago) }
      let!(:newer_draft) { create(:draft, account: account, blog: blog, author: author, updated_at: Time.current) }

      it "returns drafts ordered by updated_at desc" do
        expect(described_class.ordered.first).to(eq(newer_draft))
      end
    end

    describe ".recent" do
      let!(:recent_draft) { create(:draft, account: account, blog: blog, author: author, updated_at: 1.hour.ago) }
      let!(:old_draft) { create(:draft, account: account, blog: blog, author: author, updated_at: 2.days.ago) }

      it "returns only drafts updated within the last 24 hours" do
        expect(described_class.recent).to(include(recent_draft))
        expect(described_class.recent).not_to(include(old_draft))
      end
    end

    describe ".by_author" do
      let(:other_author) { create(:user) }
      let!(:author_draft) { create(:draft, account: account, blog: blog, author: author) }
      let!(:other_draft) { create(:draft, account: account, blog: blog, author: other_author) }

      it "returns only drafts by the specified author" do
        expect(described_class.by_author(author.id)).to(include(author_draft))
        expect(described_class.by_author(author.id)).not_to(include(other_draft))
      end
    end
  end

  describe "instance methods" do
    let(:account) { create(:account) }
    let(:blog) { create(:blog, account: account) }
    let(:author) { create(:user) }

    describe "#autosave!" do
      let(:draft) { create(:draft, account: account, blog: blog, author: author) }

      it "updates content and autosaved_at" do
        draft.autosave!(content: "New content", title: "New title")
        draft.reload

        expect(draft.content).to(eq("New content"))
        expect(draft.title).to(eq("New title"))
        expect(draft.autosaved_at).to(be_present)
      end

      it "preserves existing title if not provided" do
        original_title = draft.title
        draft.autosave!(content: "New content")
        draft.reload

        expect(draft.title).to(eq(original_title))
      end
    end

    describe "#convert_to_post!" do
      let(:draft) { create(:draft, account: account, blog: blog, author: author, title: "Draft Title", content: "Draft content") }

      it "creates a new post from the draft" do
        expect { draft.convert_to_post! }.to(change(Post, :count).by(1))
      end

      it "deletes the draft after conversion" do
        expect { draft.convert_to_post! }.to(change(Draft, :count).by(-1))
      end

      it "returns nil if title is blank" do
        draft.update!(title: nil)
        expect(draft.convert_to_post!).to(be_nil)
      end

      it "returns nil if content is blank" do
        draft.update!(content: nil)
        expect(draft.convert_to_post!).to(be_nil)
      end
    end

    describe "#word_count" do
      it "returns the word count of the content" do
        draft = build(:draft, content: "This is a five word sentence")
        expect(draft.word_count).to(eq(6))
      end

      it "returns 0 if content is blank" do
        draft = build(:draft, content: nil)
        expect(draft.word_count).to(eq(0))
      end

      it "strips HTML tags when counting words" do
        draft = build(:draft, content: "<p>Hello <strong>World</strong></p>")
        expect(draft.word_count).to(eq(2))
      end
    end

    describe "#last_saved" do
      it "returns autosaved_at if present" do
        autosaved_time = 1.hour.ago
        draft = build(:draft, autosaved_at: autosaved_time)
        expect(draft.last_saved).to(eq(autosaved_time))
      end

      it "returns updated_at if autosaved_at is nil" do
        draft = create(:draft, account: account, blog: blog, author: author, autosaved_at: nil)
        expect(draft.last_saved).to(eq(draft.updated_at))
      end
    end
  end
end
