#!/usr/bin/env python3
import subprocess
import os
from http.server import HTTPServer, BaseHTTPRequestHandler

class LatinSquareHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/check':
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            
            try:
                result = subprocess.run(
                    ['/usr/bin/matrix'],
                    input=post_data,
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                self.send_response(200)
                self.send_header('Content-Type', 'text/plain; charset=utf-8')
                self.end_headers()
                self.wfile.write(result.stdout.encode())
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(str(e).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_GET(self):
        if self.path == '/health' or self.path == '/ready':
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'OK')
        elif self.path == '/metrics':
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'latin_square_requests_total 0\n')
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    port = int(os.environ.get('HTTP_PORT', 8080))
    server = HTTPServer(('0.0.0.0', port), LatinSquareHandler)
    print(f'Starting Latin Square HTTP server on port {port}')
    server.serve_forever()