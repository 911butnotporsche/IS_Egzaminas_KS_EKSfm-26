$ErrorActionPreference = "Stop"
$root = "C:\Users\kamil\Documents\Uni Stuff\2026-09\LDs\Kruties_Navikas"
$mdPath = Join-Path $root "IGYVENDINIMO_PLANAS.md"
$htmlPath = Join-Path $env:TEMP ("kruties_navikas_planas_" + [guid]::NewGuid().ToString("N") + ".html")
$docxPath = Join-Path $root "IGYVENDINIMO_PLANAS.docx"

function Escape-Html([string]$s) {
    if ($null -eq $s) { return "" }
    return ($s.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;"))
}

function Convert-LatexToReadable([string]$s) {
    $s = $s -replace '\\mathrm\{([^}]+)\}', '$1'
    $s = $s -replace '\\mathbf\{([^}]+)\}', '$1'
    $s = $s -replace '\\boldsymbol\{([^}]+)\}', '$1'
    $s = $s -replace '\\mathbb\{R\}', 'R'
    $s = $s -replace '\\mathcal\{([^}]+)\}', '$1'
    $s = $s -replace '\\hat\{([^}]+)\}', '$1-hat'
    $s = $s -replace '\\text\{([^}]+)\}', '$1'
    $s = $s -replace '\\operatorname\{([^}]+)\}', '$1'
    $s = $s -replace '\\,|\\;|\\!|\\:', ' '
    $s = $s -replace '\\left|\\right|\\bigl|\\bigr', ''
    $s = $s -replace '\\exp', 'exp'
    $s = $s -replace '\\min', 'min'
    $s = $s -replace '\\max', 'max'
    $s = $s -replace '\\sum', 'SUM'
    $s = $s -replace '\\sigma', 'sigma'
    $s = $s -replace '\\gamma', 'gamma'
    $s = $s -replace '\\alpha', 'alpha'
    $s = $s -replace '\\beta', 'beta'
    $s = $s -replace '\\varphi', 'phi'
    $s = $s -replace '\\phi', 'phi'
    $s = $s -replace '\\approx', '~='
    $s = $s -replace '\\ge', '>='
    $s = $s -replace '\\le', '<='
    $s = $s -replace '\\neq', '!='
    $s = $s -replace '\\times', 'x'
    $s = $s -replace '\\cdot', '*'
    $s = $s -replace '\\in', ' in '
    $s = $s -replace '\\frac\{([^}]+)\}\{([^}]+)\}', '($1)/($2)'
    $s = $s -replace '\\log', 'log'
    $s = $s -replace '\\|', '|'
    $s = $s -replace '\\\\', ' '
    $s = $s -replace '\{', ''
    $s = $s -replace '\}', ''
    $s = $s -replace '~', ' '
    return $s.Trim()
}

function Convert-Inline([string]$s) {
    $s = [regex]::Replace($s, '\$\$([\s\S]+?)\$\$', {
        param($m)
        return '<i>' + (Escape-Html (Convert-LatexToReadable $m.Groups[1].Value)) + '</i>'
    })
    $s = [regex]::Replace($s, '\\\[([\s\S]+?)\\\]', {
        param($m)
        return '<div style="text-align:center;margin:8pt 0;font-style:italic;">' + (Escape-Html (Convert-LatexToReadable $m.Groups[1].Value)) + '</div>'
    })
    $s = [regex]::Replace($s, '\\\((.+?)\\\)', {
        param($m)
        return '<i>' + (Escape-Html (Convert-LatexToReadable $m.Groups[1].Value)) + '</i>'
    })
    $s = [regex]::Replace($s, '(?<!\$)\$(.+?)\$(?!\$)', {
        param($m)
        return '<i>' + (Escape-Html (Convert-LatexToReadable $m.Groups[1].Value)) + '</i>'
    })

    $parts = [regex]::Split($s, '(`[^`]+`)')
    $out = New-Object System.Text.StringBuilder
    foreach ($p in $parts) {
        if ($p -match '^`(.+)`$') {
            [void]$out.Append('<code>' + (Escape-Html $Matches[1]) + '</code>')
        } else {
            $t = Escape-Html $p
            $t = [regex]::Replace($t, '\*\*(.+?)\*\*', '<b>$1</b>')
            $t = [regex]::Replace($t, '(?<!\*)\*(.+?)\*(?!\*)', '<i>$1</i>')
            $t = [regex]::Replace($t, '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>')
            [void]$out.Append($t)
        }
    }
    return $out.ToString()
}

function Is-TableSep([string]$line) {
    return $line -match '^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$'
}

function Parse-TableRow([string]$line) {
    $t = $line.Trim()
    if ($t.StartsWith('|')) { $t = $t.Substring(1) }
    if ($t.EndsWith('|')) { $t = $t.Substring(0, $t.Length - 1) }
    return @($t.Split('|') | ForEach-Object { $_.Trim() })
}

$md = [System.IO.File]::ReadAllText($mdPath, [System.Text.Encoding]::UTF8)
$lines = $md -split "`r?`n", -1
$html = New-Object System.Collections.Generic.List[string]
$html.Add('<!DOCTYPE html>')
$html.Add('<html lang="lt"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">')
$html.Add('<title>Igyvendinimo planas</title>')
$html.Add('<style>
body { font-family: "Times New Roman", Times, serif; font-size: 12pt; }
h1 { font-size: 18pt; text-align: center; }
h2 { font-size: 14pt; }
h3 { font-size: 12.5pt; }
p { margin: 0 0 8pt 0; text-align: justify; }
table { border-collapse: collapse; width: 100%; margin: 8pt 0 12pt; font-size: 11pt; }
th, td { border: 1px solid #222; padding: 4pt 6pt; vertical-align: top; }
th { background: #e8e8e8; }
code, pre { font-family: Consolas, "Courier New", monospace; font-size: 10pt; }
pre { background: #f4f4f4; padding: 8pt; border: 1px solid #ccc; white-space: pre-wrap; }
</style></head><body>')

$i = 0
$n = $lines.Count
while ($i -lt $n) {
    $line = $lines[$i]

    if ($line -match '^```') {
        $code = New-Object System.Collections.Generic.List[string]
        $i++
        while ($i -lt $n -and $lines[$i] -notmatch '^```') {
            $code.Add((Escape-Html $lines[$i]))
            $i++
        }
        $html.Add('<pre>' + ($code -join "`n") + '</pre>')
        $i++
        continue
    }

    if ($line -match '^\s*\|' -and ($i + 1) -lt $n -and (Is-TableSep $lines[$i + 1])) {
        $header = Parse-TableRow $line
        $i += 2
        $html.Add('<table><thead><tr>')
        foreach ($c in $header) { $html.Add('<th>' + (Convert-Inline $c) + '</th>') }
        $html.Add('</tr></thead><tbody>')
        while ($i -lt $n -and $lines[$i] -match '^\s*\|') {
            $row = Parse-TableRow $lines[$i]
            $html.Add('<tr>')
            for ($c = 0; $c -lt [Math]::Max($header.Count, $row.Count); $c++) {
                $cell = if ($c -lt $row.Count) { $row[$c] } else { '' }
                $html.Add('<td>' + (Convert-Inline $cell) + '</td>')
            }
            $html.Add('</tr>')
            $i++
        }
        $html.Add('</tbody></table>')
        continue
    }

    if ($line -match '^# ') { $html.Add('<h1>' + (Convert-Inline $line.Substring(2)) + '</h1>'); $i++; continue }
    if ($line -match '^## ') { $html.Add('<h2>' + (Convert-Inline $line.Substring(3)) + '</h2>'); $i++; continue }
    if ($line -match '^### ') { $html.Add('<h3>' + (Convert-Inline $line.Substring(4)) + '</h3>'); $i++; continue }
    if ($line -match '^---\s*$') { $html.Add('<hr>'); $i++; continue }
    if ([string]::IsNullOrWhiteSpace($line)) { $i++; continue }

    if ($line -match '^\s*[-*]\s+') {
        $html.Add('<ul>')
        while ($i -lt $n -and $lines[$i] -match '^\s*[-*]\s+(.*)$') {
            $html.Add('<li>' + (Convert-Inline $Matches[1]) + '</li>')
            $i++
        }
        $html.Add('</ul>')
        continue
    }

    if ($line -match '^\s*\d+\.\s+') {
        $html.Add('<ol>')
        while ($i -lt $n -and $lines[$i] -match '^\s*\d+\.\s+(.*)$') {
            $html.Add('<li>' + (Convert-Inline $Matches[1]) + '</li>')
            $i++
        }
        $html.Add('</ol>')
        continue
    }

    $para = New-Object System.Collections.Generic.List[string]
    while ($i -lt $n) {
        $cur = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($cur)) { break }
        if ($cur -match '^(#{1,3} |```|---\s*$)' ) { break }
        if ($cur -match '^\s*\|') { break }
        if ($cur -match '^\s*[-*]\s+') { break }
        if ($cur -match '^\s*\d+\.\s+') { break }
        $para.Add($cur.TrimEnd())
        $i++
    }
    $html.Add('<p>' + (Convert-Inline ($para -join ' ')) + '</p>')
}

$html.Add('</body></html>')
$utf8bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($htmlPath, ($html -join "`r`n"), $utf8bom)

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
    $doc = $word.Documents.Open($htmlPath)
    $doc.PageSetup.PaperSize = 7
    $doc.PageSetup.TopMargin = 72
    $doc.PageSetup.BottomMargin = 72
    $doc.PageSetup.LeftMargin = 85
    $doc.PageSetup.RightMargin = 72
    if (Test-Path -LiteralPath $docxPath) { Remove-Item -LiteralPath $docxPath -Force }
    $savePath = [string]$docxPath
    $doc.SaveAs2($savePath, 16)
    $doc.Close($false)
} finally {
    $word.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

Get-Item -LiteralPath $docxPath | Format-List FullName, Length, LastWriteTime
