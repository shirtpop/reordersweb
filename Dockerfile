# syntax=docker/dockerfile:1

# Define build arguments
ARG RUBY_VERSION=3.4.3
ARG NODE_VERSION=22

FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install system dependencies (including editors for all stages)
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
    libyaml-dev \
    nano \
    vim \
    postgresql-client \
    zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Node.js and Yarn
ARG NODE_VERSION
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    npm install --global yarn && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Production build stage
FROM base AS build

ENV BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    RAILS_ENV=production \
    NODE_ENV=production

# Copy dependency files first for better caching
COPY Gemfile* package.json* yarn.lock* .ruby-version* ./

# Install dependencies
RUN if [ -f "Gemfile" ]; then \
        bundle config set --local deployment 'true' && \
        bundle config set --local without 'development test' && \
        bundle install && \
        rm -rf "${BUNDLE_PATH}/ruby/*/cache" "${BUNDLE_PATH}/ruby/*/bundler/gems/*/.git"; \
    fi

RUN if [ -f "package.json" ]; then \
        yarn install --frozen-lockfile --production; \
    fi

# Copy application code
COPY . .

# Precompile assets and bootsnap
RUN if [ -f "bin/rails" ]; then \
        SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile && \
        bundle exec bootsnap precompile app/ lib/; \
    fi

# Production stage
FROM base AS prod

# Copy built artifacts
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create non-root user for security
RUN groupadd --system --gid 1000 ruby && \
    useradd ruby --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R ruby:ruby db log storage tmp public

USER ruby:ruby

# Set production environment
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development:test"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

ENTRYPOINT ["./bin/docker-entrypoint"]
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

# Development stage
FROM base AS dev

# Copy dependency files
COPY Gemfile* .ruby-version* package.json* yarn.lock* ./

# Install all dependencies (including dev/test)
RUN if [ -f "Gemfile" ]; then bundle install; fi
RUN if [ -f "package.json" ]; then yarn install --check-files; fi

# Create development directories
RUN mkdir -p tmp/pids tmp/cache log

# Set development environment
ENV RAILS_ENV=development \
    BUNDLE_WITHOUT="" \
    BOOTSNAP_CACHE_DIR=/tmp/bootsnap-cache \
    EDITOR=nano

EXPOSE 3000