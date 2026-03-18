# Upgrade Plan: Sistem Pendaftaran Produk Air (20260318013609)

- Generated: 2026-03-18 01:37 local
- HEAD Branch: N/A
- HEAD Commit ID: N/A

## Available Tools

Warning: Git is not available. Changes are not version-controlled in this session.

JDKs
- JDK 21.0.10: C:\Program Files\Java\jdk-21.0.10\bin

Build Tools
- Maven 3.9.14: P:\ProjectLI\tools\apache-maven-3.9.14\bin\mvn.cmd
- Maven Wrapper: Not present

## Guidelines

- Upgrade Java runtime/build target to LTS Java 21.
- Use the Java upgrade workflow and tools to generate and execute an incremental plan.

## Options

- Working branch: appmod/java-upgrade-20260318013609
- Run tests before and after the upgrade: true

## Upgrade Goals

- Upgrade Java build target from 17 to 21.

### Technology Stack

| Technology/Dependency | Current | Min Compatible | Why Incompatible |
| --------------------- | ------- | -------------- | ---------------- |
| Java (source/target) | 17 | 21 | User requested Java 21 target |
| Maven | 3.9.14 | 3.9+ | - |
| Maven Wrapper | Not present | N/A | No wrapper; use local Maven executable |
| maven-compiler-plugin | 3.10.1 | 3.11.0 | 3.10.1 is below Java 21 recommended minimum |
| maven-war-plugin | 3.3.2 | 3.3.2 | - |
| jakarta.servlet-api | 6.1.0 | 6.1.0 | - |
| mysql-connector-j | 9.2.0 | 9.2.0 | - |
| HikariCP | 5.0.1 | 5.0.1 | - |
| gson | 2.10.1 | 2.10.1 | - |
| slf4j-api/slf4j-simple | 2.0.5 | 2.0.5 | - |

### Derived Upgrades

- Upgrade POM properties `maven.compiler.source` and `maven.compiler.target` from 17 to 21 (direct goal alignment).
- Upgrade `maven-compiler-plugin` to 3.11.0+ (Java 21 compile compatibility).
- Add `maven-surefire-plugin` 3.1+ (test execution reliability on Java 21).

## Upgrade Steps

- Step 1: Setup Environment
  - Rationale: Confirm required Java 21 and Maven 3.9+ are available and define fixed tool paths for repeatable execution.
  - Changes to Make:
    - [ ] Validate Java 21 executable path.
    - [ ] Validate Maven 3.9.14 executable path.
    - [ ] Persist execution notes in progress tracking.
  - Verification:
    - Command: `"P:\ProjectLI\tools\apache-maven-3.9.14\bin\mvn.cmd" -version`
    - JDK: C:\Program Files\Java\jdk-21.0.10
    - Expected: Maven reports Java 21 runtime and correct Maven version.

- Step 2: Setup Baseline
  - Rationale: Establish baseline compile and test outcome before Java target change.
  - Changes to Make:
    - [ ] Run baseline `clean test-compile`.
    - [ ] Run baseline `clean test`.
    - [ ] Record baseline pass/fail and test totals in progress file.
  - Verification:
    - Command: `"P:\ProjectLI\tools\apache-maven-3.9.14\bin\mvn.cmd" -q clean test-compile` and `"P:\ProjectLI\tools\apache-maven-3.9.14\bin\mvn.cmd" -q clean test`
    - JDK: C:\Program Files\Java\jdk-21.0.10
    - Expected: Baseline compile and test status documented.

- Step 3: Upgrade Build Target to Java 21
  - Rationale: Apply minimal required POM changes to align compiler and test plugins with Java 21.
  - Changes to Make:
    - [ ] Update `maven.compiler.source` to 21.
    - [ ] Update `maven.compiler.target` to 21.
    - [ ] Upgrade `maven-compiler-plugin` to 3.11.0+.
    - [ ] Add/upgrade `maven-surefire-plugin` to 3.1+.
  - Verification:
    - Command: `"P:\ProjectLI\tools\apache-maven-3.9.14\bin\mvn.cmd" -q clean test-compile`
    - JDK: C:\Program Files\Java\jdk-21.0.10
    - Expected: Main and test code compile successfully.

- Step 4: Final Validation
  - Rationale: Validate all upgrade goals and full test success criteria.
  - Changes to Make:
    - [ ] Confirm Java 21 target values are present in `pom.xml`.
    - [ ] Resolve any remaining compilation or test issues.
    - [ ] Run full clean test with Java 21.
  - Verification:
    - Command: `"P:\ProjectLI\tools\apache-maven-3.9.14\bin\mvn.cmd" -q clean test`
    - JDK: C:\Program Files\Java\jdk-21.0.10
    - Expected: Compile success and 100% tests pass.

## Key Challenges

- Maven plugin compatibility with Java 21
  - Challenge: `maven-compiler-plugin` 3.10.1 may not reliably handle Java 21 target.
  - Strategy: Upgrade compiler plugin first, then validate with `clean test-compile`.
- No Git on machine
  - Challenge: No branch/commit safety net or automated rollback points.
  - Strategy: Keep changes minimal and track every step in `progress.md` and `summary.md`.

## Plan Review

- Coverage check: Mandatory setup, baseline, upgrade, and final validation steps are included.
- Feasibility check: Required tools already available (JDK 21 + Maven 3.9.14), no installations needed.
- Limitation: No git history/branching for this run; compensating control is detailed step tracking.
