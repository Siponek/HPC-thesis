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

# Compile all Mermaid diagrams to PDF
[group("thesis")]
compile-mermaid:
  #!pwsh
  Set-Location '{{diagrams_dir}}'
  Write-Host "Compiling Mermaid diagrams to PDF..."
  Get-ChildItem -Path . -Filter *.mmd | ForEach-Object {
    mmdc -i $_.Name -o "$($_.BaseName).pdf"
  }
  Write-Host "All Mermaid diagrams compiled!"

# Compile Mermaid diagrams to PNG
[group("thesis")]
compile-mermaid-png:
  #!pwsh
  Set-Location '{{diagrams_dir}}'
  Write-Host "Compiling Mermaid diagrams to PNG..."
  Get-ChildItem -Path . -Filter *.mmd | ForEach-Object {
    mmdc -i $_.Name -o "$($_.BaseName).png"
  }
  Write-Host "All Mermaid diagrams compiled to PNG!"

# Compile a specific Mermaid diagram (usage: just compile-mermaid-diagram architecture)
[group("thesis")]
compile-mermaid-diagram name:
  #!pwsh
  Set-Location '{{diagrams_dir}}'
  Write-Host "Compiling Mermaid diagram: {{name}}.mmd..."
  mmdc -i '{{name}}.mmd' -o '{{name}}.pdf'
  Write-Host "Diagram compiled: {{diagrams_dir}}/{{name}}.pdf"

# Compile a specific PlantUML diagram (usage: just compile-diagram http-sse-architecture)
[group("thesis")]
compile-diagram name:
  #!pwsh
  Set-Location '{{diagrams_dir}}'
  Write-Host "Compiling diagram: {{name}}.puml..."
  plantuml -tpdf '{{name}}.puml'
  Write-Host "Diagram compiled: {{diagrams_dir}}/{{name}}.pdf"

# Watch a single PlantUML diagram for rapid prototyping (usage: just watch-diagram openmp-mode)
[group("thesis")]
watch-diagram name:
  #!pwsh
  Set-Location '{{thesis_root}}'
  $diagramFile = Join-Path '{{diagrams_dir}}' '{{name}}.puml'
  $sharedDir = Join-Path '{{thesis_root}}' 'figures/shared'

  if (-not (Test-Path $diagramFile)) {
    Write-Host "Diagram not found: $diagramFile" -ForegroundColor Red
    exit 1
  }

  Write-Host "Starting PlantUML watch (single diagram)..." -ForegroundColor Cyan
  Write-Host "Watching: $diagramFile" -ForegroundColor Gray
  Write-Host "Also watching shared includes in: $sharedDir" -ForegroundColor Gray
  Write-Host "Output format: PNG (Ctrl+C to stop)`n" -ForegroundColor Gray

  $lastWrite = @{}
  $watchFiles = @($diagramFile)
  if (Test-Path $sharedDir) {
    $watchFiles += Get-ChildItem -Path $sharedDir -Filter *.puml -Recurse | ForEach-Object { $_.FullName }
  }

  foreach ($f in $watchFiles) {
    if (Test-Path $f) {
      $lastWrite[$f] = (Get-Item $f).LastWriteTimeUtc
    }
  }

  Set-Location '{{diagrams_dir}}'
  plantuml -tpng '{{name}}.puml'
  if ($LASTEXITCODE -eq 0) { Write-Host "Initial render complete: {{name}}.png" -ForegroundColor Green }
  else { Write-Host "Initial render failed" -ForegroundColor Red }

  while ($true) {
    Start-Sleep -Milliseconds 800
    $changed = $false

    foreach ($f in $watchFiles) {
      if (-not (Test-Path $f)) { continue }
      $current = (Get-Item $f).LastWriteTimeUtc
      if (-not $lastWrite.ContainsKey($f) -or $lastWrite[$f] -lt $current) {
        $lastWrite[$f] = $current
        $changed = $true
        Write-Host "Changed: $([System.IO.Path]::GetFileName($f))" -ForegroundColor Yellow
      }
    }

    if ($changed) {
      Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Re-rendering {{name}}.puml..." -ForegroundColor Cyan
      Set-Location '{{diagrams_dir}}'
      plantuml -tpng '{{name}}.puml'
      if ($LASTEXITCODE -eq 0) { Write-Host "Render OK: {{name}}.png`n" -ForegroundColor Green }
      else { Write-Host "Render failed`n" -ForegroundColor Red }
    }
  }

# Watch all PlantUML diagrams and re-render changed files to PNG
[group("thesis")]
watch-diagrams:
  #!pwsh
  Set-Location '{{thesis_root}}'
  $diagramsDirAbs = '{{diagrams_dir}}'
  $sharedDir = Join-Path '{{thesis_root}}' 'figures/shared'

  Write-Host "Starting PlantUML watch (all diagrams)..." -ForegroundColor Cyan
  Write-Host "Watching diagrams: $diagramsDirAbs" -ForegroundColor Gray
  Write-Host "Watching shared includes: $sharedDir" -ForegroundColor Gray
  Write-Host "Output format: PNG (Ctrl+C to stop)`n" -ForegroundColor Gray

  $lastWrite = @{}
  Get-ChildItem -Path $diagramsDirAbs -Filter *.puml | ForEach-Object {
    $lastWrite[$_.FullName] = $_.LastWriteTimeUtc
  }
  if (Test-Path $sharedDir) {
    Get-ChildItem -Path $sharedDir -Filter *.puml -Recurse | ForEach-Object {
      $lastWrite[$_.FullName] = $_.LastWriteTimeUtc
    }
  }

  while ($true) {
    Start-Sleep -Milliseconds 800
    $changedDiagramFiles = @()
    $sharedChanged = $false

    Get-ChildItem -Path $diagramsDirAbs -Filter *.puml | ForEach-Object {
      if (-not $lastWrite.ContainsKey($_.FullName) -or $lastWrite[$_.FullName] -lt $_.LastWriteTimeUtc) {
        $lastWrite[$_.FullName] = $_.LastWriteTimeUtc
        $changedDiagramFiles += $_.Name
      }
    }

    if (Test-Path $sharedDir) {
      Get-ChildItem -Path $sharedDir -Filter *.puml -Recurse | ForEach-Object {
        if (-not $lastWrite.ContainsKey($_.FullName) -or $lastWrite[$_.FullName] -lt $_.LastWriteTimeUtc) {
          $lastWrite[$_.FullName] = $_.LastWriteTimeUtc
          $sharedChanged = $true
        }
      }
    }

    if ($sharedChanged) {
      Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Shared include changed -> re-rendering all diagrams..." -ForegroundColor Cyan
      Set-Location $diagramsDirAbs
      plantuml -tpng *.puml
      if ($LASTEXITCODE -eq 0) { Write-Host "Rendered all diagrams`n" -ForegroundColor Green }
      else { Write-Host "Render failed`n" -ForegroundColor Red }
      continue
    }

    if ($changedDiagramFiles.Count -gt 0) {
      Set-Location $diagramsDirAbs
      foreach ($f in $changedDiagramFiles) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Re-rendering $f..." -ForegroundColor Cyan
        plantuml -tpng $f
        if ($LASTEXITCODE -eq 0) { Write-Host "Render OK: $f" -ForegroundColor Green }
        else { Write-Host "Render failed: $f" -ForegroundColor Red }
      }
      Write-Host ""
    }
  }

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
rebuild: clean-all compile-diagrams compile-mermaid compile-thesis
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
