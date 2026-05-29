$f = "src\main\webapp\application-form.jsp"
$c = [System.IO.File]::ReadAllText((Resolve-Path $f), [System.Text.Encoding]::UTF8)
$nl = "`r`n"

# --- Build old section ---
$startMarker = '<h2 class="section-title">Bahagian B: Maklumat Produk</h2>'
$endMarker   = '<label for="standard_name">Piawaian / Standard</label>'

$si = $c.IndexOf($startMarker)
$ei = $c.IndexOf($endMarker, $si)

if ($si -lt 0) { Write-Host "START MARKER NOT FOUND"; exit 1 }
if ($ei -lt 0) { Write-Host "END MARKER NOT FOUND"; exit 1 }

$oldSection = $c.Substring($si, $ei + $endMarker.Length - $si)
Write-Host "Old section length: $($oldSection.Length)"

# --- Build new section ---
$newSection = @"
<h2 class="section-title">Bahagian B: Maklumat Produk</h2>
            <div class="product-array-wrap">
                <div class="product-array-head">
                    <span class="hint">Pemohon boleh mohon lebih daripada satu produk.</span>
                    <button type="button" id="addProductBtn" class="btn btn-secondary btn-add-product" aria-label="Tambah produk baharu">
                        <img src="`${pageContext.request.contextPath}/icon/add-new.png" alt="Tambah">
                        Add New
                    </button>
                </div>
                <div id="productArrayList" class="product-array-list">
                    <div class="product-item" data-product-item>
                        <div class="product-item-title">Produk 1</div>
                        <div class="grid-3">
                            <div class="field">
                                <label for="product_category_1">Kategori Produk</label>
                                <select id="product_category_1" name="product_category[]" required>
                                    <option value="">Pilih kategori</option>
                                    <option value="Water Treatment Equipment">Water Treatment Equipment</option>
                                    <option value="Conveyance Of Water">Conveyance Of Water</option>
                                    <option value="Flow Control">Flow Control</option>
                                    <option value="Measuring Device">Measuring Device</option>
                                    <option value="Chemical For Water Treatment">Chemical For Water Treatment</option>
                                    <option value="Storage Of Water">Storage Of Water</option>
                                    <option value="Sanitary">Sanitary</option>
                                    <option value="Lining">Lining</option>
                                    <option value="Coating">Coating</option>
                                    <option value="Waterproofing">Waterproofing</option>
                                    <option value="Sealant">Sealant</option>
                                    <option value="Adhesive">Adhesive</option>
                                    <option value="Solvent Cement">Solvent Cement</option>
                                </select>
                            </div>
                            <div class="field">
                                <label for="product_name_1">Nama Produk</label>
                                <input id="product_name_1" name="product_name[]" type="text" required />
                            </div>
                            <div class="field">
                                <label for="brand_1">Jenama</label>
                                <input id="brand_1" name="brand[]" type="text" required />
                            </div>
                        </div>
                        <div class="product-item-actions">
                            <button type="button" class="btn btn-remove-product" data-remove-product hidden>Buang</button>
                        </div>
                    </div>
                </div>
            </div>
            <div class="grid-3">
                <div class="field">
                    <label for="standard_name">Piawaian / Standard</label>
"@

# Normalize newlines in newSection to CRLF
$newSection = $newSection -replace "`r?`n", $nl

Write-Host "New section length: $($newSection.Length)"

# --- Replace ---
$updated = $c.Replace($oldSection, $newSection)
if ($updated -eq $c) {
    Write-Host "HTML REPLACEMENT FAILED - no change"
    exit 1
}
Write-Host "HTML replacement: OK"

# --- Add JS before </script> ---
$jsOld  = "    })();`r`n</script>"
$jsNew  = @"
    })();

    // Product Array - Add New
    (function() {
        var list = document.getElementById('productArrayList');
        var btn  = document.getElementById('addProductBtn');
        if (!list || !btn) return;

        function sync() {
            var items = list.querySelectorAll('[data-product-item]');
            items.forEach(function(item, i) {
                var n = i + 1;
                var t = item.querySelector('.product-item-title');
                if (t) t.textContent = 'Produk ' + n;
                var sel = item.querySelector('select[name="product_category[]"]');
                if (sel) { sel.id = 'product_category_' + n; var l = item.querySelector('label[for^="product_category"]'); if (l) l.htmlFor = sel.id; }
                var pn  = item.querySelector('input[name="product_name[]"]');
                if (pn)  { pn.id  = 'product_name_' + n; var l = item.querySelector('label[for^="product_name"]');  if (l) l.htmlFor = pn.id; }
                var br  = item.querySelector('input[name="brand[]"]');
                if (br)  { br.id  = 'brand_' + n; var l = item.querySelector('label[for^="brand"]'); if (l) l.htmlFor = br.id; }
                var rb  = item.querySelector('[data-remove-product]');
                if (rb)  { if (items.length > 1) rb.removeAttribute('hidden'); else rb.setAttribute('hidden',''); }
            });
        }

        function bindRemove(rb, item) {
            rb.addEventListener('click', function() { if (item.parentNode) item.parentNode.removeChild(item); sync(); });
        }

        var firstRb = list.querySelector('[data-remove-product]');
        if (firstRb) bindRemove(firstRb, firstRb.closest('[data-product-item]'));

        btn.addEventListener('click', function() {
            var first = list.querySelector('[data-product-item]');
            if (!first) return;
            var clone = first.cloneNode(true);
            clone.querySelectorAll('select').forEach(function(s) { s.selectedIndex = 0; });
            clone.querySelectorAll('input[type="text"]').forEach(function(i) { i.value = ''; });
            var rb = clone.querySelector('[data-remove-product]');
            if (rb) { rb.removeAttribute('hidden'); bindRemove(rb, clone); }
            list.appendChild(clone);
            sync();
        });
    })();
</script>
"@

$jsNew = $jsNew -replace "`r?`n", $nl

if ($updated.Contains($jsOld)) {
    $updated = $updated.Replace($jsOld, $jsNew)
    Write-Host "JS replacement: OK"
} else {
    Write-Host "JS marker not found - trying alternate"
    # Try with just LF
    $jsOldLF = "    })();`n</script>"
    if ($updated.Contains($jsOldLF)) {
        $updated = $updated.Replace($jsOldLF, ($jsNew -replace "`r`n", "`n"))
        Write-Host "JS replacement (LF): OK"
    } else {
        Write-Host "JS NOT FOUND either"
    }
}

# --- Write back ---
[System.IO.File]::WriteAllText((Resolve-Path $f), $updated, [System.Text.Encoding]::UTF8)
Write-Host "File written. Lines: $(($updated -split "`r?`n").Count)"

# --- Verify ---
$verify = [System.IO.File]::ReadAllText((Resolve-Path $f))
if ($verify.Contains('addProductBtn')) { Write-Host "VERIFY: addProductBtn FOUND" } else { Write-Host "VERIFY: addProductBtn MISSING" }
if ($verify.Contains('product_category[]')) { Write-Host "VERIFY: product_category[] FOUND" } else { Write-Host "VERIFY: product_category[] MISSING" }
