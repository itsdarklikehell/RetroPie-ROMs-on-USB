#!/bin/bash
#
# test.sh — Test suite for RetroPie-ROMs-on-USB scripts
#
# Pure bash test framework, no external dependencies.
# Run: ./test.sh
#
set -uo pipefail

# ── Test framework ──────────────────────────────────────────────────────
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$expected" == "$actual" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✓ $msg"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$msg")
        echo "  ✗ $msg"
        echo "    Expected: '$expected'"
        echo "    Actual:   '$actual'"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-}"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$haystack" == *"$needle"* ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✓ $msg"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$msg")
        echo "  ✗ $msg"
        echo "    Expected to contain: '$needle'"
        echo "    In: '$haystack'"
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-}"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$haystack" != *"$needle"* ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✓ $msg"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$msg")
        echo "  ✗ $msg"
        echo "    Expected NOT to contain: '$needle'"
        echo "    In: '$haystack'"
    fi
}

assert_file_exists() {
    local file="$1"
    local msg="${2:-File exists: $file}"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -f "$file" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✓ $msg"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$msg")
        echo "  ✗ $msg"
    fi
}

assert_file_not_exists() {
    local file="$1"
    local msg="${2:-File does not exist: $file}"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ ! -f "$file" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✓ $msg"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$msg")
        echo "  ✗ $msg"
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$expected" == "$actual" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✓ $msg"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$msg")
        echo "  ✗ $msg"
        echo "    Expected exit code: $expected"
        echo "    Actual exit code:   $actual"
    fi
}

# ── Test suites ─────────────────────────────────────────────────────────

test_format_usb_exists() {
    echo ""
    echo "━━━ format-usb.sh: File structure ━━━"
    assert_file_exists "format-usb.sh" "format-usb.sh exists"
    assert_file_exists "mount-usb.sh" "mount-usb.sh exists"
}

test_format_usb_shebang() {
    echo ""
    echo "━━━ format-usb.sh: Shebang ━━━"
    local first_line
    first_line=$(head -1 format-usb.sh)
    assert_eq "#!/bin/bash" "$first_line" "First line is #!/bin/bash"
}

test_format_usb_set_euo_pipefail() {
    echo ""
    echo "━━━ format-usb.sh: Safety settings ━━━"
    local content
    content=$(cat format-usb.sh)
    assert_contains "$content" "set -euo pipefail" "Has 'set -euo pipefail'"
}

test_format_usb_has_colors() {
    echo ""
    echo "━━━ format-usb.sh: Color support ━━━"
    local content
    content=$(cat format-usb.sh)
    assert_contains "$content" "RED=" "Defines RED color"
    assert_contains "$content" "GREEN=" "Defines GREEN color"
    assert_contains "$content" "YELLOW=" "Defines YELLOW color"
    assert_contains "$content" "NC=" "Defines NC (no color)"
}

test_format_usb_has_logging() {
    echo ""
    echo "━━━ format-usb.sh: Logging functions ━━━"
    local content
    content=$(cat format-usb.sh)
    assert_contains "$content" "log_info()" "Has log_info function"
    assert_contains "$content" "log_warn()" "Has log_warn function"
    assert_contains "$content" "log_error()" "Has log_error function"
}

test_format_usb_has_confirm() {
    echo ""
    echo "━━━ format-usb.sh: Confirmation prompts ━━━"
    local content
    content=$(cat format-usb.sh)
    assert_contains "$content" "confirm()" "Has confirm function"
    assert_contains "$content" "[y/N]" "Uses y/N confirmation pattern"
}

test_format_usb_has_validation() {
    echo ""
    echo "━━━ format-usb.sh: Device validation ━━━"
    local content
    content=$(cat format-usb.sh)
    assert_contains "$content" "validate_device()" "Has validate_device function"
    assert_contains "$content" '-b "/dev/$device"' "Checks if device is block device"
    assert_contains "$content" "lsblk" "Uses lsblk for device info"
}

test_format_usb_has_dry_run() {
    echo ""
    echo "━━━ format-usb.sh: Dry-run support ━━━"
    local content
    content=$(cat format-usb.sh)
    assert_contains "$content" "DRY_RUN" "Has DRY_RUN support"
    assert_contains "$content" "--dry-run" "Has --dry-run flag"
}

test_format_usb_has_menu() {
    echo ""
    echo "━━━ format-usb.sh: Interactive menu ━━━"
    local content
    content=$(cat format-usb.sh)
    assert_contains "$content" "show_menu()" "Has show_menu function"
    assert_contains "$content" "FAT32" "Menu offers FAT32"
    assert_contains "$content" "ext4" "Menu offers ext4"
    assert_contains "$content" "NTFS" "Menu offers NTFS"
}

