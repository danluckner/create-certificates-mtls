# Create Certificate Bash Script

Bash script with the intent to facilitate the creation of self-signed certificates for mTLS implementation.

The script creates the Server Certificates and the Client Certificates.

The Server Certificate should be uploaded to your reverse proxy server (NGINX or Traefik).

The Client Certificate should be uploaded and installed to your devices.

The script is free to use, reuse, copy, change, redistribute as you see fit, totally free.

Corrections and comments are also welcome.

To run the script, in your Linux instace, download to a folder with:

`wget https://github.com/danluckner/create-certificates-mtls/blob/main/createcertificates.sh`

Then, in the same folder, run the script with:

`sudo bash ./createcertificates.sh`

## References
The inspiration for this script came from this video: https://www.youtube.com/watch?v=8DWcMbgQSZg
