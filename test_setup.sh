#!/bin/bash

# Test Script for CLS Deployment Setup
# Validates fixes for Ubuntu 22.04/24.04 and root/sudo compatibility

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd ${SCRIPT_DIR}

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test result counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Function to print test results
print_test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [ "$result" = "FAIL" ]; then
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        [ -n "$message" ] && echo -e "  ${RED}Error: $message${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${YELLOW}⚠ SKIP${NC}: $test_name"
        [ -n "$message" ] && echo -e "  ${YELLOW}Reason: $message${NC}"
    fi
}

# Function to print section header
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Test 1: Check if utility files exist
test_utility_files() {
    print_section "Testing Utility Files"

    local files=(
        "utils/ssh_utils.sh"
        "utils/env_utils.sh"
        "utils/system_utils.sh"
    )

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            print_test_result "Utility file exists: $file" "PASS"
        else
            print_test_result "Utility file exists: $file" "FAIL" "File not found"
        fi
    done
}

# Test 2: Check if utility functions can be sourced
test_utility_functions() {
    print_section "Testing Utility Functions"

    # Test SSH utilities
    if source utils/ssh_utils.sh 2>/dev/null; then
        print_test_result "Source SSH utilities" "PASS"

        # Test SSH utility functions
        if declare -f get_user_home >/dev/null 2>&1; then
            print_test_result "SSH function: get_user_home" "PASS"
        else
            print_test_result "SSH function: get_user_home" "FAIL" "Function not found"
        fi

        if declare -f find_ssh_public_key >/dev/null 2>&1; then
            print_test_result "SSH function: find_ssh_public_key" "PASS"
        else
            print_test_result "SSH function: find_ssh_public_key" "FAIL" "Function not found"
        fi
    else
        print_test_result "Source SSH utilities" "FAIL" "Cannot source file"
    fi

    # Test environment utilities
    if source utils/env_utils.sh 2>/dev/null; then
        print_test_result "Source ENV utilities" "PASS"

        if declare -f replace_env_var >/dev/null 2>&1; then
            print_test_result "ENV function: replace_env_var" "PASS"
        else
            print_test_result "ENV function: replace_env_var" "FAIL" "Function not found"
        fi
    else
        print_test_result "Source ENV utilities" "FAIL" "Cannot source file"
    fi

    # Test system utilities
    if source utils/system_utils.sh 2>/dev/null; then
        print_test_result "Source SYSTEM utilities" "PASS"

        if declare -f get_ubuntu_version >/dev/null 2>&1; then
            print_test_result "SYSTEM function: get_ubuntu_version" "PASS"
        else
            print_test_result "SYSTEM function: get_ubuntu_version" "FAIL" "Function not found"
        fi
    else
        print_test_result "Source SYSTEM utilities" "FAIL" "Cannot source file"
    fi
}

# Test 3: Test SSH key detection logic
test_ssh_key_detection() {
    print_section "Testing SSH Key Detection"

    # Source utilities
    if source utils/ssh_utils.sh 2>/dev/null; then
        # Test get_user_home function
        local user_home=$(get_user_home)
        if [ -n "$user_home" ] && [ -d "$user_home" ]; then
            print_test_result "User home detection: $user_home" "PASS"
        else
            print_test_result "User home detection" "FAIL" "Invalid home directory"
        fi

        # Test SSH key discovery
        local ssh_key=$(find_ssh_public_key 2>/dev/null)
        if [ $? -eq 0 ] && [ -f "$ssh_key" ]; then
            print_test_result "SSH key detection: $(basename $ssh_key)" "PASS"
        else
            print_test_result "SSH key detection" "SKIP" "No existing SSH key found (normal for new system)"
        fi
    else
        print_test_result "SSH key detection setup" "FAIL" "Cannot load SSH utilities"
    fi
}

