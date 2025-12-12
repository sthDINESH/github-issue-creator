#!/usr/bin/env bash
#
# GitHub Issues Creator
# 
# This script reads YAML files containing issue definitions and creates them
# in any GitHub repository using the GitHub CLI (gh).
#
# Prerequisites:
#   1. Install GitHub CLI: brew install gh (macOS) or see https://cli.github.com
#   2. Authenticate: gh auth login
#   3. Install yq for YAML parsing: brew install yq
#
# Usage:
#   ./github-issues-creator.sh owner/repo issues.yaml
#   ./github-issues-creator.sh owner/repo issues-dir/
#   ./github-issues-creator.sh owner/repo issues.yaml --dry-run
#
# Examples:
#   ./github-issues-creator.sh sthDINESH/Vertex sprint-1.yaml
#   ./github-issues-creator.sh myorg/myrepo ./issues/ --dry-run
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Version
VERSION="1.0.0"

# Configuration
REPO=""
FILES=()
DRY_RUN=false

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║           GitHub Issues Creator - Standalone v${VERSION}          ║"
    echo "║                                                                ║"
    echo "║  Create GitHub issues from YAML files using GitHub CLI        ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

# Print usage
print_usage() {
    cat << EOF
${BOLD}Usage:${NC}
  $0 <owner/repo> <yaml-file-or-directory> [--dry-run]

${BOLD}Arguments:${NC}
  owner/repo    GitHub repository in format: username/repository
  yaml-file     Path to YAML file with issue definitions
  directory     Path to directory containing YAML files
  --dry-run     Preview issues without creating them

${BOLD}Examples:${NC}
  $0 sthDINESH/Vertex sprint-1.yaml
  $0 myorg/myrepo ./issues/
  $0 sthDINESH/Vertex sprint-1.yaml --dry-run

${BOLD}YAML File Format:${NC}
  ---
  sprint: 1
  milestone: "Sprint 1"
  issues:
    - title: "[Sprint 1] Feature Name"
      labels:
        - sprint-1
        - must-have
      body: |
        ## User Story
        **As a** user
        **I want to** do something
        **So that I can** achieve goal

        ## Acceptance Criteria
        - [ ] Criterion 1
        
        ## Tasks
        - [ ] Task 1

${BOLD}Prerequisites:${NC}
  - GitHub CLI (gh): brew install gh
  - yq: brew install yq
  - Authenticated: gh auth login

EOF
}

