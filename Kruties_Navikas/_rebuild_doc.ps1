# ASCII driver. Content is UTF-8 JSON. Overwrites the same DOCX/PDF.
$ErrorActionPreference = "Stop"
$proj = "C:\Users\kamil\Documents\Uni Stuff\2026-09\LDs\Kruties_Navikas"
$outDir = "C:\Users\kamil\Documents\Uni Stuff\2026-09"
$fig = Join-Path $proj "reports\figures_clean"
$docx = Join-Path $outDir "IS_Egzaminas_ataskaita_Kamil_Skaskevic_EKSfm-26.docx"
$pdf  = Join-Path $outDir "IS_Egzaminas_ataskaita_Kamil_Skaskevic_EKSfm-26.pdf"
$jsonPath = Join-Path $proj "_rebuild_doc.json"

$j = Get-Content -LiteralPath $jsonPath -Encoding UTF8 -Raw | ConvertFrom-Json

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $word.Documents.Add()
$doc.PageSetup.PaperSize = 7
$doc.PageSetup.TopMargin = 56.7
$doc.PageSetup.BottomMargin = 56.7
$doc.PageSetup.LeftMargin = 62.4
$doc.PageSetup.RightMargin = 56.7
$doc.Content.Font.Name = "Times New Roman"
$doc.Content.Font.Size = 12
$doc.Content.ParagraphFormat.SpaceAfter = 8
$doc.Content.ParagraphFormat.SpaceBefore = 0
$doc.Content.ParagraphFormat.LineSpacingRule = 0
$doc.Content.ParagraphFormat.LineSpacing = 14.4

$sel = $word.Selection
$wdStory = 6
$wdColorGray = 14277081

function Go-End { $script:sel.EndKey($wdStory) | Out-Null }

function P([string]$text, [int]$size = 12, [bool]$bold = $false, [bool]$italic = $false, [int]$align = 0, [int]$spaceAfter = 8, [int]$spaceBefore = 0) {
  Go-End
  $script:sel.Font.Name = "Times New Roman"
  $script:sel.Font.Size = $size
  $script:sel.Font.Bold = $bold
  $script:sel.Font.Italic = $italic
  $script:sel.ParagraphFormat.Alignment = $align
  $script:sel.ParagraphFormat.SpaceAfter = $spaceAfter
  $script:sel.ParagraphFormat.SpaceBefore = $spaceBefore
  $script:sel.ParagraphFormat.FirstLineIndent = 0
  $script:sel.TypeText($text)
  $script:sel.TypeParagraph()
  $script:sel.Font.Bold = $false
  $script:sel.Font.Italic = $false
  $script:sel.Font.Size = 12
  $script:sel.ParagraphFormat.Alignment = 0
}

function Add-Eq([string]$um) {
  Go-End
  $script:sel.Font.Name = "Cambria Math"
  $script:sel.Font.Size = 12
  $script:sel.Font.Italic = $false
  $script:sel.ParagraphFormat.Alignment = 1
  $start = $script:sel.Start
  $script:sel.TypeText($um)
  $end = $script:sel.Start
  try {
    $rng = $script:doc.Range($start, $end)
    [void]$rng.OMaths.Add($rng)
    $n = $script:doc.OMaths.Count
    [void]$script:doc.OMaths.Item($n).BuildUp()
  } catch {
    Write-Host ("EQ skip: " + $_.Exception.Message)
  }
  $script:sel.TypeParagraph()
  $script:sel.Font.Name = "Times New Roman"
  $script:sel.ParagraphFormat.Alignment = 0
}

