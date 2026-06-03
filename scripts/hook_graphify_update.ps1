# Read stdin
$inputJson = [System.Console]::In.ReadToEnd()
if ($inputJson) {
    try {
        $data = ConvertFrom-Json $inputJson
        if ($data -and -not $data.error) {
            $workspace = $data.workspacePaths[0]
            if ($workspace) {
                graphify update $workspace
            } else {
                graphify update .
            }
        }
    } catch {
        graphify update .
    }
} else {
    graphify update .
}
Write-Output "{}"
