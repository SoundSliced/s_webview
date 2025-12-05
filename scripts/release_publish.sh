#!/usr/bin/env bash
set -euo pipefail

# Combined Release and Publishing Script for Flutter/Dart Packages
# This script handles package renaming, verification, GitHub repo creation, and pub.dev publishing
# Run this script from your package root directory (where pubspec.yaml is located)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

print_success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

# Function to organize root-level shell scripts into scripts/ directory
organize_shell_scripts() {
    print_info "Organizing shell scripts in repository root..."
    local repo_root="$PWD"
    # Ensure we're at package root (pubspec.yaml should exist here)
    if [[ ! -f "$repo_root/pubspec.yaml" ]]; then
        print_warning "Current directory does not contain pubspec.yaml; skipping shell script organization."
        return
    fi
    mkdir -p "$repo_root/scripts"
    local moved_any=false
    # Iterate over root-level .sh files (exclude glob if none)
    for f in "$repo_root"/*.sh; do
        if [[ ! -e "$f" ]]; then
            continue
        fi
        local base_name="$(basename "$f")"
        # Skip if already inside scripts or if file is this release script (which resides in scripts/)
        if [[ "$f" == "$repo_root/scripts/release_publish.sh" ]]; then
            continue
        fi
        # Move file
        mv "$f" "$repo_root/scripts/" 2>/dev/null || {
            print_warning "Could not move $base_name"
            continue
        }
        print_info "Moved $base_name to scripts/"
        moved_any=true
    done
    if [[ "$moved_any" == true ]]; then
        print_success "Shell scripts consolidated into scripts/ directory."
    else
        print_info "No root-level shell scripts needed moving."
    fi
}

# Function to ensure .gitattributes excludes shell scripts from language stats
ensure_gitattributes() {
    local repo_root="$PWD"
    local file="$repo_root/.gitattributes"
    touch "$file"
    # Add linguist-vendored for all .sh scripts if not present
    if ! grep -qE '^\*\.sh[[:space:]]+linguist-vendored' "$file"; then
        echo "*.sh linguist-vendored" >> "$file"
        print_info "Added '*.sh linguist-vendored' to .gitattributes"
    fi
    # Add build/* linguist-generated to hide build artifacts
    if ! grep -qE '^build/\*[[:space:]]+linguist-generated' "$file"; then
        echo "build/* linguist-generated" >> "$file"
        print_info "Added 'build/* linguist-generated' to .gitattributes"
    fi
    print_success ".gitattributes updated for GitHub Linguist language detection."
}

# Function to create or update .pubignore to exclude scripts from published package
ensure_pubignore() {
    local repo_root="$PWD"
    local file="$repo_root/.pubignore"
    
    # Create .pubignore if it doesn't exist
    if [[ ! -f "$file" ]]; then
        cat > "$file" <<'EOF'
# Exclude scripts directory from published package
scripts/
*.sh
EOF
        print_info "Created .pubignore to exclude scripts from published package"
    else
        # Add scripts/ if not present
        if ! grep -q '^scripts/' "$file"; then
            echo "scripts/" >> "$file"
            print_info "Added 'scripts/' to .pubignore"
        fi
        # Add *.sh if not present
        if ! grep -q '^\\.sh' "$file" && ! grep -q '^\\*\\.sh' "$file"; then
            echo "*.sh" >> "$file"
            print_info "Added '*.sh' to .pubignore"
        fi
    fi
}

# Function to commit pending changes before verification
commit_changes() {
    # Check if there are any changes to commit
    if ! git diff --quiet || ! git diff --cached --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
        print_info "Committing changes before verification..."
        
        # Add all modified and new files
        git add -A
        
        # Create commit message
        local commit_msg="Update package to version $VERSION

- Updated version to $VERSION
- Updated documentation (CHANGELOG.md, README.md)
- Organized shell scripts into scripts/ directory
- Added .gitattributes for GitHub Linguist
- Added .pubignore to exclude scripts from published package"
        
        git commit -m "$commit_msg" || {
            print_warning "Git commit failed or nothing to commit"
            return 1
        }
        
        print_success "Changes committed successfully"
    else
        print_info "No changes to commit, working directory is clean"
    fi
}

# Function to prompt user for confirmation
confirm() {
    local message="$1"
    local default="${2:-n}"
    local response

    if [[ "$default" == "y" ]]; then
        read -p "$message [Y/n]: " response
        response=${response:-y}
    else
        read -p "$message [y/N]: " response
        response=${response:-n}
    fi

    [[ "$response" =~ ^[Yy]$ ]]
}

# Function to get package info from pubspec.yaml
get_package_info() {
    if [[ ! -f "pubspec.yaml" ]]; then
        print_error "pubspec.yaml not found. Please run this script from your package root directory."
        exit 1
    fi

    PACKAGE_NAME=$(grep '^name:' pubspec.yaml | sed 's/name: //' | tr -d ' ')
    DESCRIPTION=$(grep '^description:' pubspec.yaml | sed 's/description: //' | tr -d '\n' | sed 's/^"//' | sed 's/"$//')
    VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')

    if [[ -z "$PACKAGE_NAME" ]]; then
        print_error "Could not find package name in pubspec.yaml"
        exit 1
    fi

    print_info "Package: $PACKAGE_NAME"
    print_info "Version: $VERSION"
    print_info "Description: $DESCRIPTION"
}

# Function to update version across all files
update_version() {
    local new_version="$1"
    local old_version="$VERSION"
    
    print_info "Updating version from $old_version to $new_version in all files..."
    
    # Update pubspec.yaml
    sed -i '' "s/^version: .*/version: $new_version/" pubspec.yaml
    
    # Update CHANGELOG.md - add new version entry at the top if not present
    if [[ -f "CHANGELOG.md" ]]; then
        if ! grep -q "## $new_version" CHANGELOG.md; then
            # Create a temporary file with the new version entry
            {
                echo "## $new_version"
                echo ""
                echo "* Version $new_version"
                echo ""
                cat CHANGELOG.md
            } > CHANGELOG.md.tmp
            mv CHANGELOG.md.tmp CHANGELOG.md
        fi
    fi
    
    # Update README.md - replace version references
    if [[ -f "README.md" ]]; then
        # Update version badge if present
        sed -i '' "s/version-[0-9]\+\.[0-9]\+\.[0-9]\+/version-$new_version/g" README.md
        # Update version in dependencies examples
        sed -i '' "s/$PACKAGE_NAME: \^[0-9]\+\.[0-9]\+\.[0-9]\+/$PACKAGE_NAME: ^$new_version/g" README.md
        sed -i '' "s/$PACKAGE_NAME: [0-9]\+\.[0-9]\+\.[0-9]\+/$PACKAGE_NAME: $new_version/g" README.md
    fi
    
    VERSION="$new_version"
    print_success "Version updated to $new_version"
}

