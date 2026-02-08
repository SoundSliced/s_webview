#!/usr/bin/env bash
set -euo pipefail

# Combined Release and Publishing Script for Flutter/Dart Packages
# This script handles package renaming, verification, GitHub repo creation, and pub.dev publishing
# Run this script from your package root directory (where pubspec.yaml is located)

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="${SCRIPT_DIR%/*}"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
PACKAGE_NAME=""
DESCRIPTION=""
VERSION=""
USERNAME=""

# Logging functions
print_info()    { echo -e "${BLUE}INFO:${NC} $1"; }
print_success() { echo -e "${GREEN}SUCCESS:${NC} $1"; }
print_warning() { echo -e "${YELLOW}WARNING:${NC} $1"; }
print_error()   { echo -e "${RED}ERROR:${NC} $1"; }

# Utility: confirm prompt (returns 0 for yes, 1 for no)
confirm() {
    local message="$1" default="${2:-n}" response
    local prompt="[y/N]"
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    fi
    
    read -rp "$message $prompt: " response
    response="${response:-$default}"
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Utility: check if file contains pattern
file_has_pattern() {
    grep -qE "$2" "$1" 2>/dev/null
}

# Utility: add line after pattern in file (macOS compatible)
add_line_after() {
    local file="$1" pattern="$2" line="$3"
    sed -i '' "/$pattern/a\\
$line" "$file"
}

# Get package info from pubspec.yaml
get_package_info() {
    if [[ ! -f "pubspec.yaml" ]]; then
        print_error "pubspec.yaml not found. Run from package root."
        exit 1
    fi
    
    PACKAGE_NAME=$(awk '/^name:/{print $2}' pubspec.yaml | tr -d ' ')
    DESCRIPTION=$(awk '/^description:/{$1=""; print substr($0,2)}' pubspec.yaml | sed 's/^"\|"$//g')
    VERSION=$(awk '/^version:/{print $2}' pubspec.yaml | tr -d ' ')
    
    if [[ -z "$PACKAGE_NAME" ]]; then
        print_error "Could not find package name in pubspec.yaml"
        exit 1
    fi
    
    print_info "Package: $PACKAGE_NAME | Version: $VERSION"
    return 0
}

# Organize root-level shell scripts into scripts/ directory
organize_shell_scripts() {
    [[ -f "pubspec.yaml" ]] || return 0
    mkdir -p scripts
    
    local moved=false
    for f in ./*.sh; do
        [[ -e "$f" ]] || continue
        mv "$f" scripts/ 2>/dev/null && { print_info "Moved $(basename "$f") to scripts/"; moved=true; }
    done
    
    if [[ "$moved" == true ]]; then
        print_success "Shell scripts consolidated into scripts/"
    fi
    return 0
}

# Ensure .gitattributes excludes shell scripts from language stats
ensure_gitattributes() {
    local file=".gitattributes"
    touch "$file"
    
    if ! file_has_pattern "$file" '^\*\.sh[[:space:]]+linguist-vendored'; then
        echo "*.sh linguist-vendored" >> "$file"
        print_info "Added '*.sh linguist-vendored' to .gitattributes"
    fi
    if ! file_has_pattern "$file" '^build/\*[[:space:]]+linguist-generated'; then
        echo "build/* linguist-generated" >> "$file"
        print_info "Added 'build/* linguist-generated' to .gitattributes"
    fi
    return 0
}

# Create or update .gitignore
ensure_gitignore() {
    local file=".gitignore"
    local is_git_repo=false
    [[ -d .git ]] && is_git_repo=true
    
    if [[ ! -f "$file" ]]; then
        cat > "$file" <<'EOF'
# Dart/Flutter build artifacts
build/
.dart_tool/
.packages

# Example build artifacts
example/build/
example/.dart_tool/
example/.packages

# IDE and editor files
.vscode/
.idea/
*.iml
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Test cache
test/.test_cache/
.test_cache/

# Generated files
*.g.dart
*.freezed.dart
*.mocks.dart

# Coverage
coverage/

# Pubspec lock (optional for packages)
# pubspec.lock
EOF
        print_info "Created .gitignore to exclude build artifacts"
    else
        # Add missing critical patterns
        local patterns=("build/" ".dart_tool/" "example/build/" ".DS_Store")
        for pattern in "${patterns[@]}"; do
            if ! grep -q "^${pattern}$" "$file"; then
                echo "$pattern" >> "$file"
                print_info "Added '$pattern' to .gitignore"
            fi
        done
    fi
    
    # Remove directories/files from git tracking if already tracked
    if [[ "$is_git_repo" == true ]]; then
        local dirs_to_untrack=("build/" ".dart_tool/" "example/build/" "example/.dart_tool/")
        for dir in "${dirs_to_untrack[@]}"; do
            if git ls-files --error-unmatch "$dir" >/dev/null 2>&1; then
                print_info "Removing $dir from git tracking..."
                git rm -r --cached "$dir" 2>/dev/null || true
            fi
        done
        
        # Remove .DS_Store files from git tracking
        local ds_files
        ds_files=$(git ls-files '*.DS_Store' '.DS_Store' '*/.DS_Store' 2>/dev/null)
        if [[ -n "$ds_files" ]]; then
            print_info "Removing .DS_Store files from git tracking..."
            echo "$ds_files" | xargs git rm --cached 2>/dev/null || true
        fi
        
        print_success "Ignored files removed from git tracking"
    fi
    return 0
}

# Create or update .pubignore
ensure_pubignore() {
    local file=".pubignore"
    
    if [[ ! -f "$file" ]]; then
        cat > "$file" <<'EOF'
# Scripts
scripts/
*.sh

# Build artifacts and cache
build/
.dart_tool/
.packages
example/build/
example/.dart_tool/
example/.packages

# IDE and editor files
.vscode/
.idea/
*.iml
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Test cache
test/.test_cache/
.test_cache/
EOF
        print_info "Created .pubignore with comprehensive exclusions"
        return 0
    fi
    
    # Add missing patterns
    local patterns=("scripts/" "*.sh" "build/" ".dart_tool/" "example/build/")
    for pattern in "${patterns[@]}"; do
        if ! grep -q "^${pattern}$" "$file"; then
            echo "$pattern" >> "$file"
        fi
    done
    return 0
}

# Check for uncommitted changes and commit
commit_changes() {
    local has_changes=false
    git diff --quiet 2>/dev/null || has_changes=true
    git diff --cached --quiet 2>/dev/null || has_changes=true
    [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]] && has_changes=true
    
    if [[ "$has_changes" == false ]]; then
        print_info "Working directory clean, nothing to commit"
        return 0
    fi
    
    print_info "Committing changes..."
    git add -A
    git commit -m "Release version $VERSION

- Updated version, documentation, and configuration
- Organized scripts and added .gitattributes/.pubignore" || print_warning "Nothing to commit"
    return 0
}

