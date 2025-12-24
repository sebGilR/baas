# frozen_string_literal: true

module Api
  module V1
    module Public
      class PostsController < BaseController
        def index
          blog = find_blog!
          posts = paginate(blog.posts.published.by_published_date.includes(:tags, :category))

          render_jsonapi(
            posts,
            serializer: Api::V1::PublicPostSerializer,
            meta: pagination_meta(posts),
            links: pagination_links(posts),
            params: { blog: blog },
          )
        end

        def show
          blog = find_blog!
          post = blog.posts.published.includes(:tags, :category).find_by!(slug: params[:slug])
          render_jsonapi(post, serializer: Api::V1::PublicPostSerializer, params: { blog: blog })
        end

        private

        def find_blog!
          slug = params[:blog_slug]
          Blog.active.find_by!(slug: slug)
        end
      end
    end
  end
end
