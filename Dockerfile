FROM ubuntu:22.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Устанавливаем зависимости
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        python3 \
    && rm -rf /var/lib/apt/lists/*

# Копируем deb пакет и устанавливаем
COPY dist/*.deb /tmp/

RUN set -eux; \
    deb_file="$(ls /tmp/*.deb | head -n 1)"; \
    test -n "${deb_file}"; \
    echo "Installing deb package: ${deb_file}"; \
    dpkg -i "${deb_file}" || apt-get install -y -f; \
    rm -rf /var/lib/apt/lists/* /tmp/*.deb

# Проверяем, что бинарник установился
RUN ls -la /usr/bin/ | grep -E "(matrix|latin-square)" || echo "Binary not found"

# Копируем HTTP сервер
COPY server.py /usr/bin/server.py
RUN chmod +x /usr/bin/server.py

EXPOSE 8080 9090

# Запускаем HTTP сервер
CMD ["python3", "/usr/bin/server.py"]