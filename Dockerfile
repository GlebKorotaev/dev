FROM ubuntu:22.04

# Устанавливаем Python
RUN apt-get update && apt-get install -y \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Копируем matrix из папки out
COPY out/matrix /usr/bin/matrix
RUN chmod +x /usr/bin/matrix

# Копируем HTTP сервер
COPY server.py /usr/bin/server.py
RUN chmod +x /usr/bin/server.py

# Проверяем наличие файлов
RUN ls -la /usr/bin/matrix /usr/bin/server.py

EXPOSE 8080

CMD ["python3", "/usr/bin/server.py"]