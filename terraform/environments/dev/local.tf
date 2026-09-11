locals {
  frontend_user_data = <<-EOF
    #!/bin/bash

    apt-get update
    apt-get install -y nginx

    systemctl enable nginx
    systemctl start nginx

    echo "<h1>Frontend Tier</h1>" > /var/www/html/index.html
  EOF

  backend_user_data = <<-EOF
  #!/bin/bash

  apt-get update
  apt-get install -y python3

  mkdir -p /opt/backend

  cat > /opt/backend/server.py <<'PYTHON'
  from http.server import BaseHTTPRequestHandler, HTTPServer

  class Handler(BaseHTTPRequestHandler):
      def do_GET(self):
          if self.path == "/health":
              self.send_response(200)
              self.end_headers()
              self.wfile.write(b"healthy")
          else:
              self.send_response(200)
              self.end_headers()
              self.wfile.write(b"Backend Tier")

  HTTPServer(("0.0.0.0", 3000), Handler).serve_forever()
  PYTHON

  cat > /etc/systemd/system/backend-test.service <<'SERVICE'
  [Unit]
  Description=Temporary Backend Test Service
  After=network.target

  [Service]
  ExecStart=/usr/bin/python3 /opt/backend/server.py
  Restart=always

  [Install]
  WantedBy=multi-user.target
  SERVICE

  systemctl daemon-reload
  systemctl enable backend-test
  systemctl start backend-test
EOF
}
