class Memcap < Formula
  desc "Keep AI coding agents inside a RAM budget on macOS"
  homepage "https://github.com/alextitov19/memcap"
  url "https://github.com/alextitov19/memcap/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "859b02ea047b9a5ea47ed91e10b9ef72e71fbe83643932775048d9a841deef7f"
  license "MIT"

  depends_on :macos
  depends_on "jq"

  def install
    libexec.install Dir["libexec/*"]
    (bin/"memcap").write <<~SH
      #!/usr/bin/env bash
      MEMCAP_ROOT="#{prefix}" exec "#{prefix}/bin/memcap-real" "$@"
    SH
    (prefix/"bin").install "bin/memcap" => "memcap-real"
    chmod 0755, bin/"memcap"
  end

  # No `service do` block on purpose: a Homebrew-managed service writes
  # homebrew.mxcl.memcap.plist, which `brew upgrade` removes -- leaving memcap
  # not running and unable to return at login, since the plist that would load it
  # is gone. memcap installs its own agent instead, which Homebrew never created
  # and so cannot remove. Keeping the block would also leave
  # `brew services start memcap` live as a second mechanism, loading a second
  # agent alongside memcap's own and racing it every 60 seconds.
  #
  # Correction, recorded rather than deleted: an earlier version of this comment
  # blamed `brew upgrade` for a 28-hour enforcement outage on the author's
  # machine. That was wrong. The cause was `memcap uninstall` calling
  # `brew services stop` unsandboxed, reached by the test suite five times per
  # run. Fixed in v0.2.0.
  def caveats
    <<~EOS
      Run `memcap init` to set up. It installs memcap's own LaunchAgent, which
      starts at login and survives `brew upgrade` -- a Homebrew-managed service
      is removed by upgrades, which silently ends enforcement.

      If you previously ran `brew services start memcap`, `memcap init` stops and
      removes that agent for you.

      To check enforcement is actually running, at any time:
        memcap status
    EOS
  end


  test do
    assert_match "usage", shell_output("#{bin}/memcap help")
  end
end
