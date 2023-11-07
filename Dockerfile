
# Versions
ARG REDIS_STACK_IMAGE=redis/redis-stack-server:7.2.0-v6

# --------
# Builder
# --------
FROM ubuntu:22.04 as coord-build

ARG VERSION=v2.8.9
# Install dependencies
RUN apt-get update && apt-get install git python3 python3-pip -y

# Build Redisearch
RUN git clone https://github.com/RediSearch/RediSearch.git && \
    cd RediSearch && \
    git checkout "${VERSION}" && \
    git config --global --add safe.directory '*' && \
    git submodule update --init --recursive && \
    ./deps/readies/bin/getupdates && \
    ./sbin/setup && \
    ./deps/readies/bin/getredis && \
    make && \
    make COORD=1

# --------
# Redis Stack patch
# --------
FROM $REDIS_STACK_IMAGE

# Copy coord
COPY --from=coord-build /RediSearch/bin/linux-x64-release/coord-oss/module-oss.so /opt/redis-stack/lib/module-oss.so

RUN chown nobody:127 /opt/redis-stack/lib/module-oss.so

RUN sed -i \
    's|--loadmodule /opt/redis-stack/lib/redisearch.so ${REDISEARCH_ARGS} \\|\
--loadmodule /opt/redis-stack/lib/module-oss.so ${REDISEARCH_ARGS} \\|g' \
    /entrypoint.sh