function Add-Tbl($rows, [string]$caption) {
  Go-End
  $nR = $rows.Count
  $nC = $rows[0].Count
  $rng = $script:sel.Range
  $tbl = $script:doc.Tables.Add($rng, $nR, $nC)
  $tbl.Borders.Enable = $true
  $tbl.Range.Font.Name = "Times New Roman"
  $tbl.Range.Font.Size = 9
  $tbl.Range.ParagraphFormat.SpaceAfter = 2
  $tbl.Range.ParagraphFormat.SpaceBefore = 1
  for ($i = 0; $i -lt $nR; $i++) {
    $row = $rows[$i]
    for ($k = 0; $k -lt $nC; $k++) {
      $cell = $tbl.Cell($i + 1, $k + 1)
      $cell.Range.Text = [string]$row[$k]
      $cell.Range.Font.Name = "Times New Roman"
      $cell.Range.Font.Size = 9
      $cell.VerticalAlignment = 1
      if ($i -eq 0) {
        $cell.Range.Font.Bold = $true
        $cell.Shading.BackgroundPatternColor = $wdColorGray
      }
    }
  }
  $tbl.AutoFitBehavior(2) | Out-Null
  Go-End
  $script:sel.TypeParagraph()
  if ($caption) { P $caption 12 $false $true 1 10 4 }
}

function Add-Pic([string]$file, [string]$caption, [string]$explain) {
  $path = Join-Path $fig $file
  if (-not (Test-Path -LiteralPath $path)) { throw "Missing figure $path" }
  Go-End
  $script:sel.ParagraphFormat.Alignment = 1
  $ish = $script:sel.InlineShapes.AddPicture($path, $false, $true)
  $ish.LockAspectRatio = $true
  $ish.Width = 425
  Go-End
  $script:sel.TypeParagraph()
  P $caption 12 $false $true 1 6 4
  if ($explain) { P $explain 12 $false $false 3 10 0 }
  $script:sel.ParagraphFormat.Alignment = 0
}

$sec = $doc.Sections.Item(1)
$hdr = $sec.Headers.Item(1)
$hdr.Range.Text = "Kamil Skaskevic, EKSfm-26  |  Intelektualiosios sistemos  |  egzamino ataskaita"
$hdr.Range.Font.Size = 9
$hdr.Range.Font.Name = "Times New Roman"
$hdr.Range.Font.Italic = $true
$ftr = $sec.Footers.Item(1)
$ftr.Range.Text = ""
$ftr.PageNumbers.Add(1) | Out-Null

foreach ($b in $j.blocks) {
  $t = [string]$b.t
  $x = [string]$b.x
  switch ($t) {
    "title1" { P $x 14 $true  $false 1 4 0 }
    "title2" { P $x 12 $false $false 1 4 0 }
    "title3" { P $x 14 $true  $false 1 4 0 }
    "title4" { P $x 18 $true  $false 1 8 0 }
    "title5" { P $x 14 $false $true  1 8 0 }
    "meta"   { P $x 12 $false $false 1 4 0 }
    "h1"     { P $x 14 $true  $false 0 8 12 }
    "h2"     { P $x 14 $true  $false 0 6 10 }
    "p"      { P $x 12 $false $false 3 8 0 }
    "cap"    { P $x 12 $false $true  1 10 4 }
    "lit"    { P $x 12 $false $false 0 4 0 }
    "eq"     { Add-Eq $x }
    "tbl"    {
      $rows = @()
      foreach ($r in $b.rows) { $rows += ,(@($r)) }
      Add-Tbl $rows ([string]$b.cap)
    }
    "pic"    { Add-Pic ([string]$b.f) ([string]$b.cap) ([string]$b.ex) }
    default  { throw "Unknown block $t" }
  }
}

foreach ($ish in @($doc.InlineShapes)) {
  try {
    if ($ish.LinkFormat) { $ish.LinkFormat.SavePictureWithDocument = $true; $ish.LinkFormat.BreakLink() }
  } catch {}
}

$doc.SaveAs2([string]$docx)
Write-Host "DOCX $docx"
$doc.ExportAsFixedFormat([string]$pdf, 17)
Write-Host "PDF  $pdf omath=$($doc.OMaths.Count) tables=$($doc.Tables.Count) pics=$($doc.InlineShapes.Count)"
$doc.Close($false)
$word.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
[GC]::Collect()
Get-Item -LiteralPath $docx, $pdf | Format-Table Name, Length, LastWriteTime