# Update version in pubspec.yaml and add CHANGELOG entry
update_version() {
    local new_version="$1"
    if [[ "$new_version" == "$VERSION" ]]; then
        return 0
    fi
    
    print_info "Updating version from $VERSION to $new_version..."
    
    # Update pubspec.yaml
    sed -i '' "s/^version: .*/version: $new_version/" pubspec.yaml
    
    # Update CHANGELOG.md
    if [[ -f "CHANGELOG.md" ]] && ! grep -q "## $new_version" CHANGELOG.md; then
        { echo -e "## $new_version\n\n* Version $new_version\n"; cat CHANGELOG.md; } > CHANGELOG.md.tmp
        mv CHANGELOG.md.tmp CHANGELOG.md
    fi
    
    # Update README.md version references
    if [[ -f "README.md" ]]; then
        sed -i '' -e "s/version-[0-9]\+\.[0-9]\+\.[0-9]\+/version-$new_version/g" \
                  -e "s/$PACKAGE_NAME: \^[0-9]\+\.[0-9]\+\.[0-9]\+/$PACKAGE_NAME: ^$new_version/g" \
                  -e "s/$PACKAGE_NAME: [0-9]\+\.[0-9]\+\.[0-9]\+/$PACKAGE_NAME: $new_version/g" README.md
    fi
    
    VERSION="$new_version"
    print_success "Version updated to $new_version"
    return 0
}

