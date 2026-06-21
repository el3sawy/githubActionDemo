import Danger

let danger = Danger()
let git = danger.git

// Warn on large PRs
let bigPRThreshold = 600
let pr = danger.github.pullRequest
let totalChanges = (pr.additions ?? 0) + (pr.deletions ?? 0)
if totalChanges > bigPRThreshold {
    warn("PR is large (\(totalChanges) lines changed). Consider splitting into smaller PRs.")
}

// Fail if PR has no description
if pr.body == nil || pr.body?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
    fail("Please provide a PR description.")
}

// Warn if PR title contains WIP
if pr.title.lowercased().contains("wip") {
    warn("PR is marked as WIP.")
}

// Warn if no tests modified when source files changed
let sourceChanged = git.modifiedFiles.contains { $0.hasSuffix(".swift") && !$0.contains("Test") && !$0.contains("Spec") }
let testsChanged = git.modifiedFiles.contains { $0.contains("Test") || $0.contains("Spec") }
if sourceChanged && !testsChanged {
    warn("Source files changed but no test files modified. Consider adding tests.")
}
