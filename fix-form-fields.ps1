$filePath = 'P:\ProjectLI\src\main\webapp\application-form.jsp'
$lines = [System.IO.File]::ReadAllLines($filePath)

Write-Host "Total lines: $($lines.Length)"

# New 7 fields to insert AFTER brand field closing </div> (index 325 = line 326)
$newFields = @(
'                            <div class="field">',
'                                <label for="standard_name_1">Piawaian / Standard</label>',
'                                <input id="standard_name_1" name="standard_name[]" type="text" placeholder="MS / BS / ISO / lain-lain" required />',
'                            </div>',
'                            <div class="field">',
'                                <label for="certification_license_1">Badan Persijilan & No. Lesen</label>',
'                                <input id="certification_license_1" name="certification_license[]" type="text" required />',
'                            </div>',
'                            <div class="field">',
'                                <label for="certification_valid_until_1">Sah Sehingga</label>',
'                                <input id="certification_valid_until_1" name="certification_valid_until[]" type="date" required />',
'                            </div>',
'                            <div class="field">',
'                                <label for="test_report_reference_1">Badan Persijilan & No. Laporan Pengujian</label>',
'                                <input id="test_report_reference_1" name="test_report_reference[]" type="text" required />',
'                            </div>',
'                            <div class="field">',
'                                <label for="test_report_date_1">Tarikh Laporan Pengujian</label>',
'                                <input id="test_report_date_1" name="test_report_date[]" type="date" required />',
'                            </div>',
'                            <div class="field">',
'                                <label for="warranty_years_1">Tempoh Jaminan Produk (Tahun)</label>',
'                                <input id="warranty_years_1" name="warranty_years[]" type="number" step="0.1" min="0" required />',
'                            </div>',
'                            <div class="field full">',
'                                <label for="product_description_1">Perihal Produk (Model / Siri / Deskripsi)</label>',
'                                <textarea id="product_description_1" name="product_description[]" required></textarea>',
'                            </div>'
)

# Build new lines array:
# - Keep lines[0..325] (lines 1-326, up to and including brand closing </div>)
# - Insert 7 new fields
# - Keep lines[326..332] (lines 327-333: close grid-3, product-item-actions, close product-item, close productArrayList, close product-array-wrap)
# - SKIP lines[333..362] (lines 334-363: standalone grid-3 block)
# - Keep lines[363..end]

$newContent = [System.Collections.Generic.List[string]]::new()

# Part 1: lines 0..325
for ($i = 0; $i -le 325; $i++) { $newContent.Add($lines[$i]) }

# Part 2: new fields
foreach ($f in $newFields) { $newContent.Add($f) }

# Part 3: lines 326..332 (keep closing divs)
for ($i = 326; $i -le 332; $i++) { $newContent.Add($lines[$i]) }

# Part 4: skip lines 333..362 (standalone grid-3)

# Part 5: lines 363..end
for ($i = 363; $i -lt $lines.Length; $i++) { $newContent.Add($lines[$i]) }

Write-Host "New total lines: $($newContent.Count)"

[System.IO.File]::WriteAllLines($filePath, $newContent, [System.Text.Encoding]::UTF8)
Write-Host "File written."

# Verify
$verify = [System.IO.File]::ReadAllText($filePath)
Write-Host "Has standard_name[]: $($verify.Contains('standard_name[]'))"
Write-Host "Has product_description[]: $($verify.Contains('product_description[]'))"
Write-Host "Has standalone standard_name non-array: $($verify.Contains('name=""standard_name""'))"
