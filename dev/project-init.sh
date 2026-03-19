#!/usr/bin/env bash
# =====================================================
#  Universal Project Initializer
# Quick setup for various project types
# =====================================================

set -e

# Colors
readonly GREEN="\033[0;32m"
readonly CYAN="\033[0;36m"
readonly YELLOW="\033[1;33m"
readonly BRIGHT_GREEN="\033[1;32m"
readonly BRIGHT_CYAN="\033[1;36m"
readonly BRIGHT_YELLOW="\033[1;33m"
readonly RESET="\033[0m"

log_success() { echo -e "${BRIGHT_GREEN}${RESET} ${GREEN}$1${RESET}"; }
log_info() { echo -e "${BRIGHT_CYAN}${RESET} ${CYAN}$1${RESET}"; }
log_warning() { echo -e "${BRIGHT_YELLOW}${RESET} ${YELLOW}$1${RESET}"; }

print_header() {
    echo -e "${BRIGHT_CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BRIGHT_CYAN}║${RESET}  $1"
    echo -e "${BRIGHT_CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}"
}

# Get project details
get_project_info() {
    echo
    read -p "Project name: " PROJECT_NAME
    
    if [ -z "$PROJECT_NAME" ]; then
        log_warning "Project name cannot be empty"
        exit 1
    fi
    
    # Sanitize project name
    PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    PROJECT_DIR="$PWD/$PROJECT_NAME"
    
    if [ -d "$PROJECT_DIR" ]; then
        log_warning "Directory $PROJECT_NAME already exists"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    read -p "Description: " PROJECT_DESC
    read -p "Author: " AUTHOR
    
    : ${AUTHOR:=$(git config user.name 2>/dev/null || echo "Your Name")}
}

# Initialize Git repository
init_git() {
    log_info "Initializing Git repository..."
    
    cd "$PROJECT_DIR"
    git init -q
    
    # Create .gitignore based on project type
    cat > .gitignore << 'EOF'
# General
.DS_Store
.vscode/
.idea/
*.log
*.tmp
.env
.env.local

# OS
Thumbs.db
EOF
    
    log_success "Git initialized"
}

# Python project
create_python_project() {
    log_info "Creating Python project structure..."
    
    mkdir -p "$PROJECT_DIR"/{src,tests,docs}
    
    # Create pyproject.toml
    cat > "$PROJECT_DIR/pyproject.toml" << EOF
[project]
name = "$PROJECT_NAME"
version = "0.1.0"
description = "$PROJECT_DESC"
authors = [
    {name = "$AUTHOR"}
]
requires-python = ">=3.9"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
]

[tool.black]
line-length = 88

[tool.ruff]
line-length = 88
EOF
    
    # Create main.py
    cat > "$PROJECT_DIR/src/main.py" << 'EOF'
"""
Main module for the application.
"""

def main():
    """Main function."""
    print("Hello, World!")

if __name__ == "__main__":
    main()
EOF
    
    # Create test file
    cat > "$PROJECT_DIR/tests/test_main.py" << 'EOF'
"""
Tests for main module.
"""
import pytest
from src.main import main

def test_main():
    """Test main function."""
    main()  # Should not raise
EOF
    
    # Create README
    cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

$PROJECT_DESC

## Installation

