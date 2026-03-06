# HPC Thesis Compilation
# ----------------------
# Self-contained justfile for thesis compilation (shebang recipes)

# Could do  @& { --- } code blocks for single shell invocation

thesis_root := source_directory()
diagrams_dir := thesis_root / "figures/diagrams"

# Compile main thesis document
[group("thesis")]
compile-thesis:
  #!pwsh
  Set-Location '{{thesis_root}}'
  Write-Host "Compiling main thesis document..."
  pdflatex main.tex
  biber main
  pdflatex main.tex
  pdflatex main.tex
  Write-Host "Thesis compilation complete! Output: main.pdf"

# Compile all PlantUML diagrams to PDF
[group("thesis")]
compile-diagrams:
  #!pwsh
  Set-Location '{{diagrams_dir}}'
  Write-Host "Compiling PlantUML diagrams..."
  plantuml -tpdf *.puml
  Write-Host "All PlantUML diagrams compiled!"

# Compile PlantUML diagrams to PNG
[group("thesis")]
compile-diagrams-png:
  #!pwsh
  Set-Location '{{diagrams_dir}}'
  Write-Host "Compiling PlantUML diagrams to PNG..."
  plantuml -tpng *.puml
  Write-Host "All PlantUML diagrams compiled to PNG!"

# Compile a specific PlantUML diagram (usage: just compile-diagram http-sse-architecture)
[group("thesis")]
compile-diagram name:
  #!pwsh
  Set-Location '{{diagrams_dir}}'
  Write-Host "Compiling diagram: {{name}}.puml..."
  plantuml -tpdf '{{name}}.puml'
  Write-Host "Diagram compiled: {{diagrams_dir}}/{{name}}.pdf"

# Clean thesis auxiliary files
[group("thesis")]
clean-thesis:
  #!pwsh
  Set-Location '{{thesis_root}}'
  Write-Host "Cleaning thesis auxiliary files..."

  $files = @(
    "main.aux","main.bbl","main.bcf","main.blg","main.fdb_latexmk","main.fls","main.log",
    "main.lof","main.lot","main.lol","main.out","main.run.xml","main.toc","indent.log"
  )

  foreach ($f in $files) {
    if (Test-Path $f) { Remove-Item $f -Force }
  }

  Write-Host "Thesis auxiliary files cleaned!"

# Clean diagram auxiliary files
[group("thesis")]
clean-diagrams:
  #!pwsh
  Set-Location '{{diagrams_dir}}'
  Write-Host "Cleaning diagram auxiliary files..."
  Get-ChildItem -Path . -Include *.aux,*.log -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
  Write-Host "Diagram auxiliary files cleaned!"

# Clean all thesis and diagram auxiliary files
[group("thesis")]
clean-all: clean-thesis clean-diagrams
  #!pwsh
  Write-Host "All auxiliary files cleaned!"

# Full rebuild: clean and compile everything
[group("thesis")]
rebuild: clean-all compile-diagrams compile-thesis
  #!pwsh
  Write-Host "Full thesis rebuild complete!"

# Quick compile (only once, useful for quick checks)
[group("thesis")]
quick-compile:
  #!pwsh
  Set-Location '{{thesis_root}}'
  Write-Host "Quick compiling thesis..."
  pdflatex main.tex
  Write-Host "Quick compilation complete! (Note: bibliography may not be updated)"

# Open the compiled thesis PDF
[group("thesis")]
open-thesis:
  #!pwsh
  Set-Location '{{thesis_root}}'
  Start-Process "main.pdf"

# View thesis compilation log
[group("thesis")]
view-log:
  #!pwsh
  Set-Location '{{thesis_root}}'
  if (Test-Path "main.log") { Get-Content "main.log" } else { Write-Host "No log file found" -ForegroundColor Red }

