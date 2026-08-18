class Memcap < Formula
  desc "Keep AI coding agents inside a RAM budget on macOS"
  homepage "https://github.com/alextitov19/memcap"
  url "https://github.com/alextitov19/memcap/archive/refs/tags/v0.1.4.tar.gz"
  sha256 "c108b6811cbac65be8511dd34305ba3f03b0e4c3d01ccfa3849d662d8b4a7574"
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

  # Homebrew prints its own restart hint for a service formula, so this only adds
  # what that hint does not say: enforcement ends silently, and `memcap status`
  # will tell you. An earlier version of this comment blamed `brew upgrade` for a
  # 28-hour outage on the author's machine. That was wrong -- the cause was
  # `memcap uninstall` calling `brew services stop` unsandboxed from the test
  # suite. Left here as a correction rather than deleted.
  def caveats
    <<~EOS
      Upgrading stops the background service, which silently ends enforcement
      until it is restarted (see below).

      To check enforcement is actually running, at any time:
        memcap status

      It reports when the last enforcement pass happened, and says so plainly
      when memcap has stopped.
    EOS
  end

  service do
    run [opt_bin/"memcap", "watch"]
    run_type :interval
    interval 60
    log_path var/"log/memcap.log"
    error_log_path var/"log/memcap.err"
  end

  test do
    assert_match "usage", shell_output("#{bin}/memcap help")
  end
end