# Update GitHub username in all relevant files
update_github_username() {
    local username="$1" old_username="${2:-}"
    print_info "Updating GitHub username to '$username'..."
    
    local github_url="https://github.com/$username/$PACKAGE_NAME"
    
    # Update pubspec.yaml URLs
    for field in homepage repository issue_tracker; do
        local url="$github_url"
        [[ "$field" == "issue_tracker" ]] && url="$github_url/issues"
        
        if grep -q "^${field}:" pubspec.yaml; then
            sed -i '' "s|^${field}:.*|${field}: $url|" pubspec.yaml
        else
            add_line_after pubspec.yaml "^description:" "${field}: $url"
        fi
    done
    
    # Update other files if old username exists
    if [[ -n "$old_username" && "$old_username" != "$username" ]]; then
        for file in README.md CHANGELOG.md LICENSE; do
            [[ -f "$file" ]] && sed -i '' "s|github.com/$old_username/|github.com/$username/|g" "$file"
        done
    fi
    
    # Update LICENSE copyright
    [[ -f "LICENSE" ]] && sed -i '' "s/Copyright (c) [0-9]\{4\} .*/Copyright (c) $(date +%Y) $username/" LICENSE
    
    print_success "GitHub username updated to '$username'"
    return 0
}

# Rename package (optional)
rename_package() {
    print_info "Current package name: $PACKAGE_NAME"
    if ! confirm "Rename the package?"; then
        return 0
    fi
    
    local new_name
    while true; do
        read -rp "Enter new package name (lowercase, underscores only): " new_name
        [[ "$new_name" =~ ^[a-z][a-z0-9_]*$ ]] && break
        print_error "Invalid name. Must start with lowercase letter, contain only [a-z0-9_]"
    done
    
    local old_name="$PACKAGE_NAME"
    print_info "Renaming '$old_name' to '$new_name'..."
    
    # Rename files
    [[ -f "lib/$old_name.dart" ]] && mv "lib/$old_name.dart" "lib/$new_name.dart"
    [[ -f "lib/src/$old_name.dart" ]] && mv "lib/src/$old_name.dart" "lib/src/$new_name.dart"
    [[ -f "test/${old_name}_test.dart" ]] && mv "test/${old_name}_test.dart" "test/${new_name}_test.dart"
    
    # Update all references in Dart files
    find lib test example -name "*.dart" -type f 2>/dev/null | xargs -I{} sed -i '' \
        -e "s/package:$old_name/package:$new_name/g" \
        -e "s/library $old_name/library $new_name/g" \
        -e "s/src\/$old_name\.dart/src\/$new_name\.dart/g" {}
    
    # Update config files
    sed -i '' "s/^name: $old_name$/name: $new_name/" pubspec.yaml
    sed -i '' "s|/$old_name|/$new_name|g" pubspec.yaml
    [[ -f "example/pubspec.yaml" ]] && sed -i '' "s/$old_name/$new_name/g" example/pubspec.yaml
    
    # Update documentation
    for file in README.md CHANGELOG.md; do
        [[ -f "$file" ]] && sed -i '' "s/$old_name/$new_name/g" "$file"
    done
    
    PACKAGE_NAME="$new_name"
    print_success "Package renamed to '$new_name'"
    
    # Optionally rename directory
    local current_dir=$(basename "$PWD")
    if [[ "$current_dir" != "$new_name" ]] && confirm "Rename directory to '$new_name'?" y; then
        local parent_dir=$(dirname "$PWD")
        local new_path="$parent_dir/$new_name"
        
        if [[ -d "$new_path" ]]; then
            print_error "Directory '$new_path' already exists"
        else
            cd "$parent_dir" && mv "$current_dir" "$new_name" && cd "$new_name"
            print_success "Directory renamed. New path: $PWD"
            command -v code >/dev/null && code "$PWD"
            print_warning "Exiting. Re-run script after VS Code reopens."
            exit 0
        fi
    fi
    
    if confirm "Run tests to verify?"; then
        flutter test || print_warning "Tests failed"
    fi
    return 0
}