# Show only critical errors from the log (fatal errors that prevent PDF generation)
[group("thesis")]
errors:
  #!pwsh
  Set-Location '{{thesis_root}}'
  Write-Host "Scanning for critical LaTeX errors..."
  if (-not (Test-Path "main.log")) {
    Write-Host "No log file found. Run compile-thesis first." -ForegroundColor Yellow
    exit 0
  }

  Get-Content "main.log" | Select-String -Pattern "^!" | ForEach-Object { Write-Host $_ -ForegroundColor Red }
  Get-Content "main.log" | Select-String -Pattern "Runaway argument" | ForEach-Object { Write-Host $_ -ForegroundColor Red }
  Get-Content "main.log" | Select-String -Pattern "Emergency stop" | ForEach-Object { Write-Host $_ -ForegroundColor Red }
  Get-Content "main.log" | Select-String -Pattern "Fatal error" | ForEach-Object { Write-Host $_ -ForegroundColor Red }
  Get-Content "main.log" | Select-String -Pattern "File .* not found" | ForEach-Object { Write-Host $_ -ForegroundColor Red }

# Show warnings from the log (undefined references, citations, etc.)
[group("thesis")]
warnings:
  #!pwsh
  Set-Location '{{thesis_root}}'
  Write-Host "Scanning for LaTeX warnings..."
  if (-not (Test-Path "main.log")) {
    Write-Host "No log file found. Run compile-thesis first." -ForegroundColor Yellow
    exit 0
  }

  Get-Content "main.log" | Select-String -Pattern "LaTeX Warning" | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }

# Watch for changes and recompile thesis automatically
[group("thesis")]
watch:
  #!pwsh
  Set-Location '{{thesis_root}}'
  Write-Host "Starting thesis watch mode... (Ctrl+C to stop)"
  Write-Host "Watching for .tex file changes..."

  $lastWrite = @{}
  Get-ChildItem -Path . -Filter *.tex -Recurse | ForEach-Object { $lastWrite[$_.FullName] = $_.LastWriteTime }

  while ($true) {
    Start-Sleep -Seconds 2
    $changed = $false

    Get-ChildItem -Path . -Filter *.tex -Recurse | ForEach-Object {
      if (-not $lastWrite.ContainsKey($_.FullName) -or $lastWrite[$_.FullName] -lt $_.LastWriteTime) {
        $lastWrite[$_.FullName] = $_.LastWriteTime
        $changed = $true
        Write-Host "Changed: $($_.Name)" -ForegroundColor Yellow
      }
    }

    if ($changed) {
      Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Recompiling..." -ForegroundColor Cyan
      pdflatex -interaction=nonstopmode main.tex | Out-Null
      if ($LASTEXITCODE -eq 0) { Write-Host "Compiled successfully" -ForegroundColor Green }
      else { Write-Host "Compilation failed - check main.log" -ForegroundColor Red }
    }
  }

# Watch with full rebuild (includes biber for bibliography updates)
[group("thesis")]
watch-full:
  #!pwsh
  Set-Location '{{thesis_root}}'
  Write-Host "Starting thesis watch mode with full rebuild... (Ctrl+C to stop)"
  Write-Host "Watching for .tex and .bib file changes..."

  $lastWrite = @{}
  Get-ChildItem -Path . -Include *.tex,*.bib -Recurse | ForEach-Object { $lastWrite[$_.FullName] = $_.LastWriteTime }

  while ($true) {
    Start-Sleep -Seconds 2
    $changed = $false

    Get-ChildItem -Path . -Include *.tex,*.bib -Recurse | ForEach-Object {
      if (-not $lastWrite.ContainsKey($_.FullName) -or $lastWrite[$_.FullName] -lt $_.LastWriteTime) {
        $lastWrite[$_.FullName] = $_.LastWriteTime
        $changed = $true
        Write-Host "Changed: $($_.Name)" -ForegroundColor Yellow
      }
    }

    if ($changed) {
      Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Full rebuild..." -ForegroundColor Cyan
      pdflatex -interaction=nonstopmode main.tex | Out-Null
      biber main 2>$null
      pdflatex -interaction=nonstopmode main.tex | Out-Null
      pdflatex -interaction=nonstopmode main.tex | Out-Null

      if ($LASTEXITCODE -eq 0) { Write-Host "Full rebuild complete" -ForegroundColor Green }
      else { Write-Host "Compilation failed - check main.log" -ForegroundColor Red }
    }
  }
