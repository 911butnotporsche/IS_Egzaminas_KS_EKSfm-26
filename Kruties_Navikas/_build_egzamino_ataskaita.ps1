# UTF-8 BOM. Builds IS exam report DOCX+PDF. Does not modify MATLAB/CSV sources.
$ErrorActionPreference = "Stop"
$proj = "C:\Users\kamil\Documents\Uni Stuff\2026-09\LDs\Kruties_Navikas"
$outDir = "C:\Users\kamil\Documents\Uni Stuff\2026-09"
$fig = Join-Path $proj "reports\figures_clean"
$docx = Join-Path $outDir "IS_Egzaminas_ataskaita_Kamil_Skaskevic_EKSfm-26.docx"
$pdf  = Join-Path $outDir "IS_Egzaminas_ataskaita_Kamil_Skaskevic_EKSfm-26.pdf"

Get-Process WINWORD -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq "" } | Out-Null

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $word.Documents.Add()
$doc.PageSetup.PaperSize = 7 # A4
$doc.PageSetup.TopMargin = 56.7
$doc.PageSetup.BottomMargin = 56.7
$doc.PageSetup.LeftMargin = 62.4
$doc.PageSetup.RightMargin = 56.7
$doc.Content.Font.Name = "Calibri"
$doc.Content.Font.Size = 12
$doc.Content.ParagraphFormat.SpaceAfter = 8
$doc.Content.ParagraphFormat.SpaceBefore = 0
$doc.Content.ParagraphFormat.LineSpacingRule = 1 # wdLineSpace1pt5? 0=single 1=1.5 2=double; use 0 + 1.08 via LineSpacing
$doc.Content.ParagraphFormat.LineSpacingRule = 0
$doc.Content.ParagraphFormat.LineSpacing = 14.4

$sel = $word.Selection
$wdStory = 6
$wdCollapseEnd = 0
$wdHeaderFooterPrimary = 1
$wdOrientPortrait = 0
$wdLineStyleSingle = 1
$wdAlignParagraphLeft = 0
$wdAlignParagraphCenter = 1
$wdAlignParagraphJustify = 3
$wdColorGray = 14277081

function Go-End {
  $script:sel.EndKey($wdStory) | Out-Null
}
function P([string]$text, [int]$size = 12, [bool]$bold = $false, [bool]$italic = $false, [int]$align = 0, [int]$spaceAfter = 8, [int]$spaceBefore = 0) {
  Go-End
  $script:sel.Font.Name = "Calibri"
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
function H1([string]$t) { P $t 14 $true $false 0 8 12 }
function H2([string]$t) { P $t 12 $true $false 0 6 8 }
function Body([string]$t) { P $t 12 $false $false 3 8 0 }
function Cap([string]$t) { P $t 11 $false $true 1 10 4 }

function Add-Tbl([object[][]]$data, [string]$caption) {
  Go-End
  $nR = $data.Length
  $nC = $data[0].Length
  $rng = $script:sel.Range
  $tbl = $script:doc.Tables.Add($rng, $nR, $nC)
  $tbl.Borders.Enable = $true
  $tbl.Range.Font.Name = "Calibri"
  $tbl.Range.Font.Size = 9
  $tbl.Range.Font.Bold = $false
  $tbl.Range.ParagraphFormat.SpaceAfter = 2
  $tbl.Range.ParagraphFormat.SpaceBefore = 1
  $tbl.Range.ParagraphFormat.Alignment = 0
  for ($i = 0; $i -lt $nR; $i++) {
    for ($j = 0; $j -lt $nC; $j++) {
      $cell = $tbl.Cell($i + 1, $j + 1)
      $cell.Range.Text = [string]$data[$i][$j]
      $cell.Range.Font.Size = 9
      $cell.Range.Font.Name = "Calibri"
      $cell.VerticalAlignment = 1
      if ($i -eq 0) {
        $cell.Range.Font.Bold = $true
        $cell.Shading.BackgroundPatternColor = $wdColorGray
      }
    }
  }
  $tbl.AutoFitBehavior(2) | Out-Null # wdAutoFitWindow
  Go-End
  $script:sel.TypeParagraph()
  if ($caption) { Cap $caption }
}

function Add-Pic([string]$path, [string]$caption) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Nera paveikslo: $path" }
  Go-End
  $script:sel.ParagraphFormat.Alignment = 1
  $ish = $script:sel.InlineShapes.AddPicture($path, $false, $true)
  $ish.LockAspectRatio = $true
  $ish.Width = 425
  try { $null = $ish.LinkFormat } catch {}
  Go-End
  $script:sel.TypeParagraph()
  Cap $caption
  $script:sel.ParagraphFormat.Alignment = 0
}

# Header / footer
$sec = $doc.Sections.Item(1)
$hdr = $sec.Headers.Item($wdHeaderFooterPrimary)
$hdr.Range.Text = "Kamil Skaskevič, EKSfm-26  |  Intelektualiosios sistemos  |  egzamino ataskaita"
$hdr.Range.Font.Size = 9
$hdr.Range.Font.Name = "Calibri"
$hdr.Range.Font.Italic = $true
$hdr.Range.ParagraphFormat.Alignment = 0
$ftr = $sec.Footers.Item($wdHeaderFooterPrimary)
$ftr.Range.Text = ""
$ftr.PageNumbers.Add(1) | Out-Null