# Function to update GitHub username across all files
update_github_username() {
    local username="$1"
    local old_username="${2:-}"
    
    print_info "Updating GitHub username to '$username' in all files..."
    
    # Update pubspec.yaml
    if grep -q "^homepage:" pubspec.yaml; then
        if [[ -n "$old_username" ]]; then
            sed -i '' "s|https://github.com/$old_username/|https://github.com/$username/|g" pubspec.yaml
        else
            sed -i '' "s|^homepage:.*|homepage: https://github.com/$username/$PACKAGE_NAME|" pubspec.yaml
        fi
    else
        sed -i '' "/^description:/a\\
homepage: https://github.com/$username/$PACKAGE_NAME" pubspec.yaml
    fi
    
    if grep -q "^repository:" pubspec.yaml; then
        if [[ -n "$old_username" ]]; then
            sed -i '' "s|https://github.com/$old_username/|https://github.com/$username/|g" pubspec.yaml
        else
            sed -i '' "s|^repository:.*|repository: https://github.com/$username/$PACKAGE_NAME|" pubspec.yaml
        fi
    else
        sed -i '' "/^description:/a\\
repository: https://github.com/$username/$PACKAGE_NAME" pubspec.yaml
    fi
    
    if grep -q "^issue_tracker:" pubspec.yaml; then
        if [[ -n "$old_username" ]]; then
            sed -i '' "s|https://github.com/$old_username/|https://github.com/$username/|g" pubspec.yaml
        else
            sed -i '' "s|^issue_tracker:.*|issue_tracker: https://github.com/$username/$PACKAGE_NAME/issues|" pubspec.yaml
        fi
    else
        sed -i '' "/^description:/a\\
issue_tracker: https://github.com/$username/$PACKAGE_NAME/issues" pubspec.yaml
    fi
    
    # Update README.md
    if [[ -f "README.md" ]]; then
        if [[ -n "$old_username" ]]; then
            sed -i '' "s|github.com/$old_username/|github.com/$username/|g" README.md
        fi
        # Add repository link if not present
        if ! grep -q "github.com/$username/$PACKAGE_NAME" README.md; then
            echo "" >> README.md
            echo "## Repository" >> README.md
            echo "" >> README.md
            echo "https://github.com/$username/$PACKAGE_NAME" >> README.md
        fi
    fi
    
    # Update CHANGELOG.md
    if [[ -f "CHANGELOG.md" ]] && [[ -n "$old_username" ]]; then
        sed -i '' "s|github.com/$old_username/|github.com/$username/|g" CHANGELOG.md
    fi
    
    # Update LICENSE
    if [[ -f "LICENSE" ]]; then
        if grep -q "Copyright (c)" LICENSE; then
            sed -i '' "s/Copyright (c) [0-9]\{4\} .*/Copyright (c) $(date +%Y) $username/" LICENSE
        fi
    fi
    
    # Update any other .md files
    find . -name "*.md" -not -path "./.git/*" -not -name "README.md" -not -name "CHANGELOG.md" | while read -r file; do
        if [[ -n "$old_username" ]]; then
            sed -i '' "s|github.com/$old_username/|github.com/$username/|g" "$file"
        fi
    done
    
    print_success "GitHub username updated to '$username'"
}

