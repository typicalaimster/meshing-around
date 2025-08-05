# Build stage - includes build tools
FROM python:3.13-slim as builder
ENV PYTHONUNBUFFERED=1

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    build-essential \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python packages
COPY requirements.txt /tmp/requirements.txt
RUN pip install --user -r /tmp/requirements.txt

# Runtime stage - minimal dependencies only
FROM python:3.13-slim
ENV PYTHONUNBUFFERED=1

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    gettext \
    tzdata \
    locales \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Set the locale default to en_US.UTF-8
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG="en_US.UTF-8"
ENV TZ="America/Los_Angeles"

# Copy Python packages from builder stage
COPY --from=builder /root/.local /root/.local

# Make sure Python can find the packages
ENV PATH=/root/.local/bin:$PATH

WORKDIR /app
COPY . /app
COPY config.template /app/config.ini

RUN chmod +x /app/script/docker/entrypoint.sh

ENTRYPOINT ["/bin/bash", "/app/script/docker/entrypoint.sh"]