# ===== TITLE =====
P "Intelektualiosios sistemos" 18 $true $false 1 4 0
P "Galutinio egzamino dalis: veikiantis ir atkuriamas sprendimas" 14 $true $false 1 4 0
P "Krūties naviko klasifikavimas pagal branduolių požymius (WDBC)" 13 $false $true 1 8 0
P "Kamil Skaskevič, EKSfm-26. Visi skaičiai skaityti iš reports/tables/main_results.csv, hypotheses.csv, ablation.csv ir reports/error_cases.csv. Grafikai – reports/figures_clean/. Koeficientų reikšmės – užšaldyti models/mlp.mat (1-asis iš 5 tinklų) ir models/rbfnet.mat. Jokių skaičių neišgalvota." 11 $false $false 1 14 0

H1 "1. Užduotis ir kontekstas iš kolokviumo (santrauka)"
Body "Uzduotis: is 30 jau apskaiciuotu FNA branduoliu pozymiu (be ID) atskirti piktybini (M=1) nuo gerybinio (B=0) atvejo UCI WDBC rinkinyje [1, 2] (n=569, 212 M / 357 B). Tai dvejetainis klasifikavimas su kalibruota P(M|x), ne vaizdu analize ir ne klinikine diagnoze. Kolokviume uzfiksuota: FN kaina 5:1 pries FP; tesinis atskiriamumas gali duoti lubu efekta AUC; testas uzrakinamas; H1 – taške t_se98 Sp(SVM)−Sp(LR)>=0,03 ir AUC ne-prastesnumas (DeLong PI apacia >= −0,005); H2 – Brier/kalibracija; H3 – idetinis CV po testo, neatstoja H1. Pagrindinis metodas plane – SVM-RBF; atskaitos – dauguma ir L2 logistine regresija; alternatyvos – MLP ir RBF tinklas. Sios ataskaitos dalykas – igyvendinimas ir uzrakinto testo irodymas; problemos isskaidymas ir literaturos apzvalga – kolokviumo dokumente Kruties_naviko_klasifikavimas_igyvendinimo_planas ir cia neatkartojami."

H1 "2. Įgyvendinimas: duomenų grandinė, baseline ir metodai"
Body "Sprendimas – MATLAB R2026a projektas su vienu vamzdziu run_all.m. Duomenys: get_wdbc / load_wdbc (UCI ID 17, DOI 10.24432/C5DW2B [1]; 569 eilutes, 0 NaN, X<0 draudziama, nuliai concavity leistini). Skaidymas: cvpartition HoldOut 0,20 Stratify, rng(42) – faktas 456 mokymas (170 M / 286 B) ir 113 testas (42 M / 71 B), priimta preregistration.md, nekirpta. Z-score (1) tik is mokymo (fit_scaler klaida jei n=569). Vidinis CV: 5x5=25 skaidiniai, scaler kiekviename folde is naujo (tune_cv.m). Testas atraunamas lygiai karta evaluate_test.m. Naudojimas: app/predict_case.m (be fit)."

Add-Tbl @(
  @("Elementas", "Tipas", "Interpretacija"),
  @("Ivestis x", "R^30 (be ID)", "vienas FNA atvejis; NaN/Inf ir x<0 – error, ne imputacija"),
  @("p_malignant", "[1e-15; 1-1e-15]", "P(M|z) po Platt / sigmoides"),
  @("threshold t", "[0; 1]", "OOF t_se98, t_cost arba t_youden"),
  @("decision", "{B, M}", "M jei p >= t"),
  @("margin_flag / ood_flag", "loginis", "|p-t|<0,10; x uz mokymo min–max"),
  @("disclaimer", "tekstas", "mokomasis prototipas, ne diagnostika")
) "1 lentele. Sistemos ivestis ir isvestis (predict_case.m)."

H2 "2.2 Baseline ir intelektualieji metodai"
Body "Visi metodai gauna ta pati Z pagal (1). Hiperparametrai – vidutinis OOF AUC per 25 skaidinius; jei |dAUC|<0,002, paprastesnis tinklelio narys (tune_cv.m). Uzsaldyti HP (models/*.mat, laukas hp; ne is testo CSV): LR lambda=0,1; SVM-RBF C=0,3, s=8; MLP H=5, lambda=0,3, 5 seklos; RBF tinklas J=40, kappa=2, lambda=0,1."

Add-Tbl @(
  @("Modelis", "Failas / funkcija", "Naudojimo formule", "HP"),
  @("B0 dauguma", "train_majority.m", "visada B; p = P_mok(M)", "–"),
  @("B1 L2 LR", "train_logreg.m, fitclinear", "p = sigma(w^T z + b)", "lambda"),
  @("M1 SVM-RBF", "train_svm_rbf.m, fitcsvm + Platt", "f(z)=Sum a_i y_i K_s(z_i,z)+b; p=Platt(f)", "C, s"),
  @("M2 MLP", "train_mlp.m, mlp_backprop_manual.m", "h=tanh(W1 z+b1), p=sigma(w2^T h + b2)", "H, lambda, seklos"),
  @("M3 RBF tinklas", "train_rbfnet.m", "a = w0 + Sum w_j phi_j(z)", "J, kappa, lambda")
) "2 lentele. Igyvendinti metodai, vieta kode ir naudojimo formules."

H1 "3. Tinklo koeficientai, formulės ir sąsaja su kodu"
Body "Sis skyrius tiesiogiai atsako i keturis destytojo praktines dalies punktus. Produkcinis MLP mokomas MATLAB patternnet + trainscg (train_mlp.m) – analogiskai tam, kaip Marcin ataskaitoje SVR mokyma vykdo bibliotekos sprendiklis. Egzamino reikalaujamos isejimo ir backpropagation formules irasytos ir vykdomos atskirame faile mlp_backprop_manual.m (antraste: Kolokviumo 3.3; 'Palyginimui, ne HP paieskai'). RBF tinklo svoriai – uzdara ridge formule, ne BP (train_rbfnet.m)."