# Function to rename package
rename_package() {
    print_info "Current package name: $PACKAGE_NAME"

    if ! confirm "Do you want to rename the package?"; then
        print_info "Skipping package renaming."
        return
    fi

    local new_name
    while true; do
        read -p "Enter the new package name (lowercase, underscores only): " new_name
        if [[ -z "$new_name" ]]; then
            print_error "Package name cannot be empty"
            continue
        fi
        if ! echo "$new_name" | grep -q '^[a-z][a-z0-9_]*$'; then
            print_error "Package name must start with lowercase letter and contain only lowercase letters, numbers, and underscores"
            continue
        fi
        break
    done

    local old_name="$PACKAGE_NAME"
    print_info "Renaming package from '$old_name' to '$new_name'"

    # Rename main library file
    if [[ -f "lib/$old_name.dart" ]]; then
        print_info "Renaming lib/$old_name.dart to lib/$new_name.dart"
        mv "lib/$old_name.dart" "lib/$new_name.dart"
        # Update content inside the file
        sed -i '' "s/library $old_name;/library $new_name;/" "lib/$new_name.dart"
        sed -i '' "s/src\/$old_name\.dart/src\/$new_name\.dart/g" "lib/$new_name.dart"
        sed -i '' "s/package:$old_name/package:$new_name/g" "lib/$new_name.dart"
    fi

    # Rename src file
    if [[ -f "lib/src/$old_name.dart" ]]; then
        print_info "Renaming lib/src/$old_name.dart to lib/src/$new_name.dart"
        mv "lib/src/$old_name.dart" "lib/src/$new_name.dart"
        # Update content inside the file
        sed -i '' "s/$old_name/$new_name/g" "lib/src/$new_name.dart"
        sed -i '' "s/package:$old_name/package:$new_name/g" "lib/src/$new_name.dart"
    fi

    # Rename test file
    if [[ -f "test/${old_name}_test.dart" ]]; then
        print_info "Renaming test/${old_name}_test.dart to test/${new_name}_test.dart"
        mv "test/${old_name}_test.dart" "test/${new_name}_test.dart"
        # Update imports in test file
        sed -i '' "s/package:$old_name/package:$new_name/g" "test/${new_name}_test.dart"
        sed -i '' "s/$old_name/$new_name/g" "test/${new_name}_test.dart"
    fi

    # Update pubspec.yaml
    sed -i '' "s/^name: $old_name$/name: $new_name/" pubspec.yaml
    # Update description if it contains old package name
    sed -i '' "s/$old_name/$new_name/g" pubspec.yaml
    # Update URLs in pubspec.yaml
    sed -i '' "s|/$old_name|/$new_name|g" pubspec.yaml

    # Update imports in example
    if [[ -f "example/lib/main.dart" ]]; then
        sed -i '' "s/package:$old_name/package:$new_name/g" example/lib/main.dart
        sed -i '' "s/$old_name/$new_name/g" example/lib/main.dart
    fi
    
    # Update example's pubspec.yaml if it exists
    if [[ -f "example/pubspec.yaml" ]]; then
        sed -i '' "s/$old_name/$new_name/g" example/pubspec.yaml
    fi

    # Update documentation files
    for file in README.md CHANGELOG.md; do
        if [[ -f "$file" ]]; then
            sed -i '' "s/$old_name/$new_name/g" "$file"
        fi
    done

    # Update other .md files
    find . -name "*.md" -not -path "./.git/*" -not -name "README.md" -not -name "CHANGELOG.md" | while read -r file; do
        sed -i '' "s/$old_name/$new_name/g" "$file"
    done
    
    # Update all Dart files for any remaining references
    find lib -name "*.dart" -type f | while read -r file; do
        sed -i '' "s/package:$old_name/package:$new_name/g" "$file"
    done
    
    find test -name "*.dart" -type f | while read -r file; do
        sed -i '' "s/package:$old_name/package:$new_name/g" "$file"
    done

    PACKAGE_NAME="$new_name"
    
    # Rename the project directory itself
    local current_dir=$(basename "$PWD")
    local project_renamed=false
    if [[ "$current_dir" != "$new_name" ]]; then
        if confirm "Rename the project directory from '$current_dir' to '$new_name'?" y; then
            local parent_dir=$(dirname "$PWD")
            local new_project_path="$parent_dir/$new_name"
            
            # Check if target directory already exists
            if [[ -d "$new_project_path" ]]; then
                print_error "Directory '$new_project_path' already exists. Cannot rename project directory."
            else
                print_info "Renaming project directory from '$current_dir' to '$new_name'"
                cd "$parent_dir"
                mv "$current_dir" "$new_name"
                cd "$new_name"
                print_success "Project directory renamed successfully!"
                print_warning "Your working directory has changed to: $PWD"
                project_renamed=true
                
                # Reopen VS Code in the new directory
                print_info "Reopening VS Code in the new directory..."
                if command -v code >/dev/null 2>&1; then
                    # Close current window and open new one
                    code "$PWD"
                    print_success "VS Code will reopen in the new directory"
                else
                    print_warning "VS Code 'code' command not found. Please manually reopen VS Code in: $PWD"
                fi
            fi
        fi
    fi
    
    print_success "Package renamed successfully!"
    
    if [[ "$project_renamed" == true ]]; then
        print_warning "IMPORTANT: The script will now exit to allow VS Code to reopen in the new directory."
        print_info "After VS Code reopens, you can re-run this script to continue with publishing if needed."
        if confirm "Exit now to let VS Code reopen?" y; then
            exit 0
        fi
    fi

    if confirm "Run tests to verify changes?"; then
        flutter test || print_warning "Tests failed, but continuing..."
    fi

    print_info "Next steps: Review changes with 'git status', then commit with 'git add . && git commit -m \"Rename package to $PACKAGE_NAME\"'"
}

