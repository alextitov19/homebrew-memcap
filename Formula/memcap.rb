class Memcap < Formula
  desc "Keep AI coding agents inside a RAM budget on macOS"
  homepage "https://github.com/alextitov19/memcap"
  url "https://github.com/alextitov19/memcap/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "d0eb0fd0a9fd0dd9c3d1cf3a084cd6e265ffb342d55c492b8a1ab7f0cb90761b"
  license "MIT"

  depends_on "jq"
  depends_on :macos

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
  # homebrew.mxcl.memcap.plist, which any `brew services stop memcap` removes --
  # whoever or whatever issues it -- leaving memcap not running and unable to
  # return at login, since the plist that would load it is gone. (An earlier
  # version of this comment said `brew upgrade` removes it. That is unproven: the
  # plist survived the upgrade to v0.2.0 on the author's machine. The `stop` path
  # is the one actually observed, and is enough on its own.) memcap installs its
  # own agent instead, which Homebrew never created
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
      starts at login and is preserved when the binary is upgraded.
      Existing installations do not need to run init again.

      Optional queue and idle-helper collector (Python 3.9+: brew install python):
        memcap run -- your-build-command
        memcap queue
        memcap gc
      Set GC_MODE=on in memcap.conf to automatically retire verified idle helpers.
      Generate opt-in agent hooks, then merge into existing settings:
        memcap agent-hooks codex --queue
        memcap agent-hooks claude --queue
      Stop hooks use a local 60-second wait (75-second hook timeout). Merge
      regenerated hooks into existing installations to prevent rapid polling.
      Reload sessions after installing hooks; Codex also requires hook trust.

      If you previously ran `brew services start memcap`, `memcap init` stops and
      removes that agent for you.

      To check enforcement is actually running, at any time:
        memcap status

      Read the latest private pressure snapshot:
        memcap diagnostics
    EOS
  end

  test do
    ENV["MEMCAP_CONFIG_HOME"] = (testpath/"config").to_s
    ENV["MEMCAP_STATE_HOME"] = (testpath/"state").to_s
    ENV["MC_DRY_RUN"] = "1"
    assert_match "usage", shell_output("#{bin}/memcap help")
    assert_match "memcap #{version}", shell_output("#{bin}/memcap version")
    assert_match "No pressure snapshots", shell_output("#{bin}/memcap diagnostics")
  end
end