H2 "3.1 Koeficientų sužymėjimas (MLP 30 → H = 5 → 1)"
Body "Architektura: iejimas z in R^30 (jau z-score), pasleptas sluoksnis H=5 su tansig=tanh, isejimas 1 neuronas su logsig=sigma. Uzsaldytame mlp.mat yra 5 tinklai (sekos 1:5); predict_proba vidurkina ju p. Zemiau – viso 1-ojo tinklo (nets{1}) koeficientai, nuskaitomi is modelio, ne is CV."

Add-Tbl @(
  @("Koeficientas", "Dydis", "Reiksme / santrauka", "Kur saugoma"),
  @("H", "skaliaras", "5  (hp.H, models/mlp.mat)", "model.H"),
  @("lambda", "skaliaras", "0,3", "model.lambda"),
  @("W1 = IW{1}", "5 x 30", "min=-0,303; max=0,301; RMS=0,129; ||W1||_F=1,581", "net.IW{1}"),
  @("b1 = b{1}", "5 x 1", "[-1,254; 1,246; 1,122; -0,207; 0,271]^T", "net.b{1}"),
  @("w2^T = LW{2,1}", "1 x 5", "[1,572; 0,853; 0,624; -1,547; 1,778]", "net.LW{2,1}"),
  @("b2 = b{2}", "1 x 1", "0,0115", "net.b{2}"),
  @("aktyvacijos", "–", "sluoksnis 1: tansig (tanh); sluoksnis 2: logsig (sigma)", "net.layers{i}.transferFcn"),
  @("ansamblis", "5 tinklai", "||W1||_F = 1,58; 2,10; 2,23; 2,12; 2,28;  b2 = 0,012; 0,514; 0,472; 0,315; 0,827", "model.nets")
) "3 lentele. MLP koeficientai (models/mlp.mat, nets{1}, jei nenurodyta kitaip)."

Add-Tbl @(
  @("h", "W1 st. 1–8 (suapvalinta iki 3 sk.)"),
  @("1", "0,293  0,136  0,024  0,143  0,171  0,009  0,026  0,014"),
  @("2", "-0,063  0,125  0,110  0,013  0,151  -0,045  0,146  -0,006"),
  @("3", "0,083  0,043  0,013  0,035  -0,049  0,069  -0,024  0,138"),
  @("4", "-0,249  -0,171  -0,182  -0,072  -0,146  -0,026  -0,117  -0,190"),
  @("5", "0,273  0,120  0,286  0,287  0,004  0,084  0,064  0,182")
) "4 lentele. W1 eilutes, stulpeliai 1–8 (nets{1}). Likę 22 stulpeliai tame paciame IW{1}; visuma 5x30."

Add-Tbl @(
  @("h", "W1 st. 9–16"),
  @("1", "-0,028  0,009  0,068  0,093  0,118  0,119  -0,032  0,023"),
  @("2", "0,042  0,086  0,070  0,075  -0,018  0,059  0,094  0,001"),
  @("3", "0,144  -0,005  0,035  0,088  0,024  -0,007  -0,061  -0,091"),
  @("4", "0,104  0,037  -0,133  0,024  -0,178  -0,263  -0,019  0,082"),
  @("5", "-0,015  -0,219  0,168  0,061  0,221  0,231  0,037  -0,140")
) "5 lentele. W1 stulpeliai 9–16 (nets{1})."

Add-Tbl @(
  @("h", "W1 st. 17–24"),
  @("1", "0,049  0,143  0,030  -0,034  0,208  0,197  0,137  0,229"),
  @("2", "0,105  -0,080  0,013  0,026  0,158  0,018  0,009  0,023"),
  @("3", "-0,096  0,078  -0,116  0,015  0,036  0,147  0,168  0,001"),
  @("4", "-0,088  0,024  0,108  0,168  -0,129  -0,254  -0,281  -0,303"),
  @("5", "-0,081  -0,008  -0,054  -0,200  0,108  0,301  0,265  0,107")
) "6 lentele. W1 stulpeliai 17–24 (nets{1})."

Add-Tbl @(
  @("h", "W1 st. 25–30"),
  @("1", "0,095  -0,024  0,148  0,252  0,018  -0,048"),
  @("2", "-0,084  -0,012  0,021  0,088  0,041  0,073"),
  @("3", "-0,085  -0,035  0,172  -0,078  0,015  0,079"),
  @("4", "-0,113  0,057  -0,159  0,005  -0,194  -0,084"),
  @("5", "0,300  0,094  0,242  0,014  0,124  0,066")
) "7 lentele. W1 stulpeliai 25–30 (nets{1}). Su 4–6 lentelėmis tai visa 5x30 matrica."

H2 "3.2 Išėjimo (atsako) skaičiavimas – pilnos formulės"
Body "Ivestis z in R^30. Paslėptas pre-aktyvacijos vektorius a^(1) in R^H:"
P "a^(1) = W1 z + b1,    W1 in R^{H x 30},  b1 in R^H,  H = 5." 12 $false $true 1 6 2
Body "Pasleptas atsakas (tansig = tanh, elementinis):"
P "h = tanh(a^(1)),    h_j = (e^{a_j} - e^{-a_j}) / (e^{a_j} + e^{-a_j}),  j = 1..H." 12 $false $true 1 6 2
Body "Isejimo pre-aktyvacija ir tikimybe (logsig = sigma):"
P "a^(2) = w2^T h + b2,    p = sigma(a^(2)) = 1 / (1 + e^{-a^(2)}),    p = P(M|z) in (0,1)." 12 $false $true 1 6 2
Body "Klases sprendimas su uzsaldytu slenkscio t (OOF, ne testas):  y-hat = 1[p >= t]. Produkcijoje 5 tinklu p vidurkinami (predict_proba.m, kind='mlp'). Tai ta pati 30->H->1 grandine kaip train_mlp.m antrasteje."

