# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is optimized for OrbStack development with Rails 8 API
# Build: docker build -t baas .
# Run: docker compose up

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.4
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages (added libvips for image processing)
# Need PostgreSQL 16 client to match database server version
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl gnupg lsb-release && \
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y libjemalloc2 libvips postgresql-client-16 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Create a non-root user to run the app
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

# Set development environment for OrbStack
ENV RAILS_ENV="development" \
    BUNDLE_DEPLOYMENT="0" \
    BUNDLE_PATH="/home/rails/bundle" \
    BUNDLE_WITHOUT=""

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config libyaml-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Create bundle directory
RUN mkdir -p /home/rails/bundle

# Copy application code and gems
COPY . .
RUN chown -R rails:rails /rails /home/rails/bundle

# Switch to non-root user
USER 1000:1000

# Install application gems
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build --chown=1000:1000 "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build --chown=1000:1000 /rails /rails

# Run and own only the runtime files as a non-root user for security
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
