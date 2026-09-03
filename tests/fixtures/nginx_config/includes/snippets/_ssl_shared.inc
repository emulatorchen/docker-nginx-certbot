# A shared SSL stanza, the way a real deployment factors out repeated config.
# Note it carries NO server_name: that lives in the file which includes this.
ssl_certificate         /etc/letsencrypt/live/my-cert/fullchain.pem;
ssl_certificate_key     /etc/letsencrypt/live/my-cert/privkey.pem;
ssl_trusted_certificate /etc/letsencrypt/live/my-cert/chain.pem;
ssl_dhparam             /etc/letsencrypt/dhparams/dhparam.pem;
