import http.server
import ssl
import os

os.chdir('build/web')

server_address = ('0.0.0.0', 5000)
httpd = http.server.HTTPServer(server_address, http.server.SimpleHTTPRequestHandler)

# Create SSL context
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile='../../cert.crt', keyfile='../../cert.pfx')

httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

print(f'Serving HTTPS on {server_address[0]}:{server_address[1]}')
print('Note: You will need to accept the self-signed certificate warning in your browser')
httpd.serve_forever()
