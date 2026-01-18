# HPC Thesis Compilation
# ----------------------
# Self-contained justfile for thesis compilation

set windows-powershell := true

# Diagrams directory
diagrams_dir := "figures/diagrams"

# Compile main thesis document
[group('thesis')]
compile-thesis:
    @echo "Compiling main thesis document..."
    pdflatex main.tex
    biber main
    pdflatex main.tex
    pdflatex main.tex
    @echo "Thesis compilation complete! Output: main.pdf"

# Compile all PlantUML diagrams to PDF
[group('thesis')]
compile-diagrams:
    @echo "Compiling PlantUML diagrams..."
    cd {{diagrams_dir}} && plantuml -tpdf *.puml
    @echo "All PlantUML diagrams compiled!"

# Compile PlantUML diagrams to PNG
[group('thesis')]
compile-diagrams-png:
    @echo "Compiling PlantUML diagrams to PNG..."
    cd {{diagrams_dir}} && plantuml -tpng *.puml
    @echo "All PlantUML diagrams compiled to PNG!"

# Compile a specific PlantUML diagram (usage: just compile-diagram http-sse-architecture)
[group('thesis')]
compile-diagram name:
    @echo "Compiling diagram: {{name}}.puml..."
    cd {{diagrams_dir}} && plantuml -tpdf {{name}}.puml
    @echo "Diagram compiled: {{diagrams_dir}}/{{name}}.pdf"

# Clean thesis auxiliary files
[group('thesis')]
clean-thesis:
    @echo "Cleaning thesis auxiliary files..."
    @if (Test-Path main.aux) { Remove-Item main.aux }
    @if (Test-Path main.bbl) { Remove-Item main.bbl }
    @if (Test-Path main.bcf) { Remove-Item main.bcf }
    @if (Test-Path main.blg) { Remove-Item main.blg }
    @if (Test-Path main.fdb_latexmk) { Remove-Item main.fdb_latexmk }
    @if (Test-Path main.fls) { Remove-Item main.fls }
    @if (Test-Path main.log) { Remove-Item main.log }
    @if (Test-Path main.lof) { Remove-Item main.lof }
    @if (Test-Path main.lot) { Remove-Item main.lot }
    @if (Test-Path main.lol) { Remove-Item main.lol }
    @if (Test-Path main.out) { Remove-Item main.out }
    @if (Test-Path main.run.xml) { Remove-Item main.run.xml }
    @if (Test-Path main.toc) { Remove-Item main.toc }
    @if (Test-Path indent.log) { Remove-Item indent.log }
    @echo "Thesis auxiliary files cleaned!"

# Clean diagram auxiliary files
[group('thesis')]
clean-diagrams:
    @echo "Cleaning diagram auxiliary files..."
    @Get-ChildItem -Path {{diagrams_dir}} -Include *.aux,*.log -Recurse | Remove-Item -Force
    @echo "Diagram auxiliary files cleaned!"

# Clean all thesis and diagram auxiliary files
[group('thesis')]
clean-all: clean-thesis clean-diagrams
    @echo "All auxiliary files cleaned!"

# Full rebuild: clean and compile everything
[group('thesis')]
rebuild: clean-all compile-diagrams compile-thesis
    @echo "Full thesis rebuild complete!"

# Quick compile (only once, useful for quick checks)
[group('thesis')]
quick-compile:
    @echo "Quick compiling thesis..."
    pdflatex main.tex
    @echo "Quick compilation complete! (Note: bibliography may not be updated)"

# Open the compiled thesis PDF
[group('thesis')]
open-thesis:
    @Start-Process main.pdf

# View thesis compilation log
[group('thesis')]
view-log:
    @if (Test-Path main.log) { Get-Content main.log } else { Write-Host "No log file found" -ForegroundColor Red }