# Run verification checklist
run_verification() {
    print_info "Running verification checklist..."
    
    # Prompt for documentation review with Copilot
    if confirm "Use Copilot AI to review and update documentation for version $VERSION?"; then
        echo ""
        print_info "Please ask Copilot AI in VS Code to help with the following:"
        echo ""
        echo "  ${YELLOW}Suggested prompt for Copilot:${NC}"
        echo "  ─────────────────────────────────────────────────────────────────"
        echo "  I'm releasing version $VERSION to GitHub and pub.dev."
        echo "  Please help ensure documentation is complete:"
        echo ""
        echo "  - Create/update example/ folder as a Flutter app with basic & advanced examples"
        echo "  - Create/update tests reflecting package features"
        echo "  - Ensure MIT LICENSE file exists"
        echo "  - Update CHANGELOG.md with version $VERSION and describe changes"
        echo "  - Update README.md with accurate description, features, and usage examples"
        echo "  - If example/ contains GIF/PNG/JPEG assets, add them to README.md using"
        echo "    GitHub raw URLs (e.g., https://raw.githubusercontent.com/$USERNAME/$PACKAGE_NAME/main/example/assets/example.gif)"
        echo "  - Ensure README.md shows both basic and advanced usage examples"
        echo "  ─────────────────────────────────────────────────────────────────"
        echo ""
        if confirm "Press Enter when documentation is updated"; then
            print_success "Documentation reviewed"
        fi
    fi
    
    # Version consistency check
    if ! grep -q "^version: $VERSION$" pubspec.yaml; then
        print_error "Version mismatch in pubspec.yaml"
        exit 1
    fi
    
    # Documentation warnings
    if [[ -f "README.md" ]] && ! grep -q "$VERSION" README.md; then
        print_warning "Version not in README.md"
    fi
    if [[ -f "CHANGELOG.md" ]] && ! grep -q "$VERSION" CHANGELOG.md; then
        print_warning "Version not in CHANGELOG.md"
    fi
    
    # Check for tests and examples
    if [[ -z "$(find test -name '*.dart' 2>/dev/null)" ]]; then
        print_warning "No test files found"
    fi
    if [[ ! -f "example/lib/main.dart" ]]; then
        print_warning "No example code found"
    fi
    
    # Run Flutter checks
    print_info "Running analysis..."
    flutter analyze || { print_error "Analysis failed"; exit 1; }
    
    print_info "Running tests..."
    flutter test || { print_error "Tests failed"; exit 1; }
    
    print_info "Formatting code..."
    dart format .
    
    print_info "Running dry-run publish..."
    flutter pub get
    flutter pub publish --dry-run || { print_error "Dry-run failed"; exit 1; }
    
    print_success "Verification complete!"
    return 0
}

# Initialize git repository
ensure_git_repo() {
    if [[ ! -d .git ]]; then
        print_info "Initializing git repository..."
        git init
        git add .
        git commit -m "Initial commit"
    fi
    git branch -M main 2>/dev/null || true
    return 0
}

# Create MIT license if missing
create_license_if_missing() {
    if [[ -f LICENSE || -f LICENSE.md ]]; then
        return 0
    fi
    
    print_info "Creating MIT LICENSE..."
    cat > LICENSE <<EOF
MIT License

Copyright (c) $(date +%Y) $USERNAME

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
    git add LICENSE
    git commit -m "Add MIT license" || true
    return 0
}