# Function to run verification checklist
run_verification() {
    print_info "Running release verification checklist..."

    # Documentation review with Copilot
    print_info "Ensuring documentation is up to date..."
    if confirm "Use Copilot AI to review and update CHANGELOG.md, README.md, and other documentation to reflect the current version ($VERSION) and package functionality?"; then
        print_info "Please use Copilot AI in VS Code to update the documentation files."
        print_info "Ask Copilot to:"
        print_info "  - Ensure to create or update as necessary example folder and tests, with the updates made to the package (if any relevant)"
        print_info "  - Ensure to create or update an MIT license file if missing"
        print_info "  - Ensure CHANGELOG.md includes the current version $VERSION and describes changes"
        print_info "  - Update README.md to accurately describe the package, its features, and include example usage, with the updates made to the package (if any relevant)"
        print_info "  - Verify all MD files are up to date with the latest package information"
        print_info "  - Ensure README.md reflects the examples in the example/ directory"
        print_info "  - unless already done, if there are any asset png or GIF or JPEG... files within the example folder, Add these screenshot files into the package's README (giving them the github path to the example folder, rather than a local path to it) to visually show a few examples of this package (basic and advanced usage) when the package is published to pub.dev."
        if confirm "Press enter when documentation is updated"; then
            print_success "Documentation updated via Copilot."
        fi
    fi

    # Version consistency
    print_info "Checking version consistency..."
    if ! grep -q "^version: $VERSION$" pubspec.yaml; then
        print_error "Version mismatch in pubspec.yaml"
        exit 1
    fi

    # Documentation checks
    if [[ -f "README.md" ]]; then
        if ! grep -q "$VERSION" README.md; then
            print_warning "Version not found in README.md"
        fi
        if ! grep -qi "example" README.md; then
            print_warning "README.md does not mention examples. Consider adding example usage."
        fi
    else
        print_warning "README.md not found"
    fi

    if [[ -f "CHANGELOG.md" ]]; then
        if ! grep -q "$VERSION" CHANGELOG.md; then
            print_warning "Version not found in CHANGELOG.md"
        fi
    else
        print_warning "CHANGELOG.md not found"
    fi

    # Test files check
    print_info "Checking for test files..."
    if [[ ! -d "test" ]] || [[ -z "$(find test -name "*.dart" 2>/dev/null)" ]]; then
        print_warning "No test files found in test/ directory."
        print_info "Use Copilot AI to generate comprehensive tests for your package."
        if ! confirm "Continue without tests?"; then
            exit 1
        fi
    fi

    # Example code check
    print_info "Checking for example code..."
    if [[ ! -d "example" ]] || [[ ! -f "example/lib/main.dart" ]]; then
        print_warning "No example code found in example/ directory."
        print_info "Use Copilot AI to create example usage code demonstrating the package functionality."
        if ! confirm "Continue without example?"; then
            exit 1
        fi
    fi

    # Code checks
    print_info "Running flutter analyze..."
    if ! flutter analyze; then
        print_error "Analysis failed"
        exit 1
    fi

    print_info "Running flutter test..."
    if ! flutter test; then
        print_error "Tests failed"
        exit 1
    fi

    print_info "Formatting code..."
    dart format .

    # Publishing preparation
    print_info "Running flutter pub get..."
    flutter pub get

    print_info "Running dry-run publish..."
    if ! flutter pub publish --dry-run; then
        print_error "Dry-run publish failed"
        exit 1
    fi

    print_success "Verification completed successfully!"
}

