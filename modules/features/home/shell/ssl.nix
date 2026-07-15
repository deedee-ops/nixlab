_: {
  flake.homeModules.features-home-ssl = _: {
    config = {
      home = {
        sessionVariables = {
          # ssl shenanigans in various frameworks and libraries
          CURL_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
          NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
          REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
          SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
        };
      };
    };
  };
}