test_format_usb_no_old_patterns() {
    echo ""
    echo "━━━ format-usb.sh: No legacy patterns ━━━"
    local content
    content=$(cat format-usb.sh)
    assert_not_contains "$content" "read -rsp" "No silent read prompts"
    assert_not_contains "$content" "clear" "No clear command"
    assert_not_contains "$content" "FINDMNT()" "No old FINDMNT function"
    assert_not_contains "$content" "FAT32()" "No old FAT32 function"
}

test_mount_usb_shebang() {
    echo ""
    echo "━━━ mount-usb.sh: Shebang ━━━"
    local first_line
    first_line=$(head -1 mount-usb.sh)
    assert_eq "#!/bin/bash" "$first_line" "First line is #!/bin/bash"
}

test_mount_usb_set_euo_pipefail() {
    echo ""
    echo "━━━ mount-usb.sh: Safety settings ━━━"
    local content
    content=$(cat mount-usb.sh)
    assert_contains "$content" "set -euo pipefail" "Has 'set -euo pipefail'"
}

test_mount_usb_has_methods() {
    echo ""
    echo "━━━ mount-usb.sh: Mount methods ━━━"
    local content
    content=$(cat mount-usb.sh)
    assert_contains "$content" "method_automatic()" "Has automatic method"
    assert_contains "$content" "method_manual()" "Has manual method"
    assert_contains "$content" "method_symlink()" "Has symlink method"
}

test_mount_usb_has_dry_run() {
    echo ""
    echo "━━━ mount-usb.sh: Dry-run support ━━━"
    local content
    content=$(cat mount-usb.sh)
    assert_contains "$content" "DRY_RUN" "Has DRY_RUN support"
    assert_contains "$content" "--dry-run" "Has --dry-run flag"
}

test_mount_usb_has_config() {
    echo ""
    echo "━━━ mount-usb.sh: Configurable paths ━━━"
    local content
    content=$(cat mount-usb.sh)
    assert_contains "$content" "RETP_FOLDER" "Configurable RETP_FOLDER"
    assert_contains "$content" "MNTPNT" "Configurable MNTPNT"
    assert_contains "$content" "MOUNT_USER" "Configurable MOUNT_USER"
}

test_mount_usb_has_usage() {
    echo ""
    echo "━━━ mount-usb.sh: Usage/help ━━━"
    local content
    content=$(cat mount-usb.sh)
    assert_contains "$content" "usage()" "Has usage function"
    assert_contains "$content" "--help" "Has --help flag"
}

test_mount_usb_no_old_patterns() {
    echo ""
    echo "━━━ mount-usb.sh: No legacy patterns ━━━"
    local content
    content=$(cat mount-usb.sh)
    assert_not_contains "$content" "read -rsp" "No silent read prompts"
    assert_not_contains "$content" "clear" "No clear command"
    assert_not_contains "$content" "DISCLAIMER()" "No old DISCLAIMER function"
    assert_not_contains "$content" "CONFIG()" "No old CONFIG function"
    assert_not_contains "$content" "AUTOMATIC()" "No old AUTOMATIC function"
    assert_not_contains "$content" "MANUAL()" "No old MANUAL function"
    assert_not_contains "$content" "SYMLINKED()" "No old SYMLINKED function"
}

test_mount_usb_no_uncommented_sudo() {
    echo ""
    echo "━━━ mount-usb.sh: No uncommented sudo commands ━━━"
    local content
    content=$(cat mount-usb.sh)
    # Check that sudo commands are wrapped in run_cmd
    assert_not_contains "$content" "#sudo mv" "No commented-out sudo mv"
    assert_not_contains "$content" "#sudo reboot" "No commented-out sudo reboot"
}

test_readme_exists() {
    echo ""
    echo "━━━ README.md: Documentation ━━━"
    assert_file_exists "README.md" "README.md exists"
}

test_readme_has_content() {
    echo ""
    echo "━━━ README.md: Content checks ━━━"
    local content
    content=$(cat README.md)
    assert_contains "$content" "RetroPie" "Mentions RetroPie"
    assert_contains "$content" "USB" "Mentions USB"
    assert_contains "$content" "format-usb.sh" "References format-usb.sh"
    assert_contains "$content" "mount-usb.sh" "References mount-usb.sh"
}

test_readme_has_symlink_docs() {
    echo ""
    echo "━━━ README.md: Symlink method documented ━━━"
    local content
    content=$(cat README.md)
    assert_contains "$content" "symlink" "Documents symlink method"
    assert_contains "$content" "ln -s" "Shows ln -s command"
}

test_ci_exists() {
    echo ""
    echo "━━━ CI: Workflow files ━━━"
    assert_file_exists ".github/workflows/ci.yml" "CI workflow exists"
}

