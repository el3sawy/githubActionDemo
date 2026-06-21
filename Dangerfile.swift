import Danger
import Foundation

let danger = Danger()
let git = danger.git
let pr = danger.github.pullRequest

// Warn on large PRs
let bigPRThreshold = 600
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

// Report failed tests from JUnit report
let reportPath = "fastlane/test_output/report.junit"
if let xmlData = FileManager.default.contents(atPath: reportPath),
   let xml = String(data: xmlData, encoding: .utf8) {

    struct FailedTest {
        let className: String
        let testName: String
        let message: String
        let location: String
    }

    var failedTests: [FailedTest] = []
    var currentClass = ""
    var currentName = ""

    func extract(_ attribute: String, from line: String) -> String? {
        let needle = "\(attribute)='"
        guard let start = line.range(of: needle) else { return nil }
        let rest = line[start.upperBound...]
        guard let end = rest.range(of: "'") else { return nil }
        return String(rest[..<end.lowerBound])
    }

    let lines = xml.components(separatedBy: .newlines)
    for (i, line) in lines.enumerated() {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("<testcase") {
            currentClass = extract("classname", from: trimmed) ?? ""
            currentName = extract("name", from: trimmed) ?? ""
        }
        if trimmed.hasPrefix("<failure") {
            let rawMessage = extract("message", from: trimmed) ?? "Test failed"
            let message = rawMessage
                .replacingOccurrences(of: "&amp;quot;", with: "\"")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
            // Location is the text content between > and </failure>
            let parts = trimmed.components(separatedBy: ">")
            let location = parts.count > 1
                ? String(parts[1].components(separatedBy: "<")[0]).trimmingCharacters(in: .whitespaces)
                : ""
            failedTests.append(FailedTest(
                className: currentClass,
                testName: currentName,
                message: message,
                location: location
            ))
        }
    }

    if !failedTests.isEmpty {
        var report = "### Failed Tests\n\n"
        for test in failedTests {
            report += "**\(test.testName)** (`\(test.className)`)\n"
            report += "> \(test.message)"
            if !test.location.isEmpty {
                report += "\n> \(test.location)"
            }
            report += "\n\n"
        }
        fail(report)
    }
}
