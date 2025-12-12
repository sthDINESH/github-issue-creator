# github-issue-creator

# GitHub Issues Creator - Standalone Tool

A standalone script to create GitHub issues from YAML files using the GitHub CLI. Perfect for managing user stories, sprints, and project planning across any GitHub repository.

## Features

- ✅ Create GitHub issues from YAML definitions
- ✅ Auto-create milestones if they don't exist
- ✅ Support for labels and assignees
- ✅ Dry-run mode to preview issues
- ✅ Batch process multiple YAML files
- ✅ Works with any GitHub repository
- ✅ Color-coded output for easy reading
- ✅ Error handling and validation

## Prerequisites

### 1. Install GitHub CLI

**macOS:**
```bash
brew install gh
```

**Linux:**
```bash
curl -sS https://webi.sh/gh | sh
```

**Windows:**
```bash
winget install GitHub.cli
```

Or download from: https://cli.github.com

### 2. Install yq (YAML processor)

**macOS:**
```bash
brew install yq
```

**Linux:**
```bash
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
chmod +x /usr/local/bin/yq
```

**Windows:**
```bash
choco install yq
```

### 3. Authenticate with GitHub

```bash
gh auth login
```

Follow the prompts to authenticate.

## Quick Start

### 1. Make the script executable

```bash
chmod +x github-issues-creator.sh
```

### 2. Create a YAML file with issue definitions

Create `my-issues.yaml`:

```yaml
---
sprint: 1
milestone: "Sprint 1"
issues:
  - title: "[Sprint 1] User Story: Feature Name"
    labels:
      - sprint-1
      - user-story
      - must-have
    body: |
      ## User Story
      **As a** user
      **I want to** do something
      **So that I can** achieve a goal

      ## Acceptance Criteria
      - [ ] Criterion 1
      - [ ] Criterion 2

      ## Tasks
      - [ ] Task 1
        - [ ] Subtask 1.1
        - [ ] Subtask 1.2
      - [ ] Task 2

      ## Definition of Done
      - [ ] All acceptance criteria met
      - [ ] Code reviewed
      - [ ] Tests passing
```

### 3. Run the script

**Dry run (preview without creating):**
```bash
./github-issues-creator.sh username/repository my-issues.yaml --dry-run
```

**Create issues:**
```bash
./github-issues-creator.sh username/repository my-issues.yaml
```

## Usage

### Basic Usage

```bash
./github-issues-creator.sh <owner/repo> <yaml-file-or-directory> [--dry-run]
```

### Examples

**Create issues from single file:**
```bash
./github-issues-creator.sh sthDINESH/Vertex sprint-1.yaml
```

**Create issues from directory (processes all .yaml files):**
```bash
./github-issues-creator.sh sthDINESH/Vertex ./issues/
```

**Dry run to preview:**
```bash
./github-issues-creator.sh sthDINESH/Vertex sprint-1.yaml --dry-run
```

**Different repository:**
```bash
./github-issues-creator.sh myorg/myproject issues/sprint-2.yaml
```

## YAML File Format

### Complete Example

```yaml
---
sprint: 1
milestone: "Sprint 1: Foundation"
issues:
  - title: "[Sprint 1] User Story: User Authentication"
    labels:
      - sprint-1
      - user-story
      - must-have
      - backend
    body: |
      ## User Story
      **As a** registered user
      **I want to** log in with my email and password
      **So that I can** access my personalized dashboard

      ## Acceptance Criteria
      - [ ] User can enter email and password
      - [ ] Form validates input before submission
      - [ ] Successful login redirects to dashboard
      - [ ] Failed login shows error message
      - [ ] "Remember me" checkbox persists session

      ## Tasks
      - [ ] **Backend**
        - [ ] Create login API endpoint (POST /auth/login)
        - [ ] Implement JWT token generation
        - [ ] Add password verification (bcrypt)
        - [ ] Set up HTTP-only cookies
      - [ ] **Frontend**
        - [ ] Create LoginForm component
        - [ ] Add form validation
        - [ ] Implement error handling
        - [ ] Add loading states
      - [ ] **Testing**
        - [ ] Unit tests for API endpoint
        - [ ] Integration tests for login flow
        - [ ] Test error scenarios

      ## Definition of Done
      - [ ] All acceptance criteria met
      - [ ] Code reviewed and approved
      - [ ] Tests passing (coverage >80%)
      - [ ] Deployed to staging
      - [ ] Documentation updated

  - title: "[Sprint 1] Task: Set Up Database Schema"
    labels:
      - sprint-1
      - task
      - must-have
      - database
    body: |
      ## Description
      Design and implement MongoDB schema for user authentication

      ## Requirements
      - [ ] User collection with email, passwordHash, createdAt fields
      - [ ] Email field has unique index
      - [ ] Schema validation in place
      - [ ] Migration scripts created

      ## Tasks
      - [ ] Define Mongoose schemas
      - [ ] Create database indexes
      - [ ] Write migration scripts
      - [ ] Test with sample data
```