# Show only critical errors from the log (fatal errors that prevent PDF generation)
[group('thesis')]
errors:
    @echo "Scanning for critical LaTeX errors..."
    @if (Test-Path main.log) { Get-Content main.log | Select-String -Pattern "^!" | ForEach-Object { Write-Host $_ -ForegroundColor Red } } else { Write-Host "No log file found. Run compile-thesis first." -ForegroundColor Yellow }
    @if (Test-Path main.log) { Get-Content main.log | Select-String -Pattern "Runaway argument" | ForEach-Object { Write-Host $_ -ForegroundColor Red } }
    @if (Test-Path main.log) { Get-Content main.log | Select-String -Pattern "Emergency stop" | ForEach-Object { Write-Host $_ -ForegroundColor Red } }
    @if (Test-Path main.log) { Get-Content main.log | Select-String -Pattern "Fatal error" | ForEach-Object { Write-Host $_ -ForegroundColor Red } }
    @if (Test-Path main.log) { Get-Content main.log | Select-String -Pattern "File .* not found" | ForEach-Object { Write-Host $_ -ForegroundColor Red } }

# Show warnings from the log (undefined references, citations, etc.)
[group('thesis')]
warnings:
    @echo "Scanning for LaTeX warnings..."
    @if (Test-Path main.log) { Get-Content main.log | Select-String -Pattern "LaTeX Warning" | ForEach-Object { Write-Host $_ -ForegroundColor Yellow } } else { Write-Host "No log file found. Run compile-thesis first." -ForegroundColor Yellow }

# Watch for changes and recompile thesis automatically
[group('thesis')]
watch:
    @echo "Starting thesis watch mode... (Ctrl+C to stop)"
    @echo "Watching for .tex file changes..."
    @$lastWrite = @{}; Get-ChildItem -Path . -Filter *.tex -Recurse | ForEach-Object { $lastWrite[$_.FullName] = $_.LastWriteTime }; while ($true) { Start-Sleep -Seconds 2; $changed = $false; Get-ChildItem -Path . -Filter *.tex -Recurse | ForEach-Object { if (-not $lastWrite.ContainsKey($_.FullName) -or $lastWrite[$_.FullName] -lt $_.LastWriteTime) { $lastWrite[$_.FullName] = $_.LastWriteTime; $changed = $true; Write-Host "Changed: $($_.Name)" -ForegroundColor Yellow } }; if ($changed) { Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Recompiling..." -ForegroundColor Cyan; pdflatex -interaction=nonstopmode main.tex | Out-Null; if ($LASTEXITCODE -eq 0) { Write-Host "Compiled successfully" -ForegroundColor Green } else { Write-Host "Compilation failed - check main.log" -ForegroundColor Red } } }

# Watch with full rebuild (includes biber for bibliography updates)
[group('thesis')]
watch-full:
    @echo "Starting thesis watch mode with full rebuild... (Ctrl+C to stop)"
    @echo "Watching for .tex and .bib file changes..."
    @$lastWrite = @{}; Get-ChildItem -Path . -Include *.tex,*.bib -Recurse | ForEach-Object { $lastWrite[$_.FullName] = $_.LastWriteTime }; while ($true) { Start-Sleep -Seconds 2; $changed = $false; Get-ChildItem -Path . -Include *.tex,*.bib -Recurse | ForEach-Object { if (-not $lastWrite.ContainsKey($_.FullName) -or $lastWrite[$_.FullName] -lt $_.LastWriteTime) { $lastWrite[$_.FullName] = $_.LastWriteTime; $changed = $true; Write-Host "Changed: $($_.Name)" -ForegroundColor Yellow } }; if ($changed) { Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Full rebuild..." -ForegroundColor Cyan; pdflatex -interaction=nonstopmode main.tex | Out-Null; biber main 2>$null; pdflatex -interaction=nonstopmode main.tex | Out-Null; pdflatex -interaction=nonstopmode main.tex | Out-Null; if ($LASTEXITCODE -eq 0) { Write-Host "Full rebuild complete" -ForegroundColor Green } else { Write-Host "Compilation failed - check main.log" -ForegroundColor Red } } }
