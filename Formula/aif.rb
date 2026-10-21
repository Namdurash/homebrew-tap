class Aif < Formula
  desc "Put an existing project on AI SDLC rails"
  homepage "https://github.com/Namdurash/ai-foundry"
  url "https://github.com/Namdurash/ai-foundry/archive/refs/tags/v0.20.0.tar.gz"
  sha256 "51847600fdd4c05a5c174ec39f8b84e2314942989cb37ecd56ef259aeb9b043c"
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
    # 0.16.0 laid the ground for an autopilot: `aif board release` sweeps the
    # Backlog cards whose dependencies are Done and landed and `aif board head`
    # returns the line a card is routed on — both named by `aif help`, the sweep
    # a CLI file of its own — and the reviewer's verdict has a fixed first line.
    # A tarball carrying the 0.15.x tree under this version would pass
    # everything above.
    assert_path_exists libexec/"lib/release.sh"
    assert_match "head, release", shell_output("#{bin}/aif help")
    assert_match "wrong:", (libexec/"sets/claude/skills/aif-review/SKILL.md").read
    # 0.17.0 is the shift: `aif start` opens the review, analyst and owner
    # sessions one at a time while the loop builds in another terminal, its
    # policy a jq file over the board's facts and a request's progress read by
    # a library of its own — three CLI files, named by `aif help`. The set's
    # land judges the merge in the ticket's own worktree, the templates name
    # what the gates' copies leave out, and the reviewer posts again with its
    # head a verdict bash cannot read. A tarball carrying the 0.16.x tree under
    # this version would pass everything above.
    assert_path_exists libexec/"lib/cmd_start.sh"
    assert_path_exists libexec/"lib/start.jq"
    assert_path_exists libexec/"lib/requests.sh"
    assert_match(/^ +start +The shift/, shell_output("#{bin}/aif help"))
    assert_match "\"leave_out\"", (libexec/"sets/claude/project.templates/jest.json").read
    review = (libexec/"sets/claude/skills/aif-review/SKILL.md").read
    assert_match "in the ticket's own worktree", review
    assert_match "A verdict already on the card", review
    refute_match "runs the suite on the result", review
    # 0.18.0 sets aif up on any stack: `aif setup` — a CLI file of its own,
    # named by `aif help` — has the profile's model write the test contract,
    # the probe gate proves it, and a runner with no template of its own
    # starts from the base template. The jest template makes jest-junit write
    # each case's file. A tarball carrying the 0.17.x tree under this version
    # would pass everything above.
    assert_path_exists libexec/"lib/cmd_setup.sh"
    assert_path_exists libexec/"sets/claude/gates/probe.sh"
    assert_path_exists libexec/"sets/claude/project.templates/base.json"
    assert_match(/^ +setup +The model/, shell_output("#{bin}/aif help"))
    assert_match "JEST_JUNIT_ADD_FILE_ATTRIBUTE=true", (libexec/"sets/claude/project.templates/jest.json").read
    assert_match "The test contract", (libexec/"sets/claude/skills/aif-setup/SKILL.md").read
    # 0.19.0 builds on opus at a named effort — the templates put both tiers at
    # opus, and every station's aif:meta names its effort — and takes a plan to
    # the product partner whole: mapped first into requests/MAP.md, read by a
    # function of the requests library, its technical work the analyst's, and
    # plan mode opened by the shift with its plans in the project. A tarball
    # carrying the 0.18.x tree under this version would pass everything above.
    jest = (libexec/"sets/claude/project.templates/jest.json").read
    assert_match "\"routine\": \"opus\"", jest
    refute_match "\"routine\": \"sonnet\"", jest
    assert_match "\"effort\": \"xhigh\"", (libexec/"sets/claude/agents/aif-implement.md").read
    po = (libexec/"sets/claude/skills/aif-po/SKILL.md").read
    assert_match "requests/MAP.md", po
    assert_match "## Four ways in", po
    refute_match "## Three ways in", po
    assert_match "A plan's technical work", (libexec/"sets/claude/skills/aif-ba/SKILL.md").read
    assert_match "aif_request_map_json", (libexec/"lib/requests.sh").read
    assert_match "plansDirectory", (libexec/"lib/runner_claude.sh").read
  end
end
