class Aif < Formula
  desc "Put an existing project on AI SDLC rails"
  homepage "https://github.com/Namdurash/ai-foundry"
  url "https://github.com/Namdurash/ai-foundry/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "7d2e6b1e4beca7ed6b5102f6f6a43fe896e5fb67235f5ccc6d0f8f78c6a55005"
  license "MIT"

  depends_on "jq"

  # aif is not a single self-contained script: bin/aif sources lib/*.sh and
  # reads sets/, profiles/ and tests/evals/ relative to AIF_ROOT, which it
  # derives by walking its own symlink chain. So the whole tree goes into
  # libexec and only the entry point is linked into bin.
  def install
    libexec.install "bin", "lib", "sets", "profiles", "tests"
    bin.install_symlink libexec/"bin/aif"
  end

  def caveats
    <<~EOS
      aif drives an agentic coding CLI; it does not ship one. Install at least
      one runner (currently `claude`), then check what aif can see:

        aif doctor
    EOS
  end

  test do
    assert_match "aif #{version}", shell_output("#{bin}/aif version")
    assert_match "usage: aif", shell_output("#{bin}/aif help")
    # The profile list is read from libexec/profiles, so this also proves the
    # tree survived the move out of the source root.
    assert_match "anthropic", shell_output("#{bin}/aif profiles")
    # Reads no project and shells out to nothing, so it is safe in a sandbox.
    assert_match "usage: aif cost", shell_output("#{bin}/aif cost --help")
    # The defect 0.3.0 fixes. `aif init` copies these into a project with `cp`,
    # and the runner execs them directly, so a hook that loses its mode anywhere
    # along the way turns off cost accounting silently — the ledger keeps filling
    # with gate rows and looks complete. This is the packaging layer of that
    # chain: the tarball carries the bit and `libexec.install` preserves it, but
    # nothing else here asserted either.
    assert_predicate libexec/"sets/claude/hooks/meter.sh", :executable?
    assert_predicate libexec/"sets/claude/hooks/guard.sh", :executable?
  end
end