test_ci_has_shellcheck() {
    echo ""
    echo "━━━ CI: ShellCheck integration ━━━"
    local content
    content=$(cat .github/workflows/ci.yml)
    assert_contains "$content" "shellcheck" "CI runs shellcheck"
}

test_ci_has_tests() {
    echo ""
    echo "━━━ CI: Test integration ━━━"
    local content
    content=$(cat .github/workflows/ci.yml)
    assert_contains "$content" "test.sh" "CI runs test.sh"
}

test_shellcheck_clean() {
    echo ""
    echo "━━━ ShellCheck: Static analysis ━━━"
    local output
    output=$(shellcheck --severity=warning format-usb.sh 2>&1)
    assert_eq "" "$output" "format-usb.sh passes shellcheck (warning+)"

    output=$(shellcheck --severity=warning mount-usb.sh 2>&1)
    assert_eq "" "$output" "mount-usb.sh passes shellcheck (warning+)"
}

test_bash_syntax() {
    echo ""
    echo "━━━ Bash syntax check ━━━"
    local output
    output=$(bash -n format-usb.sh 2>&1)
    assert_eq "" "$output" "format-usb.sh has valid bash syntax"

    output=$(bash -n mount-usb.sh 2>&1)
    assert_eq "" "$output" "mount-usb.sh has valid bash syntax"
}

test_help_flag() {
    echo ""
    echo "━━━ Help flag ━━━"
    local output
    output=$(bash mount-usb.sh --help 2>&1)
    assert_contains "$output" "Usage:" "mount-usb.sh --help shows usage"
    assert_contains "$output" "automatic" "Help mentions automatic method"
    assert_contains "$output" "manual" "Help mentions manual method"
    assert_contains "$output" "symlink" "Help mentions symlink method"
}

test_dry_run_flag() {
    echo ""
    echo "━━━ Dry-run flag ━━━"
    local output
    output=$(bash mount-usb.sh --dry-run automatic 2>&1 <<< "n")
    assert_contains "$output" "DRY-RUN" "Dry-run mode is indicated"
}

test_format_usb_help_flag() {
    echo ""
    echo "━━━ format-usb.sh: Help flag ━━━"
    local output
    output=$(bash format-usb.sh --help 2>&1)
    assert_contains "$output" "Usage:" "format-usb.sh --help shows usage"
    assert_contains "$output" "--dry-run" "Help mentions --dry-run flag"
    assert_contains "$output" "-h" "Help mentions -h flag"
}

test_format_usb_dry_run_flag() {
    echo ""
    echo "━━━ format-usb.sh: Dry-run flag ━━━"
    local output
    output=$(bash format-usb.sh --dry-run 2>&1 <<< "7")
    assert_contains "$output" "DRY-RUN" "Dry-run mode is indicated"
}

test_readme_has_testing_section() {
    echo ""
    echo "━━━ README.md: Testing section ━━━"
    local content
    content=$(cat README.md)
    assert_contains "$content" "## Testing" "Has Testing section"
    assert_contains "$content" "./test.sh" "Mentions test.sh"
}

test_readme_has_license_section() {
    echo ""
    echo "━━━ README.md: License section ━━━"
    local content
    content=$(cat README.md)
    assert_contains "$content" "## License" "Has License section"
}

test_readme_has_gource_section() {
    echo ""
    echo "━━━ README.md: Gource section ━━━"
    local content
    content=$(cat README.md)
    assert_contains "$content" "## 🎥 Gource Visualization" "Has Gource Visualization section"
    assert_contains "$content" "gource.mp4" "References gource.mp4"
}

test_readme_has_format_script_docs() {
    echo ""
    echo "━━━ README.md: format-usb.sh docs ━━━"
    local content
    content=$(cat README.md)
    assert_contains "$content" "Interactive menu with FAT32" "Documents format-usb.sh features"
    assert_contains "$content" "Double-confirmation" "Documents double-confirmation"
}

test_readme_has_mount_script_docs() {
    echo ""
    echo "━━━ README.md: mount-usb.sh docs ━━━"
    local content
    content=$(cat README.md)
    assert_contains "$content" "Three mount methods" "Documents mount-usb.sh methods"
    assert_contains "$content" "UUID-based fstab" "Documents UUID fstab config"
}

test_mount_usb_has_log_step() {
    echo ""
    echo "━━━ mount-usb.sh: Step logging ━━━"
    local content
    content=$(cat mount-usb.sh)
    assert_contains "$content" "log_step()" "Has log_step function"
    assert_contains "$content" "log_step \"Automatic" "Uses log_step for automatic method"
    assert_contains "$content" "log_step \"Manual" "Uses log_step for manual method"
    assert_contains "$content" "log_step \"Symlink" "Uses log_step for symlink method"
}