H2 "3.3 Koeficientų atnaujinimas (backpropagation)"
Body "Tikslas – vidutinis binarinis kryžminės entropijos nuostolis su L2:"
P "L = -(1/n) Sum_i [ y_i log p_i + (1-y_i) log(1-p_i) ] + (lambda/2) ( ||W1||_F^2 + ||w2||^2 )." 12 $false $true 1 6 2
Body "Isvestines pagal isejima (delta taisykle, [14]):"
P "delta^(2) = p - y     (1 x n, kiekvienam objektui)." 12 $false $true 1 6 2
Body "Paslėptam sluoksniui tanh isvestine yra 1 - h odot h:"
P "delta^(1) = (1 - h odot h) odot (w2  delta^(2)),     delta^(1) in R^{H x n}." 12 $false $true 1 6 2
Body "Gradientinis zingsnis eta, vidurkis per n, L2 ant W1 ir w2 (poslinkiai nereguliuojami, kaip kode):"
P "W1 <- W1 - (eta/n) delta^(1) Z - eta lambda W1" 12 $false $true 1 4 2
P "b1 <- b1 - (eta/n) Sum_stulpeliais delta^(1)" 12 $false $true 1 4 0
P "w2 <- w2 - (eta/n) h delta^(2)^T - eta lambda w2" 12 $false $true 1 4 0
P "b2 <- b2 - (eta/n) Sum delta^(2)" 12 $false $true 1 8 0
Body "Z cia – mokymo matrica n x 30 (eilutes = objektai); kode Z' ir Z suderinti su H x n sandaugomis. Produkcinis mokymas train_mlp.m naudoja scaled conjugate gradient (trainscg) su ta pacia architektura ir L2 (performParam.regularization=lambda), o ne sias keturias eilutes – kaip Marcin ataskaitoje LIBSVM vs rankine dualine formule. Rankinis BP yra mlp_backprop_manual.m."

H2 "3.4 Formulė ↔ kodo eilutė (pagrindinė dėstytojo lentelė)"
Add-Tbl @(
  @("Formules dalis", "Kodas", "Failas, eil."),
  @("h = tanh(W1 z + b1)", "a1 = W1 * Z' + b1;  h = tanh(a1);", "mlp_backprop_manual.m 17-18"),
  @("p = sigma(w2^T h + b2)", "a2 = w2' * h + b2;  p1 = 1./(1+exp(-a2));", "mlp_backprop_manual.m 19-20"),
  @("delta^(2) = p - y", "delta2 = p1 - y';", "mlp_backprop_manual.m 22"),
  @("delta^(1) = (1-h.^2) odot (w2 delta^(2))", "delta1 = (1 - h.^2) .* (w2 * delta2);", "mlp_backprop_manual.m 23"),
  @("W1 atnaujinimas + L2", "W1 = W1 - (eta/n)*(delta1*Z) - eta*lambda*W1;", "mlp_backprop_manual.m 24"),
  @("b1 atnaujinimas", "b1 = b1 - (eta/n)*sum(delta1, 2);", "mlp_backprop_manual.m 25"),
  @("w2 atnaujinimas + L2", "w2 = w2 - (eta/n)*(h*delta2') - eta*lambda*w2;", "mlp_backprop_manual.m 26"),
  @("b2 atnaujinimas", "b2 = b2 - (eta/n)*sum(delta2);", "mlp_backprop_manual.m 27"),
  @("L stebejimas", "hist(t) = kryzmine entropija + (lambda/2)||W||^2", "mlp_backprop_manual.m 28-29"),
  @("Init W1,b1,w2,b2", "W1=0.1*randn(H,p); b1=0; w2=0.1*randn(H,1); b2=0;", "mlp_backprop_manual.m 11-14"),
  @("Produkcijos isejimas", "out = net(Z')'; p = out(:,1);  (logsig)", "predict_proba.m 65-72"),
  @("Produkcijos mokymas", "patternnet(H,'trainscg'); net=train(net,Z',T,...)", "train_mlp.m 22-37"),
  @("Ansamblis 5 seklos", "for i=1:5 ... tmp=train_mlp(...,seeds(i),...)", "tune_cv.m train_final / fold_score")
) "8 lentele. MLP formules nariu atitikmenys kode (kaip pavyzdzio 3 lentele)."

Body "Komentarai ir tvarka (9 vs 10 balu kriterijus). mlp_backprop_manual.m pradzioje yra Kolokviumo 3.3 antraste su h=tanh ir p=sigma bei delta taisykle; kiekvienas zingsnis – atskira eilute su matricu dydziais komentaruose (H x n, 1 x n). train_mlp.m: antraste, n=569 apsauga, validacija tik is foldo mokymo (divideind, testInd=[]), processFcns isjungti kad nebūtų antro skalavimo. train_rbfnet.m ir rbf_phi antrastese – 3.4 formule. Tai ne 'vos keli komentarai', o modulio antrastes + inline dydziai. Rankinis BP nenaudojamas HP paieskai – tai sarase aiškiai parasyta, kad nebutu painiavos su patternnet."

H2 "3.5 RBF tinklas: koeficientai ir uzdara update formule"
Body "M3 nera BP. Centrai c_j in R^30 (J=40) – k-means tik ant mokymo Z; plociai s_j = kappa * vidutinis atstumas iki 2 artimiausiu kitu centru, kappa=2; isejimas ỹ in {-1,+1}, w = (Phi1^T Phi1 + lambda I)^{-1} Phi1^T ỹ, lambda=0,1, Phi1 = [1, phi(Z)]."

P "phi_j(z) = exp( -||z - c_j||^2 / (2 s_j^2) ),    a(z) = w0 + Sum_{j=1}^{40} w_j phi_j(z),    p = sigma(a)." 12 $false $true 1 8 2

