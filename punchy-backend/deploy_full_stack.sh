#!/bin/bash
set -e

echo "=== 1. Updating backend index.ts ==="
cp /tmp/index.ts /var/www/punchy-backend/src/index.ts
sudo systemctl restart punchy-backend

echo "=== 2. Setting up /var/www/punchy-admin ==="
sudo mkdir -p /var/www/punchy-admin
sudo chown -R opc:opc /var/www/punchy-admin
tar -zxvf /tmp/punchy-admin.tar.gz -C /var/www/punchy-admin/
cd /var/www/punchy-admin
npm install --omit=dev

echo "=== 3. Creating punchy-admin.service ==="
sudo tee /etc/systemd/system/punchy-admin.service > /dev/null << 'EOF'
[Unit]
Description=Punchy Admin & Homepage Next.js Web Application
After=network.target punchy-backend.service

[Service]
Type=simple
User=opc
WorkingDirectory=/var/www/punchy-admin
Environment="PORT=5000"
Environment="NODE_ENV=production"
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/local/bin/node /var/www/punchy-admin/node_modules/next/dist/bin/next start -p 5000
Restart=always
RestartSec=3
LimitNOFILE=64000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable punchy-admin
sudo systemctl restart punchy-admin

echo "=== 4. Updating Caddyfile for Unified Website + API ==="
sudo tee /etc/caddy/Caddyfile > /dev/null << 'EOF'
www.sufidistribution.com {
	redir https://sufidistribution.com{uri} permanent
}

sufidistribution.com {
	encode zstd gzip
	reverse_proxy 127.0.0.1:3000
	header {
		Strict-Transport-Security "max-age=31536000; includeSubDomains"
		X-Content-Type-Options nosniff
		Referrer-Policy strict-origin-when-cross-origin
		-Server
	}
	log {
		output stdout
		format console
	}
}

http://129.154.252.220 {
	# API routes to Express Backend
	@api {
		path /api /api/* /health
	}
	handle @api {
		reverse_proxy 127.0.0.1:4000
	}

	# All other pages, assets, and admin portal to Next.js Frontend
	handle {
		reverse_proxy 127.0.0.1:5000
	}
}
EOF

sudo systemctl reload caddy || sudo systemctl restart caddy
sleep 4
echo "=== Services Status ==="
sudo systemctl status punchy-admin punchy-backend caddy --no-pager