test_mount_usb_has_run_cmd() {
    echo ""
    echo "━━━ mount-usb.sh: run_cmd wrapper ━━━"
    local content
    content=$(cat mount-usb.sh)
    assert_contains "$content" "run_cmd()" "Has run_cmd function"
    assert_contains "$content" "run_cmd sudo" "Uses run_cmd for sudo commands"
}

test_mount_usb_has_find_usb_mount() {
    echo ""
    echo "━━━ mount-usb.sh: USB mount detection ━━━"
    local content
    content=$(cat mount-usb.sh)
    assert_contains "$content" "find_usb_mount()" "Has find_usb_mount function"
    assert_contains "$content" "get_uuid()" "Has get_uuid function"
    assert_contains "$content" "get_fstype()" "Has get_fstype function"
}

test_format_usb_has_detect_usb() {
    echo ""
    echo "━━━ format-usb.sh: USB detection ━━━"
    local content
    content=$(cat format-usb.sh)
    assert_contains "$content" "detect_usb_devices()" "Has detect_usb_devices function"
    assert_contains "$content" "get_device_size()" "Has get_device_size function"
    assert_contains "$content" "human_readable_size()" "Has human_readable_size function"
}

test_format_usb_has_all_formats() {
    echo ""
    echo "━━━ format-usb.sh: All format options ━━━"
    local content
    content=$(cat format-usb.sh)
    assert_contains "$content" "fat32" "Supports FAT32"
    assert_contains "$content" "ext2" "Supports ext2"
    assert_contains "$content" "ext3" "Supports ext3"
    assert_contains "$content" "ext4" "Supports ext4"
    assert_contains "$content" "ntfs" "Supports NTFS"
}

test_format_usb_has_large_drive_check() {
    echo ""
    echo "━━━ format-usb.sh: Large drive protection ━━━"
    local content
    content=$(cat format-usb.sh)
    assert_contains "$content" "34359738368" "Has 32GB threshold check"
    assert_contains "$content" "Really format this drive?" "Has double-confirm for large drives"
}

test_ci_has_bash_syntax_job() {
    echo ""
    echo "━━━ CI: Bash syntax job ━━━"
    local content
    content=$(cat .github/workflows/ci.yml)
    assert_contains "$content" "bash-syntax" "Has bash-syntax job"
    assert_contains "$content" "bash -n format-usb.sh" "Checks format-usb.sh syntax"
    assert_contains "$content" "bash -n mount-usb.sh" "Checks mount-usb.sh syntax"
}

# ── Run all tests ───────────────────────────────────────────────────────
main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  RetroPie-ROMs-on-USB Test Suite                          ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    # format-usb.sh tests
    test_format_usb_exists
    test_format_usb_shebang
    test_format_usb_set_euo_pipefail
    test_format_usb_has_colors
    test_format_usb_has_logging
    test_format_usb_has_confirm
    test_format_usb_has_validation
    test_format_usb_has_dry_run
    test_format_usb_has_menu
    test_format_usb_no_old_patterns

    # mount-usb.sh tests
    test_mount_usb_shebang
    test_mount_usb_set_euo_pipefail
    test_mount_usb_has_methods
    test_mount_usb_has_dry_run
    test_mount_usb_has_config
    test_mount_usb_has_usage
    test_mount_usb_no_old_patterns
    test_mount_usb_no_uncommented_sudo

    # README tests
    test_readme_exists
    test_readme_has_content
    test_readme_has_symlink_docs

    # CI tests
    test_ci_exists
    test_ci_has_shellcheck
    test_ci_has_tests

    # Static analysis
    test_shellcheck_clean
    test_bash_syntax

    # Functional tests
    test_help_flag
    test_dry_run_flag
    test_format_usb_help_flag
    test_format_usb_dry_run_flag

    # README section tests
    test_readme_has_testing_section
    test_readme_has_license_section
    test_readme_has_gource_section
    test_readme_has_format_script_docs
    test_readme_has_mount_script_docs

    # Additional script structure tests
    test_mount_usb_has_log_step
    test_mount_usb_has_run_cmd
    test_mount_usb_has_find_usb_mount
    test_format_usb_has_detect_usb
    test_format_usb_has_all_formats
    test_format_usb_has_large_drive_check

    # CI additional tests
    test_ci_has_bash_syntax_job

    # ── Summary ──────────────────────────────────────────────────────
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  Tests run:    $TESTS_RUN"
    echo "  Passed:       $TESTS_PASSED"
    echo "  Failed:       $TESTS_FAILED"
    echo "════════════════════════════════════════════════════════════"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo ""
        echo "Failed tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
        exit 1
    fi

    echo ""
    echo "All tests passed!"
    exit 0
}

main "$@"
