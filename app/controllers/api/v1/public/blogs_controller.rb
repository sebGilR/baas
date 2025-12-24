# frozen_string_literal: true

module Api
  module V1
    module Public
      class BlogsController < BaseController
        def show
          blog = find_blog!
          render_jsonapi(blog, serializer: Api::V1::PublicBlogSerializer)
        end

        private

        def find_blog!
          Blog.active.find_by!(slug: params[:slug])
        end
      end
    end
  end
end