# Function to ensure git repo
ensure_git_repo() {
    if [[ ! -d .git ]]; then
        print_info "Initializing git repository..."
        git init
        git add .
        git commit -m "Initial commit"
    fi

    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        git add .
        git commit -m "Initial commit"
    fi

    git branch -M main 2>/dev/null || true
}

# Function to create license if missing
create_license_if_missing() {
    if [[ ! -f LICENSE && ! -f LICENSE.md ]]; then
        print_info "Creating MIT LICENSE file..."
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
        git commit -m "Add MIT license"
    fi
}

# Function to create GitHub repo
create_github_repo() {
    print_info "Setting up GitHub repository..."

    ensure_git_repo

    # Check for gh CLI
    if command -v gh >/dev/null 2>&1; then
        print_info "Using GitHub CLI (gh) to create repository..."

        if gh repo view "$USERNAME/$PACKAGE_NAME" >/dev/null 2>&1; then
            print_info "Repository $USERNAME/$PACKAGE_NAME already exists. Setting remote and pushing."
            git remote remove origin 2>/dev/null || true
            git remote add origin "https://github.com/$USERNAME/$PACKAGE_NAME.git"
            git push -u origin main
        else
            print_info "Creating new repository $USERNAME/$PACKAGE_NAME on GitHub..."
            if ! gh auth status >/dev/null 2>&1; then
                print_warning "You are not logged into GitHub CLI. Attempting to login..."
                gh auth login
            fi
            gh repo create "$USERNAME/$PACKAGE_NAME" --public --description "$DESCRIPTION"
            git remote remove origin 2>/dev/null || true
            git remote add origin "https://github.com/$USERNAME/$PACKAGE_NAME.git"
            git push -u origin main
        fi
    else
        print_warning "GitHub CLI not found. Attempting to use GitHub API..."

        if [[ -z "${GITHUB_TOKEN:-}" ]]; then
            print_error "GITHUB_TOKEN not set. Please set it or install GitHub CLI."
            print_info "To create a token: https://github.com/settings/tokens"
            exit 1
        fi

        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$USERNAME/$PACKAGE_NAME")

        if [[ "$status" == "200" ]]; then
            print_info "Repository exists. Setting remote and pushing..."
            git remote remove origin 2>/dev/null || true
            git remote add origin "https://github.com/$USERNAME/$PACKAGE_NAME.git"
            git push -u origin main
        elif [[ "$status" == "404" ]]; then
            print_info "Creating repository via GitHub API..."
            curl -s -H "Authorization: token $GITHUB_TOKEN" \
                -d "{\"name\":\"$PACKAGE_NAME\",\"description\":\"$DESCRIPTION\",\"private\":false,\"auto_init\":true,\"license_template\":\"mit\"}" \
                "https://api.github.com/user/repos"
            git remote remove origin 2>/dev/null || true
            git remote add origin "https://github.com/$USERNAME/$PACKAGE_NAME.git"
            git push -u origin main
        else
            print_error "Unexpected response from GitHub API: $status"
            exit 1
        fi
    fi

    create_license_if_missing

    print_success "GitHub repository setup complete!"
}

