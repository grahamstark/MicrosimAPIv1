try
  Genie.Util.isprecompiling() || Genie.Secrets.secret_token!("03f24f6c613dd77a1840fc6cb034204870ff32c731b6e7a071d7273601a814b0")
catch ex
  @error "Failed to generate secrets file: $ex"
end
