FROM debian:12-slim
RUN apt-get update && \
    apt-get install --no-install-recommends python3-pip -y && \
    apt-get clean

RUN pip install --no-cache-dir --break-system-packages awslogs awscli

COPY docker-entrypoint.sh /entrypoint
RUN chmod +x /entrypoint

CMD ["/entrypoint"]
