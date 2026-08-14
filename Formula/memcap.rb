class Memcap < Formula
  desc "Keep AI coding agents inside a RAM budget on macOS"
  homepage "https://github.com/alextitov19/memcap"
  url "https://github.com/alextitov19/memcap/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "a9bcea51082f4629d988ee8bce3c2bcbb98ff66a270fe3aad0891dfc7c07e2cf"
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
