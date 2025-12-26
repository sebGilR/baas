# frozen_string_literal: true

require "net/http"

class FrontendRevalidateJob < ApplicationJob
  queue_as :default

  def perform(tags: [], paths: [])
    url = ENV["VERCEL_REVALIDATE_URL"]
    token = ENV["VERCEL_REVALIDATE_TOKEN"]

    return if url.blank? || token.blank?

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 2
    http.read_timeout = 5

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["X-Revalidate-Token"] = token
    request.body = { tags: Array(tags), paths: Array(paths) }.to_json

    response = http.request(request)
    Rails.logger.info("Frontend revalidate: #{response.code} #{response.body}")
  rescue StandardError => e
    Rails.logger.warn("Frontend revalidate failed: #{e.class}: #{e.message}")
  end
end
