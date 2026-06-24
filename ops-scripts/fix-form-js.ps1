<<<<<<< HEAD
$filePath = 'P:\ProjectLI\src\main\webapp\application-form.jsp'
$content = [System.IO.File]::ReadAllText($filePath)

$oldSync = @'
        function sync() {
            var items = list.querySelectorAll('[data-product-item]');
            items.forEach(function(item, i) {
                var n = i + 1;
                var t = item.querySelector('.product-item-title');
                if (t) t.textContent = 'Produk ' + n;
                var sel = item.querySelector('select[name="product_category[]"]');
                if (sel) { sel.id = 'product_category_' + n; var lb = item.querySelector('label[for^="product_category"]'); if (lb) lb.htmlFor = sel.id; }
                var pn  = item.querySelector('input[name="product_name[]"]');
                if (pn)  { pn.id  = 'product_name_' + n; var lb = item.querySelector('label[for^="product_name"]');  if (lb) lb.htmlFor = pn.id; }
                var br  = item.querySelector('input[name="brand[]"]');
                if (br)  { br.id  = 'brand_' + n; var lb = item.querySelector('label[for^="brand"]'); if (lb) lb.htmlFor = br.id; }
                var rb  = item.querySelector('[data-remove-product]');
                if (rb)  { if (items.length > 1) rb.removeAttribute('hidden'); else rb.setAttribute('hidden',''); }
            });
        }
'@

$newSync = @'
        var fieldConfigs = [
            { name: 'product_category[]', id: 'product_category_', tag: 'select' },
            { name: 'product_name[]', id: 'product_name_' },
            { name: 'brand[]', id: 'brand_' },
            { name: 'standard_name[]', id: 'standard_name_' },
            { name: 'certification_license[]', id: 'certification_license_' },
            { name: 'certification_valid_until[]', id: 'certification_valid_until_' },
            { name: 'test_report_reference[]', id: 'test_report_reference_' },
            { name: 'test_report_date[]', id: 'test_report_date_' },
            { name: 'warranty_years[]', id: 'warranty_years_' },
            { name: 'product_description[]', id: 'product_description_' }
        ];
        function sync() {
            var items = list.querySelectorAll('[data-product-item]');
            items.forEach(function(item, i) {
                var n = i + 1;
                var t = item.querySelector('.product-item-title');
                if (t) t.textContent = 'Produk ' + n;
                fieldConfigs.forEach(function(fc) {
                    var tag = fc.tag || 'input';
                    var el = item.querySelector(tag + '[name="' + fc.name + '"]') || item.querySelector('textarea[name="' + fc.name + '"]');
                    if (el) { el.id = fc.id + n; var lb = item.querySelector('label[for^="' + fc.id + '"]'); if (lb) lb.htmlFor = el.id; }
                });
                var rb = item.querySelector('[data-remove-product]');
                if (rb) { if (items.length > 1) rb.removeAttribute('hidden'); else rb.setAttribute('hidden',''); }
            });
        }
'@

$oldBtn = @'
        btn.addEventListener('click', function() {
            var first = list.querySelector('[data-product-item]');
            if (!first) return;
            var clone = first.cloneNode(true);
            clone.querySelectorAll('select').forEach(function(s) { s.selectedIndex = 0; });
            clone.querySelectorAll('input[type="text"]').forEach(function(inp) { inp.value = ''; });
            var rb = clone.querySelector('[data-remove-product]');
            if (rb) { rb.removeAttribute('hidden'); bindRemove(rb, clone); }
            list.appendChild(clone);
            sync();
        });
'@

$newBtn = @'
        btn.addEventListener('click', function() {
            var first = list.querySelector('[data-product-item]');
            if (!first) return;
            var clone = first.cloneNode(true);
            clone.querySelectorAll('select').forEach(function(s) { s.selectedIndex = 0; });
            clone.querySelectorAll('input[type="text"],input[type="date"],input[type="number"]').forEach(function(inp) { inp.value = ''; });
            clone.querySelectorAll('textarea').forEach(function(ta) { ta.value = ''; });
            var rb = clone.querySelector('[data-remove-product]');
            if (rb) { rb.removeAttribute('hidden'); bindRemove(rb, clone); }
            list.appendChild(clone);
            sync();
        });
'@

Write-Host "Old sync found: $($content.Contains($oldSync.TrimEnd()))"
Write-Host "Old btn found: $($content.Contains($oldBtn.TrimEnd()))"

$content = $content.Replace($oldSync.TrimEnd(), $newSync.TrimEnd())
$content = $content.Replace($oldBtn.TrimEnd(), $newBtn.TrimEnd())

