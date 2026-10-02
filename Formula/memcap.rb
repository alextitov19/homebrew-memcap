class Memcap < Formula
  desc "Keep AI coding agents inside a RAM budget on macOS"
  homepage "https://github.com/alextitov19/memcap"
  url "https://github.com/alextitov19/memcap/archive/refs/tags/v0.23.0.tar.gz"
  sha256 "1628d6dc739669e5852d5312b9870a2e4b2627f3b9856bd93576d0165b36295f"
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
      New installations: run `memcap init` to install memcap's own LaunchAgent.
      Existing installations do not need init again. Upgrades preserve the
      owner pause, live policy, Docker settings and agent hook trust.

      v0.23.0 learns automatic estimates from fixed requests without changing
      their floors. For ordinary builds/tests, omit --memory for automatic sizing.
      Save private release baselines outside rolling retention:
        memcap analytics snapshot ~/memcap-before --days 1
        memcap analytics release-compare ~/memcap-before ~/memcap-after
      Compare completed waits, pending ages, pressure and measurement coverage.
      Version labels follow recorded runner metadata, not installation time.

      v0.22.0 reserves disposable test stacks and their workload together before
      starting containers: `memcap environment run --memory TOTAL_GIB
      --compose compose.test.yaml -- TEST_COMMAND`. Verified owned containers stop
      after completion; volumes, pins, live claims and uncertain ownership remain
      protected. Existing untracked stacks are not adopted or stopped.
      Lightweight wrappers stay native, supported shell stages admit separately,
      and analytics retain pending ages and separate tagged monitoring work.
      Existing supervisors keep their loaded code; active jobs are not restarted.

      v0.21.0 routes lightweight and unknown-demand calls natively. Only positive
      heavyweight evidence enters the shared queue. Local helpers, package scripts
      and Git hooks are inspected without execution; tool permissions still apply.
      First-run unknown allocations remain possible; memcap is not a kernel cap.
      Heavy admissions rotate across parent sessions. Pressure and headroom checks
      remain; accumulated swap alone is not an admission blocker.

      Refresh agent guidance and managed timeout ceilings after upgrading:
        memcap integrate
        memcap doctor
      Integration preserves unrelated settings and backs up changed originals.
      Reload sessions to adopt changed hooks or timeout ceilings. Existing runners
      retain their loaded code. Codex hook trust is reviewed by the owner in /hooks.
      Stable hooks load new code at their next invocation.

      Allow needed managed jobs up to 24 hours, including admission waiting:
        memcap run --wait 86400 -- your-build-command
      Prefer native completion notifications. Otherwise block on the existing
      native task; if unavailable, `memcap wait --session --timeout 60` observes
      this scope without creating another job. Never duplicate queued work.

      Optional local analytics (Python 3.9+):
        memcap analytics enable --service --claude
        memcap analytics today
        memcap analytics html ~/Downloads/memcap-performance.html
        memcap analytics doctor
      v0.21.0 repairs recording at the SQLite storage cap. Analytics distinguishes
      build, policy and pause cohorts; missing coverage remains unknown. Native
      Claude token telemetry requires a newly started process; Codex token usage
      remains unknown. No transcript scraping or public analytics upload.

      Optional temporary raw command evidence, kept only on this Mac:
        memcap trace on
        memcap trace status
        memcap trace clear
      Capture expires after 24 hours and storage is bounded. Raw commands are
      separate from public reporting. Inspect routing with `memcap classify`.

      Optional sanitized feedback requires explicit owner opt-in:
        memcap report enable
        memcap report lightweight-queued --context repository-search
      Reports contain fixed categories and numeric facts, never raw commands or
      private paths. Report each incident once; without consent it stays local.

      Inspect current enforcement, queue and diagnostics:
        memcap status
        memcap queue
        memcap diagnostics
      Docker's VM ceiling is not a reservation. Never infer admission from it.
      Paused commands retain native task behavior and worker settings.
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
