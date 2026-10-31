_: {
  hosts.claude = {
    deployHostname = "claude.internal";
    # wheel has passwordless sudo on this host
    interactiveSudo = false;
  };
}
