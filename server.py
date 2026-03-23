#!/usr/bin/env python3
import subprocess
import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading

# Метрики
requests_total = 0
valid_total = 0
invalid_total = 0
lock = threading.Lock()

class LatinSquareHandler(BaseHTTPRequestHandler):
    
    def do_POST(self):
        global requests_total, valid_total, invalid_total
        
        if self.path == '/check':
            try:
                content_length = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_length)
                
                # Запускаем программу matrix (она установлена в /usr/bin/matrix)
                result = subprocess.run(
                    ['/usr/bin/matrix'],
                    input=post_data,
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                # Обновляем метрики
                with lock:
                    requests_total += 1
                    if "является латинским квадратом" in result.stdout:
                        valid_total += 1
                    else:
                        invalid_total += 1
                
                self.send_response(200)
                self.send_header('Content-Type', 'text/plain; charset=utf-8')
                self.end_headers()
                self.wfile.write(result.stdout.encode())
                
            except subprocess.TimeoutExpired:
                self.send_response(504)
                self.end_headers()
                self.wfile.write(b'Timeout')
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(str(e).encode())
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not found')
    
    def do_GET(self):
        if self.path == '/health' or self.path == '/ready':
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'OK')
        elif self.path == '/metrics':
            with lock:
                metrics = f'''# HELP latin_square_requests_total Total number of requests
# TYPE latin_square_requests_total counter
latin_square_requests_total {requests_total}
# HELP latin_square_valid_total Number of valid Latin squares
# TYPE latin_square_valid_total counter
latin_square_valid_total {valid_total}
# HELP latin_square_invalid_total Number of invalid Latin squares
# TYPE latin_square_invalid_total counter
latin_square_invalid_total {invalid_total}
'''
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain; version=0.0.4')
            self.end_headers()
            self.wfile.write(metrics.encode())
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not found')
    
    def log_message(self, format, *args):
        # Отключаем логи для чистоты
        pass

if __name__ == '__main__':
    port = int(os.environ.get('HTTP_PORT', 8080))
    server = HTTPServer(('0.0.0.0', port), LatinSquareHandler)
    print(f'Starting Latin Square HTTP server on port {port}')
    print(f'Health check: http://localhost:{port}/health')
    print(f'Metrics: http://localhost:{port}/metrics')
    print(f'Check endpoint: POST http://localhost:{port}/check')
    server.serve_forever()