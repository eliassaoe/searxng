FROM searxng/searxng:latest

# Install Tor and other necessary packages
USER root
RUN apt-get update && \
    apt-get install -y tor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create Tor config directory
RUN mkdir -p /etc/tor

# Add Tor configuration
RUN echo "SocksPort 0.0.0.0:9050" > /etc/tor/torrc && \
    echo "DNSPort 0.0.0.0:5353" >> /etc/tor/torrc

# Create startup script
RUN echo '#!/bin/bash\n\
# Start Tor in background\n\
tor -f /etc/tor/torrc &\n\
\n\
# Wait for Tor to start\n\
sleep 5\n\
\n\
# Configure SearXNG to use Tor\n\
sed -i "s/http: \"\"/http: socks5h:\/\/localhost:9050/g" /etc/searxng/settings.yml\n\
sed -i "s/https: \"\"/https: socks5h:\/\/localhost:9050/g" /etc/searxng/settings.yml\n\
sed -i "s/request_timeout : 2.0/request_timeout : 10.0/g" /etc/searxng/settings.yml\n\
\n\
# Start SearXNG\n\
exec /usr/local/bin/uwsgi --master --http-socket :8080 --mount /searx=/usr/local/searxng/searx/webapp.py\n\
' > /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh

# Expose SearXNG port
EXPOSE 8080

# Set environment variables
ENV INSTANCE_NAME="SearXNG via Tor"
ENV BASE_URL="https://your-render-url"
ENV ENABLE_METRICS="false"

# Switch back to non-root user for security
USER searxng

# Run the startup script
CMD ["/usr/local/bin/start.sh"]