Add-Tbl @(
  @("Koeficientas", "Dydis", "Reiksme (models/rbfnet.mat)"),
  @("J", "skaliaras", "40"),
  @("kappa, lambda", "skaliarai", "2 ir 0,1"),
  @("c_j (centers)", "40 x 30", "pilna matrica faile; 1-os eil. 6 pirmi: 3,79; 0,70; 3,85; 5,10; 1,12; 1,38 (z-skale)"),
  @("s_j (widths)", "40 x 1", "min=4,238; max=25,543; vidurkis=8,540 (visas vektorius 9 lenteleje)"),
  @("w = [w0; w_1..w_40]", "41 x 1", "w0=0,324; ||w_{1:40}||=7,049")
) "Koeficientu suzymejimas RBF tinklui."

# widths 8 per row
$wds = @(25.543,4.238,7.672,10.498,7.203,5.826,6.335,16.154,7.324,4.511,6.059,7.220,7.682,12.596,6.316,5.305,8.233,6.219,9.374,13.726,5.745,4.689,6.530,11.939,4.780,5.290,8.810,13.012,4.715,19.267,5.876,6.231,10.339,9.784,9.354,5.276,10.299,6.153,9.538,5.922)
$ww = @(0.324,0.712,-2.219,0.887,-0.490,-0.127,0.746,-1.719,0.490,-0.083,0.300,-1.107,1.685,-0.280,0.898,0.672,-1.523,-0.414,1.961,0.857,-0.871,2.329,-0.190,-0.293,0.855,0.872,-1.054,-1.417,-0.839,1.216,1.146,1.297,-0.915,-0.787,-0.124,-1.032,0.164,-1.457,1.486,-1.159,-1.598)
function Row8($arr, $start, $label) {
  $s = $label
  for ($k = 0; $k -lt 8; $k++) {
    $ix = $start + $k
    if ($ix -lt $arr.Count) { $s += ("  {0:N3}" -f $arr[$ix]) } else { $s += "  —" }
  }
  return $s
}
Add-Tbl @(
  @("Indeksai", "s_j reiksmes"),
  @("1-8", "25,543  4,238  7,672  10,498  7,203  5,826  6,335  16,154"),
  @("9-16", "7,324  4,511  6,059  7,220  7,682  12,596  6,316  5,305"),
  @("17-24", "8,233  6,219  9,374  13,726  5,745  4,689  6,530  11,939"),
  @("25-32", "4,780  5,290  8,810  13,012  4,715  19,267  5,876  6,231"),
  @("33-40", "10,339  9,784  9,354  5,276  10,299  6,153  9,538  5,922")
) "9 lentele. Visi RBF plociai s_j (models/rbfnet.mat, model.widths)."

Add-Tbl @(
  @("Indeksai", "w (w0, tada w_1..w_40)"),
  @("w0 ir 1-7", "0,324 | 0,712  -2,219  0,887  -0,490  -0,127  0,746  -1,719"),
  @("8-15", "0,490  -0,083  0,300  -1,107  1,685  -0,280  0,898  0,672"),
  @("16-23", "-1,523  -0,414  1,961  0,857  -0,871  2,329  -0,190  -0,293"),
  @("24-31", "0,855  0,872  -1,054  -1,417  -0,839  1,216  1,146  1,297"),
  @("32-40", "-0,915  -0,787  -0,124  -1,032  0,164  -1,457  1,486  -1,159  -1,598")
) "10 lentele. Visi RBF isejimo svoriai w (models/rbfnet.mat, model.w)."

Add-Tbl @(
  @("Formules dalis", "Kodas", "Failas, eil."),
  @("c_j = k-means(Z)", "[~, centers] = kmeans(Z, J, ...)", "train_rbfnet.m 21"),
  @("s_j = kappa * d2", "widths = kappa * d2;", "train_rbfnet.m 26-30"),
  @("phi_j = exp(-||z-c_j||^2/(2 s_j^2))", "Phi(:,j)=exp(-d2./(2*widths(j).^2));", "train_rbfnet.m 53-56"),
  @("w = (Phi1^T Phi1 + lambda I)^{-1} Phi1^T ytilde", "w = A \\ (Phi1' * ytilde);", "train_rbfnet.m 35-36"),
  @("a = [1, phi] w;  p = sigma(a)", "score = [ones(n,1), Phi]*model.w; p=1./(1+exp(-score));", "predict_proba.m 43-45")
) "11 lentele. RBF formules nariu atitikmenys kode."

H1 "4. Palyginimo protokolas (skaidymas, metrikos, testas neliečiamas)"
Body "Visi aštuoni užsaldyti vardai (majority, logreg, svm_rbf, mlp, rbfnet, svm_linear, svm_mean, svm_worst) mokomi tame paciame 456 bloke. HP – vidutinis OOF ROC-AUC, 25 stratifikuoti skaidiniai, scaler refit kiekviename folde; idxTest tik assert. Slenksčiai t_cost / t_se98 / t_youden – tik is OOF p (choose_threshold.m). freeze.txt rasomas pries evaluate_test. Testas n=113 skaiciuojamas viena karta; antras kvietimas – WDBC:Eval:AlreadyUnlocked. Metrikos visiems tos pacios (metrics.m, Kolokviumo (7)–(9)): Se, Sp, Wilson PI, FN/FP/TP/TN, AUC, Brier, EC=5 FN+1 FP. H1/H2 – hypotheses.csv (bootstrap 2000, DeLong). H3 – po testo, 10x5, neatstoja H1."