\`\`\`bash
pip install -e .
\`\`\`

## Development

\`\`\`bash
pip install -e ".[dev]"
pytest
\`\`\`

## Usage

\`\`\`bash
python src/main.py
\`\`\`

## Author

$AUTHOR
EOF
    
    # Update .gitignore for Python
    cat >> "$PROJECT_DIR/.gitignore" << 'EOF'

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
.pytest_cache/
.coverage
htmlcov/
venv/
env/
ENV/
EOF
    
    init_git
    
    log_success "Python project created!"
    echo
    echo "Next steps:"
    echo "  cd $PROJECT_NAME"
    echo "  python -m venv venv"
    echo "  source venv/bin/activate"
    echo "  pip install -e '.[dev]'"
}

# Node.js project
create_nodejs_project() {
    log_info "Creating Node.js project structure..."
    
    mkdir -p "$PROJECT_DIR"/{src,tests}
    
    cd "$PROJECT_DIR"
    
    # Create package.json
    cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "0.1.0",
  "description": "$PROJECT_DESC",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest"
  },
  "author": "$AUTHOR",
  "license": "MIT",
  "devDependencies": {
    "nodemon": "^3.0.0",
    "jest": "^29.0.0"
  }
}
EOF
    
    # Create index.js
    cat > src/index.js << 'EOF'
/**
 * Main entry point
 */

function main() {
    console.log('Hello, World!');
}

main();

module.exports = { main };
EOF
    
    # Create test
    cat > tests/index.test.js << 'EOF'
const { main } = require('../src/index');

describe('Main function', () => {
    test('should run without errors', () => {
        expect(() => main()).not.toThrow();
    });
});
EOF
    
    # Create README
    cat > README.md << EOF
# $PROJECT_NAME

$PROJECT_DESC

## Installation

\`\`\`bash
npm install
\`\`\`

## Development

\`\`\`bash
npm run dev
\`\`\`

## Testing

\`\`\`bash
npm test
\`\`\`

## Author

$AUTHOR
EOF
    
    # Update .gitignore for Node.js
    cat >> .gitignore << 'EOF'

# Node.js
node_modules/
npm-debug.log
yarn-error.log
package-lock.json
yarn.lock
.npm
.yarn
dist/
build/
EOF
    
    init_git
    
    log_success "Node.js project created!"
    echo
    echo "Next steps:"
    echo "  cd $PROJECT_NAME"
    echo "  npm install"
    echo "  npm run dev"
}

# Bash script project
create_bash_project() {
    log_info "Creating Bash script project..."
    
    mkdir -p "$PROJECT_DIR"/{bin,lib,tests}
    
    # Create main script
    cat > "$PROJECT_DIR/bin/$PROJECT_NAME" << EOF
#!/usr/bin/env bash
# =====================================================
# Script description here
# =====================================================

set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="\$SCRIPT_DIR/../lib"

# Source libraries
source "\$LIB_DIR/utils.sh"

main() {
    echo "Hello from $PROJECT_NAME!"
}

main "\$@"
EOF
    
    chmod +x "$PROJECT_DIR/bin/$PROJECT_NAME"
    
    # Create utility library
    cat > "$PROJECT_DIR/lib/utils.sh" << 'EOF'
#!/usr/bin/env bash
# Utility functions

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}
EOF
    
    # Create README
    cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

$PROJECT_DESC

## Installation

\`\`\`bash
# Add to PATH or create symlink
ln -s "\$(pwd)/bin/$PROJECT_NAME" ~/.local/bin/$PROJECT_NAME
\`\`\`

## Usage

\`\`\`bash
./$PROJECT_NAME
\`\`\`

## Author

$AUTHOR
EOF
    
    # Update .gitignore for Bash
    cat >> "$PROJECT_DIR/.gitignore" << 'EOF'

# Bash
*.swp
*~
EOF
    
    init_git
    
    log_success "Bash project created!"
    echo
    echo "Next steps:"
    echo "  cd $PROJECT_NAME"
    echo "  ./bin/$PROJECT_NAME"
}

# Generic project
create_generic_project() {
    log_info "Creating generic project structure..."
    
    mkdir -p "$PROJECT_DIR"/{src,docs,tests}
    
    cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

$PROJECT_DESC

## Author

$AUTHOR
EOF
    
    init_git
    
    log_success "Generic project created!"
}

# Show menu
show_menu() {
    print_header " Project Initializer"
    echo
    echo "Choose project type:"
    echo
    echo "  1) Python (with pyproject.toml)"
    echo "  2) Node.js (with package.json)"
    echo "  3) Bash Script"
    echo "  4) Generic (basic structure)"
    echo "  0) Exit"
    echo
}

# Main function
main() {
    clear
    show_menu
    
    read -p "Enter choice [0-4]: " choice
    
    case $choice in
        1)
            get_project_info
            create_python_project
            ;;
        2)
            get_project_info
            create_nodejs_project
            ;;
        3)
            get_project_info
            create_bash_project
            ;;
        4)
            get_project_info
            create_generic_project
            ;;
        0)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
    
    echo
    log_success "Project ready at: $PROJECT_DIR"
    echo
}

# Run
main "$@"