# Test 4: Test environment variable handling
test_env_var_handling() {
    print_section "Testing Environment Variable Handling"

    if source utils/env_utils.sh 2>/dev/null; then
        # Create temporary test file
        local test_file="/tmp/test_env_${RANDOM}.txt"
        echo "TEST_VAR=__TEST_PLACEHOLDER__" > "$test_file"
        echo "ANOTHER_VAR=__ANOTHER_PLACEHOLDER__" >> "$test_file"

        # Test replacement
        if replace_env_var "TEST_PLACEHOLDER" "test_value" "$test_file" >/dev/null 2>&1; then
            if grep -q "TEST_VAR=test_value" "$test_file"; then
                print_test_result "Environment variable replacement" "PASS"
            else
                print_test_result "Environment variable replacement" "FAIL" "Replacement not applied correctly"
            fi
        else
            print_test_result "Environment variable replacement" "FAIL" "Replace function failed"
        fi

        # Test special characters in replacement
        if replace_env_var "ANOTHER_PLACEHOLDER" "special/chars@#$%^&*()" "$test_file" >/dev/null 2>&1; then
            if grep -q "ANOTHER_VAR=special/chars@#" "$test_file"; then
                print_test_result "Special character handling" "PASS"
            else
                print_test_result "Special character handling" "FAIL" "Special characters not handled correctly"
            fi
        else
            print_test_result "Special character handling" "FAIL" "Replace function failed with special chars"
        fi

        # Clean up
        rm -f "$test_file" "${test_file}.bak"
    else
        print_test_result "Environment variable handling setup" "FAIL" "Cannot load ENV utilities"
    fi
}

# Test 5: Test system compatibility
test_system_compatibility() {
    print_section "Testing System Compatibility"

    if source utils/system_utils.sh 2>/dev/null; then
        # Test Ubuntu version detection
        local version=$(get_ubuntu_version)
        if [ "$version" != "unknown" ]; then
            print_test_result "Ubuntu version detection: $version" "PASS"
        else
            print_test_result "Ubuntu version detection" "FAIL" "Could not detect Ubuntu version"
        fi

        # Test user privilege detection
        local user_type=$(get_user_type)
        if [ -n "$user_type" ]; then
            print_test_result "User privilege detection: $user_type" "PASS"
        else
            print_test_result "User privilege detection" "FAIL" "Could not detect user type"
        fi

        # Test supported Ubuntu check
        if is_supported_ubuntu; then
            print_test_result "Supported Ubuntu version check" "PASS"
        else
            print_test_result "Supported Ubuntu version check" "SKIP" "Running on unsupported Ubuntu version"
        fi
    else
        print_test_result "System compatibility setup" "FAIL" "Cannot load SYSTEM utilities"
    fi
}

# Test 6: Test configuration file syntax
test_config_syntax() {
    print_section "Testing Configuration File Syntax"

    # Test main scripts syntax
    local scripts=(
        "1.setup_server.sh"
        "2.configure_project.sh"
        "3.configure_ssl.sh"
    )

    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                print_test_result "Script syntax check: $script" "PASS"
            else
                print_test_result "Script syntax check: $script" "FAIL" "Syntax errors found"
            fi
        else
            print_test_result "Script syntax check: $script" "SKIP" "File not found"
        fi
    done
}

# Test 7: Test .env file handling
test_env_file() {
    print_section "Testing Environment Configuration"

    if [ -f ".env" ]; then
        print_test_result ".env file exists" "PASS"

        # Check for required variables
        local required_vars=("domain" "db" "user" "pass" "repo" "branch")
        local missing_vars=()

        source .env 2>/dev/null

        for var in "${required_vars[@]}"; do
            if [ -z "${!var}" ]; then
                missing_vars+=("$var")
            fi
        done

        if [ ${#missing_vars[@]} -eq 0 ]; then
            print_test_result "Required environment variables" "PASS"
        else
            print_test_result "Required environment variables" "FAIL" "Missing: ${missing_vars[*]}"
        fi
    elif [ -f ".env.example" ]; then
        print_test_result ".env file exists" "SKIP" "Only .env.example found - copy to .env and configure"
    else
        print_test_result ".env file exists" "FAIL" "Neither .env nor .env.example found"
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}CLS Deployment Setup Test Suite${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo "Testing deployment setup fixes for Ubuntu 22.04/24.04 compatibility"
    echo "User: $(whoami)"
    echo "OS: $(lsb_release -d 2>/dev/null | cut -f2- || echo 'Unknown')"

    # Run all tests
    test_utility_files
    test_utility_functions
    test_ssh_key_detection
    test_env_var_handling
    test_system_compatibility
    test_config_syntax
    test_env_file

    # Print summary
    print_section "Test Summary"
    echo -e "Total tests: ${TESTS_TOTAL}"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    echo -e "Skipped: $((TESTS_TOTAL - TESTS_PASSED - TESTS_FAILED))"

    if [ ${TESTS_FAILED} -eq 0 ]; then
        echo -e "\n${GREEN}✓ All tests passed! The deployment setup appears to be working correctly.${NC}"
        exit 0
    else
        echo -e "\n${RED}✗ Some tests failed. Please review the issues above before proceeding.${NC}"
        exit 1
    fi
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