# Setup GitHub repository
create_github_repo() {
    print_info "Setting up GitHub repository..."
    ensure_git_repo
    
    local repo="$USERNAME/$PACKAGE_NAME"
    local remote_url="https://github.com/$repo.git"
    
    if command -v gh >/dev/null 2>&1; then
        # Ensure authenticated
        gh auth status >/dev/null 2>&1 || gh auth login
        
        if gh repo view "$repo" >/dev/null 2>&1; then
            print_info "Repository exists, pushing..."
        else
            print_info "Creating repository..."
            gh repo create "$repo" --public --description "$DESCRIPTION"
        fi
        
        git remote remove origin 2>/dev/null || true
        git remote add origin "$remote_url"
        git push -u origin main
    else
        # Fallback to GitHub API
        if [[ -z "${GITHUB_TOKEN:-}" ]]; then
            print_error "GITHUB_TOKEN not set. Install gh CLI or set token."
            exit 1
        fi
        
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$repo")
        
        if [[ "$status" == "404" ]]; then
            print_info "Creating repository via API..."
            curl -s -H "Authorization: token $GITHUB_TOKEN" \
                -d "{\"name\":\"$PACKAGE_NAME\",\"description\":\"$DESCRIPTION\",\"private\":false}" \
                "https://api.github.com/user/repos"
        fi
        
        git remote remove origin 2>/dev/null || true
        git remote add origin "$remote_url"
        git push -u origin main
    fi
    
    create_license_if_missing
    print_success "GitHub repository ready!"
    return 0
}

# Publish to pub.dev
publish_to_pubdev() {
    print_info "Publishing to pub.dev..."
    
    # Final dry-run
    if ! flutter pub publish --dry-run; then
        print_error "Dry-run failed"
        return 1
    fi
    
    if ! confirm "Proceed with publishing?"; then
        print_info "Cancelled"
        return 0
    fi
    
    flutter pub publish
    print_success "Published! Visit: https://pub.dev/packages/$PACKAGE_NAME"
    return 0
}

# Create GitHub release
create_github_release() {
    print_info "Creating GitHub release v$VERSION..."
    
    git tag -a "v$VERSION" -m "Release version $VERSION"
    git push origin "v$VERSION"
    
    if command -v gh >/dev/null 2>&1; then
        gh release create "v$VERSION" --title "Release v$VERSION" --notes-file CHANGELOG.md
    else
        print_info "Create release manually: https://github.com/$USERNAME/$PACKAGE_NAME/releases/new"
    fi
    
    print_success "GitHub release created!"
    return 0
}

# Main entry point
main() {
    echo "========================================"
    echo "Flutter Package Release & Publish Script"
    echo "========================================"
    
    # Initialize
    get_package_info
    organize_shell_scripts
    ensure_gitignore
    ensure_gitattributes
    ensure_pubignore
    
    # Optional package rename
    rename_package
    get_package_info  # Reload after potential rename
    
    # Get/update GitHub username
    local old_username=""
    if grep -q "github.com/" pubspec.yaml; then
        old_username=$(grep "github.com/" pubspec.yaml | head -1 | sed 's|.*github.com/||; s|/.*||')
    fi
    
    read -rp "GitHub username [$old_username]: " USERNAME
    USERNAME="${USERNAME:-$old_username}"
    if [[ -z "$USERNAME" ]]; then
        print_error "GitHub username required"
        exit 1
    fi
    
    update_github_username "$USERNAME" "$old_username"
    
    # Version update
    read -rp "Version [$VERSION]: " new_version
    new_version="${new_version:-$VERSION}"
    
    # Validate semver format
    if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.+-]+)?(\+[a-zA-Z0-9.+-]+)?$ ]]; then
        print_error "Invalid version format (use semver: 0.0.1, 1.0.0-beta)"
        exit 1
    fi
    
    update_version "$new_version"
    get_package_info
    
    # Summary
    echo -e "\n${GREEN}Configuration:${NC}"
    echo "  Package: $PACKAGE_NAME"
    echo "  Version: $VERSION"
    echo "  GitHub:  $USERNAME/$PACKAGE_NAME"
    echo ""
    
    # Execute steps
    commit_changes
    if confirm "Run verification?" y; then
        run_verification
    fi
    if confirm "Setup GitHub repository?" y; then
        create_github_repo
    fi
    if confirm "Publish to pub.dev?" y; then
        publish_to_pubdev
    fi
    if confirm "Create GitHub release?" y; then
        create_github_release
    fi
    
    print_success "All done! Package released and published."
}

main "$@"