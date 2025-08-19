# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.3
ARG NODE_VERSION=22

# Builder stage (dependencies + asset compilation)
FROM ruby:$RUBY_VERSION-slim AS builder

# Install build dependencies
RUN apt-get update -qq && apt-get install --no-install-recommends -y \
    build-essential \
    curl \
    git \
    gnupg2 \
    libjemalloc2 \
    libffi-dev \
    libgmp-dev \
    libpq-dev \
    libreadline-dev \
    libssl-dev \
    libvips \
    libxml2-dev \
    libxslt1-dev \
    nodejs \
    npm \
    libyaml-dev \
    zlib1g-dev \
    g++ \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Yarn
RUN npm install --global yarn

WORKDIR /rails

# Install dependencies
COPY Gemfile* package.json* yarn.lock* .ruby-version* ./
RUN bundle config set --local deployment 'true' \
    && bundle config set --local without 'development test' \
    && bundle install --jobs 4 --retry 3 \
    && rm -rf /usr/local/bundle/cache/*.gem \
    && yarn install --frozen-lockfile --production

# Copy application code
COPY . .

# Precompile assets
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile \
    && bundle exec bootsnap precompile app/ lib/

# Production stage
FROM ruby:$RUBY_VERSION-slim AS prod

# Install runtime dependencies
RUN apt-get update -qq && apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add wait-for-it
RUN curl -o /usr/local/bin/wait-for-it \
    https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    && chmod +x /usr/local/bin/wait-for-it

WORKDIR /rails

# Copy built artifacts
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails \
    && useradd --system --uid 1000 --gid rails rails \
    && chown -R rails:rails db log storage tmp public

USER rails:rails

# Environment variables
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH="/usr/local/bundle" \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=true

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/up || exit 1

# Entrypoint and command
ENTRYPOINT ["./bin/docker-entrypoint"]
CMD ["./bin/rails", "server"]

# Development stage
FROM builder AS dev

# Set development environment
ENV RAILS_ENV=development \
    BUNDLE_WITHOUT="" \
    BOOTSNAP_CACHE_DIR=/tmp/bootsnap-cache \
    EDITOR=nano

# Create development directories
RUN mkdir -p tmp/pids tmp/cache log

EXPOSE 3000