# Function to publish to pub.dev
publish_to_pubdev() {
    print_info "Publishing to pub.dev..."

    # URLs should already be set by update_github_username, but verify
    local homepage="https://github.com/$USERNAME/$PACKAGE_NAME"
    local repository="https://github.com/$USERNAME/$PACKAGE_NAME"
    local issues="https://github.com/$USERNAME/$PACKAGE_NAME/issues"

    # Verify URLs are present (should have been added by update_github_username)
    if ! grep -q "^homepage:" pubspec.yaml; then
        print_warning "Homepage not found, adding it now..."
        sed -i '' "/^description:/a\\
homepage: $homepage" pubspec.yaml
    fi

    if ! grep -q "^repository:" pubspec.yaml; then
        print_warning "Repository not found, adding it now..."
        sed -i '' "/^description:/a\\
repository: $repository" pubspec.yaml
    fi

    if ! grep -q "^issue_tracker:" pubspec.yaml; then
        print_warning "Issue tracker not found, adding it now..."
        sed -i '' "/^description:/a\\
issue_tracker: $issues" pubspec.yaml
    fi

    # Final dry-run
    print_info "Final dry-run before publishing..."
    if ! flutter pub publish --dry-run; then
        print_error "Dry-run failed. Please fix the issues before publishing."
        return 1
    fi

    if ! confirm "Proceed with publishing to pub.dev?"; then
        print_info "Publishing cancelled."
        return
    fi

    print_info "Publishing to pub.dev..."
    flutter pub publish

    print_success "Published to pub.dev successfully!"
    print_info "Visit: https://pub.dev/packages/$PACKAGE_NAME"
}

