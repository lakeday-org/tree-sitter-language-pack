"""Keep release dry runs read-only while retaining artifact validation."""

import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DRY = "needs.prepare.outputs.dry_run"
INPUT_DRY = "inputs.dry_run"


def allows_mutation(condition: str, variable: str, value: bool | str) -> bool:
    condition = condition.replace("${{", "(").replace("}}", ")")
    comparisons = re.findall(rf"(?:^|&&|\()\s*{re.escape(variable)}\s*!=\s*('true'|true)\s*(?=&&|\)|$)", condition)
    for comparison in comparisons:
        expected = True if comparison == "true" else "true"
        if type(value) is type(expected) and value == expected:
            return False
    return True


class ReleaseDryMutationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.jobs = yaml.safe_load((ROOT / ".github/workflows/publish.yaml").read_text())["jobs"]

    def test_or_mutation_is_rejected_instead_of_mistaken_for_a_guard(self) -> None:
        unsafe = f"{INPUT_DRY} != true || {INPUT_DRY} != 'true'"
        safe = f"{INPUT_DRY} != true && {INPUT_DRY} != 'true'"
        for dry in [True, "true"]:
            with self.subTest(dry=dry):
                assert allows_mutation(unsafe, INPUT_DRY, dry)
                assert not allows_mutation(safe, INPUT_DRY, dry)

    def test_swift_mutation_blocks_both_true_forms_and_allows_real_release(self) -> None:
        steps = self.jobs["update-swift-package-manifest"]["steps"]
        commit = next(step for step in steps if step.get("name") == "Commit and push Package.swift")
        assert "||" not in commit.get("if", "")
        for dry, expected in [(True, False), ("true", False), (False, True), ("false", True)]:
            with self.subTest(dry=dry), tempfile.TemporaryDirectory() as directory:
                log = Path(directory) / "git.log"
                git = Path(directory) / "git"
                git.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$GIT_LOG"\n')
                git.chmod(0o755)
                if allows_mutation(commit.get("if", ""), OUTPUT_DRY, dry):
                    script = commit["run"].replace("${{ needs.prepare.outputs.version }}", "1.22.2")
                    script = script.replace("${{ needs.prepare.outputs.tag }}", "v1.22.2")
                    environment = dict(os.environ, PATH=f"{directory}:{os.environ['PATH']}", GIT_LOG=str(log))
                    subprocess.run(["bash", "-eu", "-c", script], env=environment, check=True)
                commands = log.read_text().splitlines() if log.exists() else []
                pushes = [command for command in commands if command.startswith("push ")]
                assert len(pushes) == (2 if expected else 0)
                if expected:
                    assert pushes[0].endswith("refs/tags/v1.22.2")
                    assert pushes[1].endswith("HEAD:refs/heads/release/swift/1.22.2")

    def test_swift_dry_run_keeps_checksum_validation_and_artifact_builds(self) -> None:
        job = self.jobs["update-swift-package-manifest"]
        assert "dry_run" not in job["if"]
        assert job["needs"] == ["prepare", "build-swift-artifactbundle", "e2e-swift"]
        validate = next(step for step in job["steps"] if step.get("name", "").startswith("Update Package.swift"))
        assert "if" not in validate
        assert '[[ -z "$CHECKSUM" ]]' in validate["run"]
        assert '[[ "$placeholders" -eq 0 ]]' in validate["run"]
        assert "/releases/download/v${VERSION}/" in validate["run"]

    def test_plugins_only_dispatch_blocks_both_true_forms(self) -> None:
        for name in ["dispatch-plugin-npm", "dispatch-plugin-hermes"]:
            assert "||" not in self.jobs[name]["if"]
            for dry, expected in [(True, False), ("true", False), (False, True), ("false", True)]:
                with self.subTest(job=name, dry=dry):
                    assert allows_mutation(self.jobs[name]["if"], INPUT_DRY, dry) == expected

    def test_contract_runs_in_the_existing_ci_job(self) -> None:
        workflow = yaml.safe_load((ROOT / ".github/workflows/ci.yaml").read_text())
        steps = workflow["jobs"]["nuget-pack-contract"]["steps"]
        assert sum(step.get("run") == "task contract-tests:release-dry-mutations" for step in steps) == 1
        assert any(step.get("uses", "").startswith("xberg-io/actions/install-task@") for step in steps)
        tasks = yaml.safe_load((ROOT / ".task/contract-tests.yml").read_text())["tasks"]
        assert tasks["release-dry-mutations"]["cmds"] == [
            "uv run --no-sync python -m unittest scripts.ci.test_release_dry_mutations -v"
        ]

    def test_every_remote_shell_mutation_has_a_dry_guard(self) -> None:
        found = []
        for name, job in self.jobs.items():
            for step in job.get("steps", []):
                if not re.search("\\bgit push\\b|\\bgh (?:release create|workflow run)\\b", step.get("run", "")):
                    continue
                found.append((name, step["name"]))
                condition = f"{job.get('if', '')} {step.get('if', '')}"
                with self.subTest(job=name, step=step["name"]):
                    assert not allows_mutation(condition, OUTPUT_DRY, "true")
        assert len(found) == 8


if __name__ == "__main__":
    unittest.main()