# Parse command line arguments
parse_args() {
    if [[ $# -lt 2 ]]; then
        echo -e "${RED}Error: Missing required arguments${NC}\n"
        print_usage
        exit 1
    fi
    
    REPO="$1"
    shift
    
    # Validate repo format
    if [[ ! "$REPO" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$ ]]; then
        echo -e "${RED}Error: Invalid repository format${NC}"
        echo -e "Expected: ${CYAN}owner/repository${NC}"
        echo -e "Got: ${YELLOW}$REPO${NC}\n"
        exit 1
    fi
    
    local input="$1"
    shift
    
    # Check for flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            --version|-v)
                echo "GitHub Issues Creator v${VERSION}"
                exit 0
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}\n"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Check if input is directory or file
    if [[ -d "$input" ]]; then
        # Directory: find all YAML files
        mapfile -t FILES < <(find "$input" -maxdepth 1 -type f \( -name "*.yaml" -o -name "*.yml" \) | sort)
        if [[ ${#FILES[@]} -eq 0 ]]; then
            echo -e "${RED}Error: No YAML files found in directory: $input${NC}"
            exit 1
        fi
    elif [[ -f "$input" ]]; then
        # Single file
        FILES=("$input")
    else
        echo -e "${RED}Error: File or directory not found: $input${NC}"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    local errors=0
    
    # Check if gh is installed
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}✗ GitHub CLI (gh) is not installed${NC}"
        echo -e "  Install: ${CYAN}brew install gh${NC} (macOS)"
        echo -e "  Or visit: https://cli.github.com"
        ((errors++))
    else
        echo -e "${GREEN}✓ GitHub CLI (gh) installed${NC}"
    fi
    
    # Check if yq is installed
    if ! command -v yq &> /dev/null; then
        echo -e "${RED}✗ yq is not installed${NC}"
        echo -e "  Install: ${CYAN}brew install yq${NC} (macOS)"
        ((errors++))
    else
        echo -e "${GREEN}✓ yq installed${NC}"
    fi
    
    # Check if authenticated with GitHub
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}✗ Not authenticated with GitHub CLI${NC}"
        echo -e "  Run: ${CYAN}gh auth login${NC}"
        ((errors++))
    else
        echo -e "${GREEN}✓ Authenticated with GitHub${NC}"
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo -e "\n${RED}Please fix the above errors before continuing${NC}"
        exit 1
    fi
    
    # Verify repository exists
    echo -e "${BLUE}Verifying repository access...${NC}"
    if gh repo view "$REPO" &> /dev/null; then
        echo -e "${GREEN}✓ Repository found: $REPO${NC}"
    else
        echo -e "${RED}✗ Cannot access repository: $REPO${NC}"
        echo -e "  Verify the repository name and your access permissions"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites met${NC}\n"
}

# Create or get milestone
get_or_create_milestone() {
    local milestone_title="$1"
    
    # Check if milestone exists
    local milestone_number
    milestone_number=$(gh api "repos/$REPO/milestones" \
        --jq ".[] | select(.title == \"$milestone_title\") | .number" 2>/dev/null || echo "")
    
    if [[ -n "$milestone_number" ]]; then
        echo "$milestone_number"
        return
    fi
    
    # Create milestone if it doesn't exist
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY_RUN_MILESTONE"
        return
    fi
    
    echo -e "${YELLOW}Creating milestone: $milestone_title${NC}" >&2
    milestone_number=$(gh api "repos/$REPO/milestones" \
        -f title="$milestone_title" \
        -f state="open" \
        --jq ".number")
    
    echo "$milestone_number"
}

# Check if label exists
label_exists() {
    local label_name="$1"
    
    gh api "repos/$REPO/labels" \
        --jq ".[] | select(.name == \"$label_name\") | .name" 2>/dev/null | grep -q "."
}

# Create label if it doesn't exist
create_label_if_needed() {
    local label_name="$1"
    
    if label_exists "$label_name"; then
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would create label: ${CYAN}$label_name${NC}" >&2
        return 0
    fi
    
    # Default colors for common label types
    local color="EDEDED"  # Default gray
    case "$label_name" in
        user-story)       color="0052CC" ;;  # Blue
        must-have)        color="D93F0B" ;;  # Red
        should-have)      color="FBCA04" ;;  # Yellow
        could-have)       color="C2E0C6" ;;  # Light green
        frontend)         color="1D76DB" ;;  # Blue
        backend)          color="0E8A16" ;;  # Green
        ai-integration)   color="5319E7" ;;  # Purple
        deployment)       color="0E8A16" ;;  # Green
        devops)           color="FBCA04" ;;  # Yellow
        testing)          color="D4C5F9" ;;  # Light purple
        qa)               color="C2E0C6" ;;  # Light green
        ux)               color="BFD4F2" ;;  # Light blue
        bug)              color="D73A4A" ;;  # Red
        enhancement)      color="A2EEEF" ;;  # Light cyan
        documentation)    color="0075CA" ;;  # Blue
    esac
    
    echo -e "${YELLOW}Creating label: ${CYAN}$label_name${NC}" >&2
    gh api "repos/$REPO/labels" \
        -f name="$label_name" \
        -f color="$color" \
        > /dev/null 2>&1
}

# Extract and create all labels from YAML file
prepare_labels() {
    local yaml_file="$1"
    
    # Get all unique labels from the YAML file
    local labels_list
    labels_list=$(yq eval '.issues[].labels[]' "$yaml_file" 2>/dev/null | sort -u)
    
    if [[ -z "$labels_list" ]]; then
        return 0
    fi
    
    echo -e "${BLUE}Checking labels...${NC}"
    
    local label_count=0
    while IFS= read -r label; do
        if [[ -n "$label" ]]; then
            create_label_if_needed "$label"
            ((label_count++))
        fi
    done <<< "$labels_list"
    
    if [[ $label_count -gt 0 ]]; then
        echo -e "${GREEN}✓ Labels ready ($label_count unique labels)${NC}\n"
    fi
}

# Create a single issue
create_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"
    local milestone="$4"
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would create issue:"
        echo -e "  ${BLUE}Title:${NC} $title"
        if [[ -n "$labels" && "$labels" != "null" ]]; then
            echo -e "  ${BLUE}Labels:${NC} $labels"
        fi
        if [[ -n "$milestone" && "$milestone" != "null" && "$milestone" != "DRY_RUN_MILESTONE" ]]; then
            echo -e "  ${BLUE}Milestone:${NC} $milestone"
        fi
        echo -e "  ${BLUE}Body:${NC} ${#body} characters"
        echo ""
        return 0
    fi
    
    # Build gh issue create command
    local cmd=(gh issue create --repo "$REPO" --title "$title" --body "$body")
    
    # Add labels if provided
    if [[ -n "$labels" && "$labels" != "null" ]]; then
        IFS=',' read -ra LABEL_ARRAY <<< "$labels"
        for label in "${LABEL_ARRAY[@]}"; do
            cmd+=(--label "$(echo "$label" | xargs)")  # xargs trims whitespace
        done
    fi
    
    # Add milestone if provided
    if [[ -n "$milestone" && "$milestone" != "null" && "$milestone" != "DRY_RUN_MILESTONE" ]]; then
        cmd+=(--milestone "$milestone")
    fi
    
    # Execute command
    if output=$("${cmd[@]}" 2>&1); then
        echo -e "${GREEN}✓${NC} $title"
        return 0
    else
        echo -e "${RED}✗${NC} $title"
        echo -e "${RED}  Error: $output${NC}"
        return 1
    fi
}