Add-Tbl @(
  @("Modelis", "OOF nugaletojas (hp, ne testas)"),
  @("logreg", "lambda = 0,1"),
  @("svm_rbf", "C = 0,3, KernelScale s = 8"),
  @("mlp", "H = 5, lambda = 0,3, seklos 1:5"),
  @("rbfnet", "J = 40, kappa = 2, lambda = 0,1"),
  @("svm_linear", "C = 0,01 (paprastesnis +/-0,002 nuo max AUC)")
) "12 lentele. Vidinės paieskos nugaletojai. Testas paieskoje nenaudotas."

H1 "5. Rezultatai: lentelė, grafikai ir kodėl H1 atmesta"
Body "Se/Sp 95 % PI – main_results.csv stulpeliai Se_lo/Se_hi, Sp_lo/Sp_hi. AUC ir Brier faile tik taskiniai (atskiru modeliu AUC/BS bootstrap PI TRUKSTA). Zemiau – veikimo taskas t_se98, kuriame preregistruota H1."

Add-Tbl @(
  @("Modelis", "t", "Se", "Se 95% PI", "Sp", "Sp 95% PI", "FN", "FP", "AUC", "BS"),
  @("majority", "0,50", "0,000", "[0,00; 0,08]", "1,000", "[0,95; 1,00]", "42", "0", "0,500", "0,372"),
  @("logreg", "0,21", "1,000", "[0,92; 1,00]", "0,563", "[0,45; 0,67]", "0", "31", "0,988", "0,072"),
  @("svm_rbf", "0,34", "0,952", "[0,84; 0,99]", "0,930", "[0,85; 0,97]", "2", "5", "0,986", "0,043"),
  @("mlp", "0,44", "0,929", "[0,81; 0,98]", "0,986", "[0,92; 1,00]", "3", "1", "0,993", "0,033"),
  @("rbfnet", "0,22", "0,952", "[0,84; 0,99]", "0,887", "[0,79; 0,94]", "2", "8", "0,976", "0,053")
) "13 lentele. Testas n=113, taskas t_se98 (main_results.csv, eilutes model x t_se98)."

Body "Skaitymas: LR pagavo visus 42 M, bet 31 FP. SVM-RBF – 2 FN ir 5 FP. MLP turi auksciausia AUC (0,993) ir Sp, bet Se teste 0,929 < 0,98. OOF t_se98 taisykle SVM teste Se>=0,98 neduoda (main_results.csv, svm_rbf t_se98, Se ir FN) – priestaravimas plano lukesciui, ne tylus taisymas."

Add-Pic (Join-Path $fig "roc.png") "1 pav. ROC kreives teste su insetu virsutiniam kairiam kampui (figures_clean/roc.png). AUC stulpelis – main_results.csv."
Add-Pic (Join-Path $fig "calibration.png") "2 pav. Kalibracija 2x2: dezuciu vidurkiai ir logit kreive is cal_a, cal_b (figures_clean/calibration.png; ECE – main_results.csv)."
Add-Pic (Join-Path $fig "h1_sprendimas.png") "3 pav. H1 konjunkcija: dSp priimta, dAUC atmesta (figures_clean/h1_sprendimas.png; hypotheses.csv)."

Add-Tbl @(
  @("Hipotese", "Taskas", "PI apacia", "PI virsus", "accepted"),
  @("H1_dSp", "0,3662", "0,2568", "0,4786", "1"),
  @("H1_AUC", "-0,0020", "-0,0074", "0,0034", "0"),
  @("H1", "0", "—", "—", "0"),
  @("H2_BS", "-0,0291", "-0,0496", "-0,0078", "1"),
  @("H2_slope", "1,097", "0,789", "2,753", "1"),
  @("H2", "1", "—", "—", "1"),
  @("H3_frac", "1", "— (NaN faile)", "—", "1"),
  @("H3", "1", "—", "—", "1")
) "14 lentele. Hipotezes (hypotheses.csv, visos eilutes). H3 PI faile nera."

Body "H1 ATMESTA (hypotheses.csv, H1, accepted=0). Tai validus rezultatas (planas 4.1). dSp dalis ivykyta (ci_lo=0,257>0 ir taskas 0,366>=0,03). Krenta AUC ne-prastesnumas: DeLong ci_lo=-0,0074 < -0,005 (H1_AUC). SVM pakeite klaidu balansa (maziau FP, du FN), bet nepakėlė reitingo virs LR (AUC 0,986 vs 0,988). H2 PRIIMTA – Brier SVM geresnis; nuolydzio PI kerta [0,8; 1,25], bet yra platus (n=113). H3 PRIIMTA (frac=1), neatstoja H1. Prototipas pagal egzamino taisykle po H1 atmetimo – logistine regresija (logreg t_se98: FN=0, FP=31)."

H1 "6. Klaidų pavyzdžiai"
Add-Pic (Join-Path $fig "confusion_svm_rbf.png") "4 pav. SVM-RBF painiava t_se98=0,34: TN=66, FP=5, FN=2, TP=40 (figures_clean/confusion_svm_rbf.png; tie patys skaiciai main_results.csv, svm_rbf t_se98)."

Body "error_profile.txt: FN=2, FP=5. Mokymo medianos M: concave_points_worst=0,183, area_worst=1333; B: 0,074 ir 548. Zemiau – visos error_cases.csv eilutes."

Add-Tbl @(
  @("Tipas", "abs_idx", "p", "|p-t|", "cp_worst", "area_worst", "pastaba"),
  @("FN", "41", "0,048", "0,292", "0,111", "788", "toli nuo t; pozymiai arciau B"),
  @("FN", "264", "0,214", "0,126", "0,086", "989", "toli nuo t"),
  @("FP", "69", "0,776", "0,436", "0,175", "325", "mazas plotas, auksti cp"),
  @("FP", "82", "0,508", "0,168", "0,171", "615", ""),
  @("FP", "153", "0,804", "0,464", "0,157", "381", "panašiai kaip 69"),
  @("FP", "291", "0,446", "0,106", "0,102", "767", ""),
  @("FP", "466", "0,385", "0,045", "0,136", "734", "vienintelis |p-t|<0,10")
) "15 lentele. SVM-RBF klaidos teste (error_cases.csv). t=0,34."