[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
Write-Host "File written."
$verify = [System.IO.File]::ReadAllText($filePath)
Write-Host "Has fieldConfigs: $($verify.Contains('fieldConfigs'))"
Write-Host "Has textarea clear: $($verify.Contains('querySelectorAll(''textarea'')'))"
=======
$filePath = 'P:\ProjectLI\src\main\webapp\application-form.jsp'
$content = [System.IO.File]::ReadAllText($filePath)

$oldSync = @'
        function sync() {
            var items = list.querySelectorAll('[data-product-item]');
            items.forEach(function(item, i) {
                var n = i + 1;
                var t = item.querySelector('.product-item-title');
                if (t) t.textContent = 'Produk ' + n;
                var sel = item.querySelector('select[name="product_category[]"]');
                if (sel) { sel.id = 'product_category_' + n; var lb = item.querySelector('label[for^="product_category"]'); if (lb) lb.htmlFor = sel.id; }
                var pn  = item.querySelector('input[name="product_name[]"]');
                if (pn)  { pn.id  = 'product_name_' + n; var lb = item.querySelector('label[for^="product_name"]');  if (lb) lb.htmlFor = pn.id; }
                var br  = item.querySelector('input[name="brand[]"]');
                if (br)  { br.id  = 'brand_' + n; var lb = item.querySelector('label[for^="brand"]'); if (lb) lb.htmlFor = br.id; }
                var rb  = item.querySelector('[data-remove-product]');
                if (rb)  { if (items.length > 1) rb.removeAttribute('hidden'); else rb.setAttribute('hidden',''); }
            });
        }
'@

$newSync = @'
        var fieldConfigs = [
            { name: 'product_category[]', id: 'product_category_', tag: 'select' },
            { name: 'product_name[]', id: 'product_name_' },
            { name: 'brand[]', id: 'brand_' },
            { name: 'standard_name[]', id: 'standard_name_' },
            { name: 'certification_license[]', id: 'certification_license_' },
            { name: 'certification_valid_until[]', id: 'certification_valid_until_' },
            { name: 'test_report_reference[]', id: 'test_report_reference_' },
            { name: 'test_report_date[]', id: 'test_report_date_' },
            { name: 'warranty_years[]', id: 'warranty_years_' },
            { name: 'product_description[]', id: 'product_description_' }
        ];
        function sync() {
            var items = list.querySelectorAll('[data-product-item]');
            items.forEach(function(item, i) {
                var n = i + 1;
                var t = item.querySelector('.product-item-title');
                if (t) t.textContent = 'Produk ' + n;
                fieldConfigs.forEach(function(fc) {
                    var tag = fc.tag || 'input';
                    var el = item.querySelector(tag + '[name="' + fc.name + '"]') || item.querySelector('textarea[name="' + fc.name + '"]');
                    if (el) { el.id = fc.id + n; var lb = item.querySelector('label[for^="' + fc.id + '"]'); if (lb) lb.htmlFor = el.id; }
                });
                var rb = item.querySelector('[data-remove-product]');
                if (rb) { if (items.length > 1) rb.removeAttribute('hidden'); else rb.setAttribute('hidden',''); }
            });
        }
'@

$oldBtn = @'
        btn.addEventListener('click', function() {
            var first = list.querySelector('[data-product-item]');
            if (!first) return;
            var clone = first.cloneNode(true);
            clone.querySelectorAll('select').forEach(function(s) { s.selectedIndex = 0; });
            clone.querySelectorAll('input[type="text"]').forEach(function(inp) { inp.value = ''; });
            var rb = clone.querySelector('[data-remove-product]');
            if (rb) { rb.removeAttribute('hidden'); bindRemove(rb, clone); }
            list.appendChild(clone);
            sync();
        });
'@

$newBtn = @'
        btn.addEventListener('click', function() {
            var first = list.querySelector('[data-product-item]');
            if (!first) return;
            var clone = first.cloneNode(true);
            clone.querySelectorAll('select').forEach(function(s) { s.selectedIndex = 0; });
            clone.querySelectorAll('input[type="text"],input[type="date"],input[type="number"]').forEach(function(inp) { inp.value = ''; });
            clone.querySelectorAll('textarea').forEach(function(ta) { ta.value = ''; });
            var rb = clone.querySelector('[data-remove-product]');
            if (rb) { rb.removeAttribute('hidden'); bindRemove(rb, clone); }
            list.appendChild(clone);
            sync();
        });
'@

Write-Host "Old sync found: $($content.Contains($oldSync.TrimEnd()))"
Write-Host "Old btn found: $($content.Contains($oldBtn.TrimEnd()))"

$content = $content.Replace($oldSync.TrimEnd(), $newSync.TrimEnd())
$content = $content.Replace($oldBtn.TrimEnd(), $newBtn.TrimEnd())

[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
Write-Host "File written."
$verify = [System.IO.File]::ReadAllText($filePath)
Write-Host "Has fieldConfigs: $($verify.Contains('fieldConfigs'))"
Write-Host "Has textarea clear: $($verify.Contains('querySelectorAll(''textarea'')'))"
>>>>>>> origin/SPPPA