# Process a YAML file
process_yaml_file() {
    local yaml_file="$1"
    local filename=$(basename "$yaml_file")
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Processing: $filename${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Validate YAML file
    if ! yq eval '.' "$yaml_file" > /dev/null 2>&1; then
        echo -e "${RED}Error: Invalid YAML file: $filename${NC}"
        return 1
    fi
    
    # Extract sprint info (optional)
    local sprint_num
    sprint_num=$(yq eval '.sprint // "N/A"' "$yaml_file")
    local milestone_title
    milestone_title=$(yq eval '.milestone' "$yaml_file")
    
    # Prepare labels (create if they don't exist)
    prepare_labels "$yaml_file"
    
    # Get or create milestone (only if specified)
    local milestone_number=""
    if [[ -n "$milestone_title" && "$milestone_title" != "null" ]]; then
        milestone_number=$(get_or_create_milestone "$milestone_title")
        echo -e "${BLUE}Milestone:${NC} $milestone_title ${CYAN}(ID: $milestone_number)${NC}"
    fi
    
    # Display sprint if provided
    if [[ "$sprint_num" != "N/A" && "$sprint_num" != "null" ]]; then
        echo -e "${BLUE}Sprint:${NC} $sprint_num"
    fi
    
    # Get number of issues in file
    local issue_count
    issue_count=$(yq eval '.issues | length' "$yaml_file")
    
    if [[ "$issue_count" == "null" || "$issue_count" -eq 0 ]]; then
        echo -e "${YELLOW}No issues found in $filename${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Issues:${NC} $issue_count\n"
    
    local success=0
    local failed=0
    
    # Iterate through issues
    for ((i=0; i<issue_count; i++)); do
        # Extract issue data
        local title
        title=$(yq eval ".issues[$i].title" "$yaml_file")
        local body
        body=$(yq eval ".issues[$i].body" "$yaml_file")
        local labels
        labels=$(yq eval ".issues[$i].labels // [] | join(\",\")" "$yaml_file")
        
        # Create issue
        if create_issue "$title" "$body" "$labels" "$milestone_number"; then
            ((success++))
        else
            ((failed++))
        fi
        
        # Small delay to avoid rate limiting
        [[ "$DRY_RUN" == false ]] && sleep 0.5
    done
    
    echo ""
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✓ Successfully processed $filename${NC}"
        echo -e "  Created: $success issues"
    else
        echo -e "${YELLOW}⚠ Partially processed $filename${NC}"
        echo -e "  Created: $success issues"
        echo -e "  Failed: $failed issues"
    fi
    
    return $failed
}

# Main function
main() {
    print_banner
    parse_args "$@"
    check_prerequisites
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}${BOLD}DRY RUN MODE${NC} - No issues will be created\n"
    fi
    
    echo -e "${BLUE}${BOLD}Repository:${NC} $REPO"
    echo -e "${BLUE}${BOLD}Files to process:${NC} ${#FILES[@]}\n"
    
    local total_files=${#FILES[@]}
    local current=0
    local total_failed=0
    
    for yaml_file in "${FILES[@]}"; do
        ((current++))
        echo -e "${CYAN}[$current/$total_files]${NC}"
        
        if process_yaml_file "$yaml_file"; then
            :  # Success
        else
            ((total_failed+=$?))
        fi
    done
    
    # Final summary
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}${BOLD}DRY RUN COMPLETE${NC}"
        echo -e "No issues were created."
        echo -e "Run without ${CYAN}--dry-run${NC} to create issues."
    elif [[ $total_failed -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ ALL ISSUES CREATED SUCCESSFULLY${NC}"
        echo -e "\nView issues at: ${BLUE}https://github.com/$REPO/issues${NC}"
    else
        echo -e "${YELLOW}${BOLD}⚠ COMPLETED WITH ERRORS${NC}"
        echo -e "Some issues failed to create. See errors above."
        echo -e "\nView created issues at: ${BLUE}https://github.com/$REPO/issues${NC}"
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    exit $total_failed
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}Script interrupted. Exiting...${NC}"; exit 130' INT

# Run main function
main "$@"
