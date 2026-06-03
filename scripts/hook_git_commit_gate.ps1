# Read stdin
$inputJson = [System.Console]::In.ReadToEnd()
if ($inputJson) {
    try {
        $data = ConvertFrom-Json $inputJson
        $commandLine = $data.toolCall.args.CommandLine
        
        # Check if the command is a git commit command
        if ($commandLine -match "git\s+commit") {
            # Get current branch name
            $currentBranch = (git branch --show-current).Trim()
            
            # 1. Direct Commit to Main/Master Protection
            if ($currentBranch -eq "main" -or $currentBranch -eq "master") {
                # Allow release commits on main/master
                if ($commandLine -match "chore\(release\)") {
                    Write-Output '{"decision":"allow"}'
                    exit
                }
                
                $output = @{
                    decision = "deny"
                    reason = "Direct commits to main/master are strictly blocked. Please create a feature/fix branch (e.g. feat/ui-panning) or use a release commit style."
                }
                Write-Output (ConvertTo-Json $output -Compress)
                exit
            }
            
            # 2. Branch Naming Standard Validation
            # Format: <type>/<scope>-<kebab-case-description>
            # Types: feat|fix|refactor|perf|docs|chore|test
            # Scopes: graph|node|relation|tags|ui|ffi|db|workflow
            $pattern = "^(feat|fix|refactor|perf|docs|chore|test)/(graph|node|relation|tags|ui|ffi|db|workflow)-[a-z0-9\-]+$"
            if ($currentBranch -notmatch $pattern) {
                $output = @{
                    decision = "ask"
                    reason = "Branch name '$currentBranch' does not conform to standard format: <type>/<scope>-<kebab-case-description> (types: feat|fix|refactor|perf|docs|chore|test; scopes: graph|node|relation|tags|ui|ffi|db|workflow). Do you want to proceed anyway?"
                }
                Write-Output (ConvertTo-Json $output -Compress)
                exit
            }
        }
    } catch {
        # Fallback to allow if any exception occurs during evaluation
    }
}
Write-Output '{"decision":"allow"}'
