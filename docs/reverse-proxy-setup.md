# Reverse Proxy Setup For Public Access

This guide shows the simplest way to expose SPPPBA through a public domain or public IP while keeping Tomcat behind a reverse proxy.

## Goal

- Users open the system from a public domain or public IP.
- Nginx or Apache listens on port 80/443.
- Tomcat stays on an internal port such as 8081.
- The app generates email links using the public address, not localhost or a private LAN IP.

## Recommended Layout

- Public DNS name: `spppba.example.gov.my`
- Reverse proxy: Nginx or Apache on the public server
- Tomcat: `127.0.0.1:8081` or internal-only port
- App context path: `/sistemppa`

## App Setting

Keep `app.base.url` aligned with the public address you want to advertise in emails.

In `WEB-INF/web.xml`, set:

```xml
<context-param>
    <param-name>app.base.url</param-name>
    <param-value>https://spppba.example.gov.my/sistemppa</param-value>
</context-param>
```

If you use a reverse proxy, also send forwarded headers. The app now reads those headers and prefers the public host when present.

## Nginx Example

```nginx
server {
    listen 80;
    server_name spppba.example.gov.my;

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name spppba.example.gov.my;

    ssl_certificate     /etc/letsencrypt/live/spppba.example.gov.my/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/spppba.example.gov.my/privkey.pem;

    location /sistemppa/ {
        proxy_pass http://127.0.0.1:8081/sistemppa/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Apache Example

Enable the proxy modules first, then use a vhost like this:

```apache
<VirtualHost *:80>
    ServerName spppba.example.gov.my
    Redirect permanent / https://spppba.example.gov.my/
</VirtualHost>

<VirtualHost *:443>
    ServerName spppba.example.gov.my

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/spppba.example.gov.my/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/spppba.example.gov.my/privkey.pem

    ProxyPreserveHost On
    ProxyPass /sistemppa/ http://127.0.0.1:8081/sistemppa/
    ProxyPassReverse /sistemppa/ http://127.0.0.1:8081/sistemppa/

    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Forwarded-Port "443"
</VirtualHost>
```

## Firewall And Network

If users are on the internet, make sure:

- Port 80 and 443 are open on the public server.
- Tomcat port 8081 is not exposed publicly unless you explicitly want it public.
- DNS for the domain points to the reverse proxy public IP.

## What Changed In The App

- The app now resolves public base URLs from forwarded proxy headers when available.
- Director email links use the public host exposed by the proxy instead of the backend Tomcat host.
- Registration verification links and KPP guest links use the same shared URL resolver.

## Practical Rule

Use this setup if you want links to work across devices and from outside the office network:

- Public domain + reverse proxy = best option for internet access.
- Private IP only = only works inside the same LAN/VPN.
