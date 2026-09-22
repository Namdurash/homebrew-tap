class Aif < Formula
  desc "Put an existing project on AI SDLC rails"
  homepage "https://github.com/Namdurash/ai-foundry"
  url "https://github.com/Namdurash/ai-foundry/archive/refs/tags/v0.5.3.tar.gz"
  sha256 "28427245e9add44835193ce739428baef16fbc2cde1a2a9a660849b5db43a9a7"
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
    # The defect 0.3.0 fixed, kept as a standing check. `aif init` copies these
    # into a project with `cp`, and the runner execs them directly, so a hook
    # that loses its mode anywhere along the way turns off cost accounting
    # silently — the ledger keeps filling with gate rows and looks complete.
    # This is the packaging layer of that chain: the tarball carries the bit and
    # `libexec.install` preserves it, but nothing else here asserted either.
    assert_predicate libexec/"sets/claude/hooks/meter.sh", :executable?
    assert_predicate libexec/"sets/claude/hooks/guard.sh", :executable?
    # The bottle is a (CLI, set) pair and the two are versioned separately, so a
    # release that bumps only AIF_VERSION ships stations from the previous set
    # against the current gates. That mismatch is invisible from `aif version`.
    assert_match "SET_VERSION=#{version}", (libexec/"sets/claude/set.meta").read
    # Proves the tarball carries the new set, not just a new version string on
    # the old one — and 0.5.0 is the release where that stopped being a
    # formality. The rebuild replaced the spec chain with one Definition of
    # Ready, so the set is told apart by what it now has AND by what it no
    # longer ships: a tap serving the old tree under the new version would pass
    # every other assertion here.
    assert_path_exists libexec/"sets/claude/gates/ready.sh"
    refute_path_exists libexec/"sets/claude/gates/plan-form.sh"
    refute_path_exists libexec/"sets/claude/gates/spec-form.sh"
  end
end
