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

// Fail if PR title doesn't start with a Jira ticket e.g. [CLX-152]
let jiraPattern = #"^\[[A-Z]+-\d+\]"#
if pr.title.range(of: jiraPattern, options: .regularExpression) == nil {
    fail("PR title must start with a Jira ticket e.g. `[CLX-152] Add offline model`")
}

// Warn if no tests modified when source files changed
let sourceChanged = git.modifiedFiles.contains { $0.hasSuffix(".swift") && !$0.contains("Test") && !$0.contains("Spec") }
let testsChanged = git.modifiedFiles.contains { $0.contains("Test") || $0.contains("Spec") }
if sourceChanged && !testsChanged {
    warn("Source files changed but no test files modified. Consider adding tests.")
}

// Check per-file coverage >= 80%
let coveragePath = "coverage.json"
let coverageThreshold = 0.80

if let coverageData = FileManager.default.contents(atPath: coveragePath),
   let json = try? JSONSerialization.jsonObject(with: coverageData) as? [String: Any],
   let targets = json["targets"] as? [[String: Any]] {

    struct FileCoverage {
        let name: String
        let coverage: Double
        let covered: Int
        let executable: Int
    }

    var belowThreshold: [FileCoverage] = []

    for target in targets {
        guard let files = target["files"] as? [[String: Any]] else { continue }
        for file in files {
            guard
                let name = file["name"] as? String,
                let lineCoverage = file["lineCoverage"] as? Double,
                let coveredLines = file["coveredLines"] as? Int,
                let executableLines = file["executableLines"] as? Int,
                executableLines > 0
            else { continue }

            // Skip test files and app entry points
            if name.contains("Test") || name.contains("Spec") || name == "CIDemoApp.swift" { continue }

            if lineCoverage < coverageThreshold {
                belowThreshold.append(FileCoverage(
                    name: name,
                    coverage: lineCoverage,
                    covered: coveredLines,
                    executable: executableLines
                ))
            }
        }
    }

    if !belowThreshold.isEmpty {
        var report = "### Coverage Below 80%\n\n"
        report += "| File | Coverage | Lines |\n"
        report += "|------|----------|-------|\n"
        for f in belowThreshold.sorted(by: { $0.coverage < $1.coverage }) {
            let pct = String(format: "%.1f%%", f.coverage * 100)
            report += "| `\(f.name)` | \(pct) | \(f.covered)/\(f.executable) |\n"
        }
        fail(report)
    }
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