### Required Fields

- `issues`: Array of issue objects
  - Each issue must have:
    - `title`: Issue title (string)
    - `body`: Issue body in Markdown (multiline string using `|`)

### Optional Fields

- `sprint`: Number identifying the sprint
- `milestone`: Name of the milestone (created if doesn't exist)

### Issue Object Optional Fields

Each issue can optionally have:
- `labels`: Array of label strings
- `assignees`: Array of GitHub usernames
- `projects`: Array of project IDs

### Examples

**Minimal example (only required fields):**
```yaml
---
issues:
  - title: "Fix login bug"
    body: |
      The login button is not working on the homepage.
```

**Example with labels but no sprint/milestone:**
```yaml
---
issues:
  - title: "Bug Fix: Login Error"
    labels: [bug, high-priority]
    body: |
      ## Description
      Fix the login error on the homepage.
      
      ## Steps to Reproduce
      1. Go to login page
      2. Enter credentials
      3. Click submit
```

**Example with sprint and milestone but no labels:**
```yaml
---
sprint: 1
milestone: "Sprint 1"
issues:
  - title: "[Sprint 1] Set up project structure"
    body: |
      Initialize the project with the basic folder structure and dependencies.
```

**Full example with all optional fields:**
```yaml
---
sprint: 1
milestone: "Sprint 1"
issues:
  - title: "[Sprint 1] Feature"
    labels: [sprint-1, feature]
    assignees: [username1, username2]
    body: |
      Issue description here
```

**Multiple issues with mixed configurations:**
```yaml
---
issues:
  - title: "Quick bug fix"
    body: "Fix this issue quickly"
  
  - title: "Feature: Add search"
    labels: [enhancement, frontend]
    body: |
      Add search functionality to the app
  
  - title: "Documentation update"
    labels: [documentation]
    assignees: [tech-writer]
    body: |
      Update the API documentation
```

## Tips & Best Practices

### 1. Use Consistent Naming

**Title format:**
```
Type: Feature Name
```

Examples:
- `User Story: User Authentication`
- `Task: Deploy to Production`
- `Bug Fix: Login Error Handling`

### 2. Organize Labels

Create standard labels in your repository:

**Priority:**
- `must-have` - Critical for MVP
- `should-have` - Important but not critical
- `could-have` - Nice to have

**Type:**
- `user-story` - User-facing features
- `task` - Technical work
- `bug` - Bug fixes
- `testing` - Testing tasks
- `deployment` - Deployment tasks

**Sprint:**
- `sprint-1`, `sprint-2`, etc.

**Area:**
- `frontend`, `backend`, `database`, `devops`

### 3. Write Atomic Tasks

Break down large tasks into small, completable units:

❌ **Too broad:**
```yaml
- [ ] Implement authentication
```

✅ **Better:**
```yaml
- [ ] Create login API endpoint
- [ ] Add JWT token generation
- [ ] Implement password hashing
- [ ] Create login form component
- [ ] Add form validation
```

### 4. Use Templates

Create template YAML files for common issue types:

**user-story-template.yaml:**
```yaml
issues:
  - title: "[Sprint X] User Story: FEATURE_NAME"
    labels:
      - sprint-X
      - user-story
      - must-have
    body: |
      ## User Story
      **As a** [user type]
      **I want to** [action]
      **So that I can** [benefit]

      ## Acceptance Criteria
      - [ ] 

      ## Tasks
      - [ ] 

      ## Definition of Done
      - [ ] All acceptance criteria met
      - [ ] Code reviewed
      - [ ] Tests passing
```

### 5. Version Control Your YAML Files

Store YAML files in a separate repository or folder:

```
project-issues/
├── sprint-1.yaml
├── sprint-2.yaml
├── sprint-3.yaml
└── templates/
    ├── user-story.yaml
    └── task.yaml
```

Track changes with Git to see issue evolution over time.

### 6. Dry Run First

Always preview with `--dry-run` before creating:

```bash
./github-issues-creator.sh myorg/repo sprint-1.yaml --dry-run
```

Review the output to ensure everything looks correct.

## Troubleshooting

### "gh: command not found"
Install GitHub CLI (see Prerequisites).

### "yq: command not found"
Install yq YAML processor (see Prerequisites).

### "Not authenticated with GitHub CLI"
Run `gh auth login` and follow prompts.

### "Invalid repository format"
Ensure repository is in format: `owner/repository`

Examples:
- ✅ `sthDINESH/Vertex`
- ✅ `facebook/react`
- ❌ `Vertex` (missing owner)
- ❌ `https://github.com/user/repo` (should be owner/repo)

### "Cannot access repository"
1. Verify repository name is correct
2. Check you have access (public repo or you're a collaborator)
3. Ensure you're authenticated: `gh auth status`

### "Invalid YAML file"
Validate your YAML syntax:
```bash
yq eval '.' your-file.yaml
```

Common issues:
- Incorrect indentation (use spaces, not tabs)
- Missing quotes around special characters
- Unclosed multiline strings

### Issues created with wrong labels
Create labels in your GitHub repository first:
1. Go to repository → Issues → Labels
2. Create labels matching your YAML file
3. Re-run the script

### Rate limiting errors
If creating many issues quickly, the script includes a 0.5s delay between issues. For large batches:
1. Process smaller batches
2. Wait a few minutes between runs
3. Check GitHub API rate limits: `gh api rate_limit`

## Advanced Usage

### Process Multiple Sprints

Create all sprints at once:
```bash
./github-issues-creator.sh myorg/repo ./sprints/
```

Directory structure:
```
sprints/
├── sprint-1.yaml
├── sprint-2.yaml
├── sprint-3.yaml
└── sprint-4.yaml
```

### Custom Milestone Dates

Milestones are created without dates. To set due dates:
1. Create issues with the script
2. Go to GitHub → Milestones
3. Edit milestone to add due date

Or use GitHub API:
```bash
gh api repos/owner/repo/milestones/1 -X PATCH -f due_on="2025-12-31T23:59:59Z"
```

### Export Existing Issues to YAML

Reverse the process - export GitHub issues to YAML:
```bash
# List all issues
gh issue list --repo owner/repo --json title,body,labels,milestone

# Export to file (requires custom script)
```

### Integrate with CI/CD

Use in GitHub Actions to auto-create issues:

```yaml
name: Create Sprint Issues
on:
  workflow_dispatch:
    inputs:
      sprint_file:
        description: 'Sprint YAML file'
        required: true

jobs:
  create-issues:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install yq
        run: sudo snap install yq
      
      - name: Create Issues
        run: |
          ./github-issues-creator.sh ${{ github.repository }} ${{ github.event.inputs.sprint_file }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Contributing

To use this tool in other projects:
1. Copy `github-issues-creator.sh` to your project
2. Create YAML files with your issue definitions
3. Run the script pointing to your repository

## Support

For issues with the script:
1. Check error messages carefully
2. Verify prerequisites are installed
3. Test with `--dry-run` first
4. Validate YAML syntax with `yq`

## License

This script is provided as-is for use in any project.

## Credits

Created for the Vertex project sprint planning. Adaptable for any GitHub project management workflow.
