$files = Get-ChildItem -Path . -Recurse -File -Include *.dart, *.py, *.yml, *.yaml, *.iss -Exclude *node_modules*, *.git*, *analysis_results.txt*
$output = "projeto music\codigo_projeto_music.txt"
if (!(Test-Path "projeto music")) { New-Item -ItemType Directory "projeto music" }
"--- CONSOLIDATED PROJECT CODE (STAGE 8) ---" | Out-File $output -Encoding utf8
foreach ($file in $files) {
    "--- FILE: $($file.FullName) ---" | Out-File $output -Append -Encoding utf8
    Get-Content $file.FullName | Out-File $output -Append -Encoding utf8
    "`n" | Out-File $output -Append -Encoding utf8
}
Write-Host "Consolidation complete: $output"