Body "Abu FN nera slenkscio artefaktas (dist_to_t>0,10): 'mazi, lygesni' piktybiniai zemiau M medianos. FP 69 ir 153 – priestaraujantys pozymiai (plotas kaip B, cp kaip M). margin_flag |p-t|<0,10 pagautu tik 466, ne FN 41 – siauresne apsauga, nei 6.5 skyrius tikejosi."

H1 "7. Abliacija ir atsparumo bandymai"
Add-Pic (Join-Path $fig "se_sp_tse98.png") "5 pav. Se ir Sp su 95 % Wilson juostomis, t_se98, penki pagrindiniai modeliai (figures_clean/se_sp_tse98.png; intervalai is main_results.csv)."
Add-Pic (Join-Path $fig "cost_curve.png") "6 pav. EC(t)=5 FN+1 FP teste: SVM-RBF vs LR, vertikalus t_se98 (figures_clean/cost_curve.png; slenksciu reiksmes main_results.csv)."

Add-Tbl @(
  @("id", "Kas keiciama", "Se / Sp / AUC", "Isvada"),
  @("A0", "dauguma t=0,5", "0 / 1 / 0,500; FN=42", "be pozymiu visos M praleidziamos (ablation.csv A0)"),
  @("A2 RBF", "SVM-RBF t_se98", "0,952 / 0,930 / 0,986; dSp PI kerta 0", "RBF Sp pries linear neirodytas"),
  @("A2 linear", "tiesinis SVM t_se98", "0,976 / 0,887 / 0,995", "AUC lubos: linear > RBF (ablation.csv A2)"),
  @("A5 mean10", "10 mean pozymiu", "0,976 / 0,718 / 0,975; FP=20", "mean vienu neuztenka Sp"),
  @("A5 worst10", "10 worst pozymiu", "1,000 / 0,873 / 0,996; FN=0", "diskriminacija jau 10 worst"),
  @("A5 all30", "visi 30 = M1", "0,952 / 0,930 / 0,986; FP=5", "30 pozymiu geresnis Sp, ne AUC"),
  @("A7 1:1..10:1", "kaina, tas pats t_cost=0,33", "FN=2 FP=5 visiems; EC=7,11,15,25", "kainos santykis slenksčio nepastume")
) "16 lentele. Abliacija tuo paciu uzsaldytu testu (ablation.csv)."

Body "Planas 1.4/A7 tikejosi, kad c_FN:c_FP pastumes t ir FN/FP. Fakte OOF t_cost sutapo, teste painiava identiska – keičiasi tik perskaiciuota EC (ablation.csv, A7_* stulpeliai t, FN, FP, EC_or_delta)."

H1 "8. Paleidimo instrukcija, priklausomybės, sėklos, viena komanda"
Body "Aplinka: MATLAB R2026a, Statistics and Machine Learning Toolbox, Deep Learning Toolbox (patternnet). Projekto saknis Kruties_Navikas. Duomenys: pirma karta get_wdbc parsiuncia wdbc.data is UCI i data/raw/ (jei failas jau yra ir netuscias – nesiuncia). Fiksuotos seklos (config.m): cfg.seed=42 (skaidymas, CV, k-means); MLP seklos 1:5. Viena komanda vamzdžiui: run_all  (Command Window, projekto saknyje). Ji paleidzia testus, mokyma jei truksta .mat, freeze, evaluate_test viena karta, predict_case pavyzdi, H3. Jei test_unlocked.flag jau yra, evaluate_test praleidziama. Grafikai pristatymui (langai lieka atidaryti): make_report_plots. Patikros: runtests('tests') – nutekejimas, skaidinys, metrikos, predict_case. Vieno atvejo prognoze: predict_case('data/examples/one_case.csv') po testo atrakinimo."

H1 "9. AI naudojimo žurnalas"
Add-Tbl @(
  @("Uzklausa / etapas", "Priimta", "Atmesta"),
  @("5 etapu MATLAB vamzdis pagal plana", "katalogai, run_all, freeze, lock", "HP/slenks vis is testo"),
  @("Scaler ir skaidinys", "mu tik is 456; 113/456 kaip cvpartition", "n=569 scaler; rankinis 114/455 kirpimas; nuliu eiluciu metimas"),
  @("HP taisykle", "max OOF AUC, tada +/-0,002 paprastesnis", "eilinis 'pirmas paprastas tinklelyje' (AI klaida #1)"),
  @("Formuliu numeriai", "Kolokviumo (1)–(9) komentaruose", "plano (6)–(24) numeriai (AI klaida #2)"),
  @("H1 interpretacija", "accepted=0 palikta; prototipas LR", "'SVM laimejo, nes dSp didelis'; H3 perraso H1"),
  @("App Designer .mlapp", "predict_case.m pakanka", "neprivaloma 8 lentele")
) "17 lentele. Svarbiausios uzklausos (reports/ai_usage.md)."

Body "Dvi konkrecios AI klaidos su patikra. (1) tune_cv pirma ėjo tinklu ir galejo palikti paprastesnę konfigūracija su zemesniu AUC nei maksimumas. Patikra: po viso tinklo palyginti aucMean; taisykle pakeista pries evaluate_test. (2) Komentaruose buvo plano (6)–(24), ne Kolokviumo (1)–(9). Patikra: gretutinai Kolokviumo dalis.pdf ir moduliu antrastes; perrasyta pries lock. Papildomas luzis: error_analysis dublia vota antraste area_worst – pataisyta kol test_unlocked.flag dar neegzistavo."

