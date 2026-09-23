class Memcap < Formula
  desc "Keep AI coding agents inside a RAM budget on macOS"
  homepage "https://github.com/alextitov19/memcap"
  url "https://github.com/alextitov19/memcap/archive/refs/tags/v0.15.1.tar.gz"
  sha256 "949ea7ec4b537e1c48d607041c5c80f33ce59d3cc0a1ba16af6742734fc44fcc"
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

      Docker, agents and simulators now share measured usage under TOTAL_BUDGET_GB.
      Docker's VM ceiling is not a reservation. BUDGET_MODE=split retains the
      legacy watchdog slices. Upgrades preserve pause state and Docker settings.

      Optional queue and idle-helper collector (Python 3.9+: brew install python):
        memcap run -- your-build-command
        memcap queue
        memcap gc
      Set GC_MODE=on in memcap.conf to automatically retire verified idle helpers.
      Install or refresh agent hooks and managed global instructions:
        memcap integrate
        memcap doctor
      Init offers this integration for detected Claude/Codex profiles.
      Existing settings are preserved and changed originals are backed up.
      Re-run integrate after upgrades. Stable hooks pick up new code immediately.
      Running sessions receive guidance at their next tool, once per version.
      Reload sessions if hook definitions changed; existing runners keep old code.
      Codex requires hook trust review in /hooks; doctor reports unverified trust.
      Stop hooks wait locally for 60 seconds to avoid rapid model polling.
      If TaskOutput is unavailable, use the existing ID from memcap queue:
        memcap wait JOB_ID --timeout 60
        memcap wait --session --timeout 60
      The session form needs no lookup pipeline. This does not create another queued job or reserve memory.

      Optional sanitized GitHub feedback (Python 3.9+ and an authenticated gh):
        memcap report enable
        memcap report queue-lock
        memcap report lightweight-queued --context repository-search --wait-seconds 120
        memcap report disable
      Setup asks once, defaulting to no. Existing installs remain opted out.
      Reports include numeric machine capacity, OS, memory/load and queue facts.
      Fixed activity contexts distinguish read, wait, remote and Stop-hook incidents.
      Queue ages and last blocker codes describe stored records, not proven live work.
      No hostnames, commands, project paths or raw logs are published.
      Performance regressions are reportable even if the command succeeds.
      Memcap has no publication quota or retry cooldown.
      Report once per incident, not every poll; duplicate suppression still applies.
      Without opt-in or GitHub access, reporting keeps a private local draft.

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
