# Read stdin
$inputJson = [System.Console]::In.ReadToEnd()
if ($inputJson) {
    try {
        $data = ConvertFrom-Json $inputJson
        $toolName = $data.toolCall.name
        
        # Allow reading graphify outputs or agent config files without asking
        if ($toolName -eq "view_file") {
            $path = $data.toolCall.args.AbsolutePath
            if ($path -like "*graphify-out*" -or $path -like "*.agents*" -or $data.toolCall.args.IsSkillFile -eq $true) {
                Write-Output '{"decision":"allow"}'
                exit
            }
        }

        # For search/read tools, ask the user to nudge using graphify
        if ($toolName -eq "grep_search" -or $toolName -eq "find_by_name" -or $toolName -eq "view_file") {
            $output = @{
                decision = "ask"
                reason = "Suggested: Consult the Graphify knowledge graph first if this is a codebase query (e.g. use 'graphify query', 'graphify path', 'graphify explain', or check 'graphify-out/GRAPH_REPORT.md')."
            }
            Write-Output (ConvertTo-Json $output -Compress)
            exit
        }
    } catch {
        # Fallback to allow
    }
}
Write-Output '{"decision":"allow"}'