H1 "10. Pasiruošimas gyvam gynimui"
Body "Formule ir kodas: atversti mlp_backprop_manual.m 17–27 eil. (8 lentele) ir palyginti su train_mlp.m 22–37 (patternnet) bei predict_proba.m 65–72. Paaiskinti, kodėl tanh isvestine yra 1-h.^2 ir kodėl delta^(2)=p-y kryzminei entropijai su sigma. RBF: train_rbfnet.m 21–36 ir 53–56. Nematytas bandymas: destytojo 1x30 eilute – predict_case(x) po lock; neigiamos reiksmes ir NaN meta klaida; |p-t|<0,10 duoda margin_flag. Nedidelis pakeitimas be perrasymo: (a) metrika – metrics.m prideti PPV i lentele, tas pats testas; (b) modelis – config.m SVM C tinklelis arba mlp.H=[5 10]; (c) apdorojimas – cfg.prep.log_transform=true. Kiekvienas variantas lyginamas su 13 lentele, nes skaidinys uzsaldytas; evaluate_test antro karto neleis – naujas eksperimentas reikalautu naujo lock politikos aptarimo."

H1 "11. Išvados"
Body "Pateiktas veikiantis, atkuriamas WDBC klasifikatorius: grandine be nutekejimo, du baseline ir trys intelektualieji metodai, tas pats uzsaldytas testas. MLP ir RBF koeficientai suzymeti dydziu ir reikšme; isejimo ir BP formules isvestos ir susietos su tiksliomis MATLAB eilutėmis; kode yra antrastes ir struktura. H1 atmesta del AUC ne-prastesnumo, nors dSp didelis – validus rezultatas, prototipas LR. H2 ir H3 priimtos. RBF branduolys AUC nepakėlė virs tiesinio SVM; 5:1 kaina slenksčio nepastume. Ribos: n_test M=42, OOF Se>=0,98 neneša i testa, PPV neperkeliama i kita paplitima, isorines kohortos nera. Sistema tinka mokomajam sprendimo palaikymui, ne diagnostikai."

P "Literatura" 12 $true $false 0 6 10
P "1. Wolberg, W., Mangasarian, O., Street, N., Street, W. (1993). Breast Cancer Wisconsin (Diagnostic) [Dataset]. UCI. https://doi.org/10.24432/C5DW2B" 11 $false $false 0 4 0
P "2. Street, W. N., Wolberg, W. H., Mangasarian, O. L. (1993). Nuclear feature extraction for breast tumor diagnosis. Proc. SPIE, 1905, 861–870. https://doi.org/10.1117/12.148698" 11 $false $false 0 4 0
P "3. Mangasarian, O. L., Street, W. N., Wolberg, W. H. (1995). Breast cancer diagnosis and prognosis via linear programming. Operations Research, 43(4), 570–577. https://doi.org/10.1287/opre.43.4.570" 11 $false $false 0 4 0
P "5. Elkan, C. (2001). The foundations of cost-sensitive learning. IJCAI, 973–978." 11 $false $false 0 4 0
P "6. Cox, D. R. (1958). The regression analysis of binary sequences. JRSS B, 20(2), 215–242." 11 $false $false 0 4 0
P "9. Cortes, C., Vapnik, V. (1995). Support-vector networks. Machine Learning, 20, 273–297." 11 $false $false 0 4 0
P "13. Cybenko, G. (1989). Approximation by superpositions of a sigmoidal function. MCSS, 2, 303–314." 11 $false $false 0 4 0
P "14. Rumelhart, D. E., Hinton, G. E., Williams, R. J. (1986). Learning representations by back-propagating errors. Nature, 323, 533–536." 11 $false $false 0 4 0
P "15. Moody, J., Darken, C. J. (1989). Fast learning in networks of locally-tuned processing units. Neural Computation, 1(2), 281–294." 11 $false $false 0 4 0
P "16. Platt, J. (1999). Probabilistic outputs for support vector machines. In Advances in Large Margin Classifiers. MIT Press." 11 $false $false 0 4 0
P "21. DeLong, E. R., DeLong, D. M., Clarke-Pearson, D. L. (1988). Comparing the areas under two or more correlated ROC curves. Biometrics, 44(3), 837–845." 11 $false $false 0 4 0
P "22. Brier, G. W. (1950). Verification of forecasts expressed in terms of probability. Monthly Weather Review, 78(1), 1–3." 11 $false $false 0 4 0
P "Numeracija atitinka kolokviumo igyvendinimo plano literaturos sarasa; cia tik faktiškai cituoti šaltiniai." 11 $false $true 0 8 6

# Embed pictures (already Insert with LinkToFile=false SaveWithDocument=true)
foreach ($ish in @($doc.InlineShapes)) {
  try {
    if ($ish.LinkFormat) { $ish.LinkFormat.SavePictureWithDocument = $true; $ish.LinkFormat.BreakLink() }
  } catch {}
}

$saveDocx = [string]$docx
$savePdf  = [string]$pdf
$doc.SaveAs2($saveDocx)
Write-Host "DOCX $saveDocx"
try {
  $doc.ExportAsFixedFormat($savePdf, 17)
  Write-Host "PDF  $savePdf"
} catch {
  Write-Host "ExportAsFixedFormat failed, trying SaveAs PDF"
  $doc.SaveAs2($savePdf, 17)
  Write-Host "PDF  $savePdf"
}
$doc.Close($false)
$word.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
[GC]::Collect()
Write-Host "DONE"
Get-Item -LiteralPath $saveDocx, $savePdf | Format-Table Name, Length, LastWriteTime
