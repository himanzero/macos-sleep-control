import Foundation

/// Manages reading and modifying macOS `pmset` sleep configuration and managing `/etc/sudoers.d/mac_sleep_control`
final class SleepManager: @unchecked Sendable {
    static let shared = SleepManager()
    private let sudoersFilePath = "/etc/sudoers.d/mac_sleep_control"

    private init() {}

    // MARK: - Read Current pmset Telemetry

    /// Executes `/usr/bin/pmset -g` and parses `SleepDisabled` along with key metrics
    func fetchTelemetry() -> PmsetTelemetry {
        let output = runProcess(executable: "/usr/bin/pmset", arguments: ["-g"]).output
        var telemetry = PmsetTelemetry(rawOutput: output)

        let lines = output.components(separatedBy: .newlines)
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }

            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            guard parts.count >= 2 else { continue }
            let key = parts[0].lowercased()
            let value = parts[1]

            switch key {
            case "sleepdisabled":
                telemetry.isSleepDisabled = (value == "1")
            case "displaysleep":
                telemetry.rawDisplaySleep = value
            case "hibernatemode":
                telemetry.rawHibernateMode = value
            case "sleep":
                telemetry.rawSystemSleep = value
            case "lowpowermode":
                telemetry.rawLowPowerMode = value
            default:
                break
            }
        }
        return telemetry
    }

    // MARK: - Passwordless sudo Detection

    /// Checks if current user can execute `/usr/bin/pmset` without password via sudo
    func isPasswordlessSudoEnabled() -> Bool {
        let checkResult = runProcess(
            executable: "/usr/bin/sudo",
            arguments: ["-n", "-l", "/usr/bin/pmset"]
        )
        if checkResult.exitCode == 0 {
            return true
        }
        let fallbackResult = runProcess(
            executable: "/usr/bin/sudo",
            arguments: ["-n", "/usr/bin/pmset", "-g"]
        )
        return fallbackResult.exitCode == 0
    }

    // MARK: - Toggle Sleep State (disablesleep 1 / 0)

    func setSleepDisabled(_ disableSleep: Bool, allowInteractiveAuth: Bool = true) -> Result<Void, Error> {
        let targetFlag = disableSleep ? "1" : "0"

        // 1. Prefer silent passwordless channel: sudo -n /usr/bin/pmset -a disablesleep <0|1>
        let silentResult = runProcess(
            executable: "/usr/bin/sudo",
            arguments: ["-n", "/usr/bin/pmset", "-a", "disablesleep", targetFlag]
        )
        if silentResult.exitCode == 0 {
            return .success(())
        }

        // 2. Return error if interactive prompt is disabled
        guard allowInteractiveAuth else {
            return .failure(SleepControlError.passwordlessNotConfigured)
        }

        // 3. Fallback to native macOS administrator prompt
        let shellCommand = "/usr/bin/pmset -a disablesleep \(targetFlag)"
        return runWithAdministratorPrivileges(shellCommand: shellCommand)
    }

    // MARK: - Passwordless sudoers Configuration

    func configurePasswordlessSudo() -> Result<Void, Error> {
        let username = NSUserName()
        guard !username.isEmpty,
              username.range(of: "^[a-zA-Z0-9._-]+$", options: .regularExpression) != nil else {
            return .failure(SleepControlError.invalidUsername(username))
        }

        let ruleLine = "# Managed by SleepControl.app - Passwordless pmset for sleep toggle\\n\(username) ALL=(ALL) NOPASSWD: /usr/bin/pmset\\n"
        let tmpFile = "/private/tmp/mac_sleep_control_sudoers_\(UUID().uuidString)"

        let script = [
            "printf '\(ruleLine)' > '\(tmpFile)'",
            "/usr/sbin/chown root:wheel '\(tmpFile)'",
            "/bin/chmod 0440 '\(tmpFile)'",
            "/usr/sbin/visudo -cf '\(tmpFile)'",
            "/bin/mv '\(tmpFile)' '\(sudoersFilePath)'"
        ].joined(separator: " && ")

        return runWithAdministratorPrivileges(shellCommand: script)
    }

    func removePasswordlessSudo() -> Result<Void, Error> {
        let script = "/bin/rm -f '\(sudoersFilePath)'"
        return runWithAdministratorPrivileges(shellCommand: script)
    }

    // MARK: - Subprocess Execution Helpers

    private func runProcess(executable: String, arguments: [String]) -> (exitCode: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return (process.terminationStatus, output)
        } catch {
            return (-1, error.localizedDescription)
        }
    }

    private func runWithAdministratorPrivileges(shellCommand: String) -> Result<Void, Error> {
        let escaped = shellCommand
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let appleScript = "do shell script \"\(escaped)\" with administrator privileges"

        let result = runProcess(executable: "/usr/bin/osascript", arguments: ["-e", appleScript])
        if result.exitCode == 0 {
            return .success(())
        } else {
            let msg = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            if msg.contains("-128") || msg.localizedCaseInsensitiveContains("User canceled") {
                return .failure(SleepControlError.userCanceledAuth)
            }
            if msg.isEmpty {
                return .failure(SleepControlError.executionFailedWithCode(result.exitCode))
            }
            return .failure(SleepControlError.executionFailed(msg))
        }
    }
}

enum SleepControlError: LocalizedError, Equatable {
    case passwordlessNotConfigured
    case userCanceledAuth
    case invalidUsername(String)
    case executionFailed(String)
    case executionFailedWithCode(Int32)

    var errorDescription: String? {
        localizedErrorDescription(in: nil)
    }

    func localizedErrorDescription(in language: AppLanguage? = nil) -> String {
        switch self {
        case .passwordlessNotConfigured:
            return I18n.shared.localized("err.passwordless_not_configured", in: language)
        case .userCanceledAuth:
            return I18n.shared.localized("err.user_canceled", in: language)
        case .invalidUsername(let name):
            return I18n.shared.format("err.invalid_username", in: language, args: [name])
        case .executionFailed(let detail):
            return detail
        case .executionFailedWithCode(let code):
            return I18n.shared.format("err.exec_failed", in: language, args: [code])
        }
    }
}
