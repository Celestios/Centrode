# Build Graphify knowledge graph for lib and rust directories using Google Gemini API key
if (-not $env:GEMINI_API_KEY) {
    $env:GEMINI_API_KEY = "AQ.Ab8RN6K0Pb8FdqwlQ--qpyP_bhc-RXdFcQClA43uaHNM-w72Jg"
}

# Rate limit: pause 5 seconds before invoking Graphify (helps avoid throttling)
Start-Sleep -Seconds 5

# Execute graphify on the repository root, using Gemini as the backend.
# The .graphifyignore file ensures only lib/ and rust/ are processed.
graphify . --backend gemini