# Function to create GitHub release
create_github_release() {
    print_info "Creating GitHub release..."

    # Create tag
    git tag -a "v$VERSION" -m "Release version $VERSION"
    git push origin "v$VERSION"

    # Create release
    if command -v gh >/dev/null 2>&1; then
        gh release create "v$VERSION" --title "Release v$VERSION" --notes-file CHANGELOG.md
    else
        print_info "GitHub CLI not available. Please create the release manually at:"
        print_info "https://github.com/$USERNAME/$PACKAGE_NAME/releases/new"
        print_info "Tag: v$VERSION"
        print_info "Title: Release v$VERSION"
        print_info "Copy changelog from CHANGELOG.md"
    fi

    print_success "GitHub release created!"
}

# Main script
main() {
    echo "========================================"
    echo "Flutter Package Release & Publish Script"
    echo "========================================"

    # Get package info
    get_package_info

    # Pre-step: organize shell scripts & ensure .gitattributes and .pubignore configuration
    organize_shell_scripts
    ensure_gitattributes
    ensure_pubignore

    # Step 1: Package renaming
    rename_package
    
    # Reload package info after potential rename
    get_package_info

    # Step 2: Get GitHub username
    local old_username=""
    # Try to extract existing username from pubspec.yaml
    if grep -q "github.com/" pubspec.yaml; then
        old_username=$(grep "github.com/" pubspec.yaml | head -1 | sed 's|.*github.com/||' | sed 's|/.*||')
        print_info "Current GitHub username in pubspec.yaml: $old_username"
    fi
    
    read -p "Enter your GitHub username [$old_username]: " USERNAME
    USERNAME=${USERNAME:-$old_username}
    
    if [[ -z "$USERNAME" ]]; then
        print_error "GitHub username is required"
        exit 1
    fi
    
    # Update GitHub username across all files
    update_github_username "$USERNAME" "$old_username"

    # Step 3: Version number
    print_info "Current version: $VERSION"
    local new_version
    read -p "Enter the version number (e.g., 0.0.1) [$VERSION]: " new_version
    new_version=${new_version:-$VERSION}
    
    # Validate version format
    if ! echo "$new_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.+-]+)?(\+[a-zA-Z0-9.+-]+)?$'; then
        print_error "Invalid version format. Please use semantic versioning (e.g., 0.0.1, 1.0.0-beta, 2.1.3+build123)"
        exit 1
    fi
    
    if [[ "$new_version" != "$VERSION" ]]; then
        update_version "$new_version"
    fi
    
    # Reload package info after updates
    get_package_info
    
    print_success "Package configuration updated!"
    echo ""
    echo "Summary:"
    echo "  Package: $PACKAGE_NAME"
    echo "  Version: $VERSION"
    echo "  GitHub: $USERNAME/$PACKAGE_NAME"
    echo ""

    # Commit changes before verification
    commit_changes

    # Verification
    if confirm "Run verification checklist (analyze, test, dry-run)?" y; then
        run_verification
    fi

    # GitHub setup
    if confirm "Set up GitHub repository?" y; then
        create_github_repo
    fi

    # Publishing
    if confirm "Publish to pub.dev?" y; then
        publish_to_pubdev
    fi

    # GitHub release
    if confirm "Create GitHub release?" y; then
        create_github_release
    fi

    print_success "All done! Your package is released and published."
    print_info "Don't forget to update your package's pub.dev score and respond to issues."
}

# Run main function
main "$@"