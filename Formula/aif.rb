class Aif < Formula
  desc "Put an existing project on AI SDLC rails"
  homepage "https://github.com/Namdurash/ai-foundry"
  url "https://github.com/Namdurash/ai-foundry/archive/refs/tags/v0.15.0.tar.gz"
  sha256 "e39ffe0c2cf5e3af553c65cfb7477e4ef0c082b3326548962b2375593761cdbd"
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
    # 0.9.0 closed the cycle after the worker: `aif land` in the CLI and the
    # reviewer's brief in the set. A tap serving the old tree under the new
    # version would still pass everything above.
    assert_match "land", shell_output("#{bin}/aif help")
    assert_path_exists libexec/"sets/claude/skills/aif-review/SKILL.md"
    # 0.11.0 handed the stations the stack: a runner fragment per template in
    # the set, and `aif project guide` in the CLI. The fragments are what the
    # worker appends to the plan and tests stations' prompts, so a tarball
    # carrying the 0.10.x set under this version would ship stations that
    # work from their general rules while doctor reports the fragment present.
    assert_path_exists libexec/"sets/claude/stacks/jest.md"
    assert_path_exists libexec/"sets/claude/stacks/pytest.md"
    assert_match "guide", shell_output("#{bin}/aif help")
    # 0.13.0 counts a ticket by its rules and gives the analyst the map of every
    # ticket's rules: `aif rules` is a CLI file of its own, and the templates
    # carry the rules cap and no longer the plan-file and diff-line caps. A
    # tarball carrying the 0.12.x tree under this version would pass everything
    # above.
    assert_path_exists libexec/"lib/cmd_rules.sh"
    assert_match(/^ +rules +Every ticket/, shell_output("#{bin}/aif help"))
    template = (libexec/"sets/claude/project.templates/jest.json").read
    assert_match "ticket_rules_max", template
    refute_match "\"diff_lines_max\": 400", template
    # 0.14.0 put the product partner after the reviewer: on the human's land the
    # reviewer's brief hands the card to the product partner's demo, which holds
    # the build to its request before aif land runs. The change is all in two
    # skills' text, so a tarball carrying the 0.13.x set under this version would
    # pass everything above.
    assert_match "demo: not as expected", (libexec/"sets/claude/skills/aif-po/SKILL.md").read
    assert_match "The product partner's demo", (libexec/"sets/claude/skills/aif-review/SKILL.md").read
  end
end
