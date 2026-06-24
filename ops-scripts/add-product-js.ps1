<<<<<<< HEAD
$f = "src\main\webapp\application-form.jsp"
$c = [System.IO.File]::ReadAllText((Resolve-Path $f), [System.Text.Encoding]::UTF8)
$nl = if ($c.Contains("`r`n")) { "`r`n" } else { "`n" }

$jsOld = "})();${nl}</script>"

$jsNew = @"
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
                if (sel) { sel.id = 'product_category_' + n; var lb = item.querySelector('label[for^="product_category"]'); if (lb) lb.htmlFor = sel.id; }
                var pn  = item.querySelector('input[name="product_name[]"]');
                if (pn)  { pn.id  = 'product_name_' + n; var lb = item.querySelector('label[for^="product_name"]');  if (lb) lb.htmlFor = pn.id; }
                var br  = item.querySelector('input[name="brand[]"]');
                if (br)  { br.id  = 'brand_' + n; var lb = item.querySelector('label[for^="brand"]'); if (lb) lb.htmlFor = br.id; }
                var rb  = item.querySelector('[data-remove-product]');
                if (rb)  { if (items.length > 1) rb.removeAttribute('hidden'); else rb.setAttribute('hidden',''); }
            });
        }

        function bindRemove(rb, item) {
            rb.addEventListener('click', function() {
                if (item.parentNode) item.parentNode.removeChild(item);
                sync();
            });
        }

        var firstRb = list.querySelector('[data-remove-product]');
        if (firstRb) bindRemove(firstRb, firstRb.closest('[data-product-item]'));

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
    })();
</script>
"@

$jsNew = $jsNew -replace "`r?`n", $nl

if ($c.Contains($jsOld)) {
    $updated = $c.Replace($jsOld, $jsNew)
    [System.IO.File]::WriteAllText((Resolve-Path $f), $updated, [System.Text.Encoding]::UTF8)
    Write-Host "JS added. Total lines: $(($updated -split "`r?`n").Count)"
    $v = [System.IO.File]::ReadAllText((Resolve-Path $f))
    Write-Host "VERIFY: $(if ($v.Contains('btn.addEventListener')) { 'JS FOUND' } else { 'JS MISSING' })"
} else {
    Write-Host "JS OLD MARKER NOT FOUND"
    # Show what's near </script>
    $i = $c.IndexOf('</script>')
    Write-Host "Near </script>: [$($c.Substring([Math]::Max(0,$i-80), 90))]"
}
=======
$f = "src\main\webapp\application-form.jsp"
$c = [System.IO.File]::ReadAllText((Resolve-Path $f), [System.Text.Encoding]::UTF8)
$nl = if ($c.Contains("`r`n")) { "`r`n" } else { "`n" }

$jsOld = "})();${nl}</script>"

$jsNew = @"
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
                if (sel) { sel.id = 'product_category_' + n; var lb = item.querySelector('label[for^="product_category"]'); if (lb) lb.htmlFor = sel.id; }
                var pn  = item.querySelector('input[name="product_name[]"]');
                if (pn)  { pn.id  = 'product_name_' + n; var lb = item.querySelector('label[for^="product_name"]');  if (lb) lb.htmlFor = pn.id; }
                var br  = item.querySelector('input[name="brand[]"]');
                if (br)  { br.id  = 'brand_' + n; var lb = item.querySelector('label[for^="brand"]'); if (lb) lb.htmlFor = br.id; }
                var rb  = item.querySelector('[data-remove-product]');
                if (rb)  { if (items.length > 1) rb.removeAttribute('hidden'); else rb.setAttribute('hidden',''); }
            });
        }

        function bindRemove(rb, item) {
            rb.addEventListener('click', function() {
                if (item.parentNode) item.parentNode.removeChild(item);
                sync();
            });
        }

        var firstRb = list.querySelector('[data-remove-product]');
        if (firstRb) bindRemove(firstRb, firstRb.closest('[data-product-item]'));

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
    })();
</script>
"@

$jsNew = $jsNew -replace "`r?`n", $nl

if ($c.Contains($jsOld)) {
    $updated = $c.Replace($jsOld, $jsNew)
    [System.IO.File]::WriteAllText((Resolve-Path $f), $updated, [System.Text.Encoding]::UTF8)
    Write-Host "JS added. Total lines: $(($updated -split "`r?`n").Count)"
    $v = [System.IO.File]::ReadAllText((Resolve-Path $f))
    Write-Host "VERIFY: $(if ($v.Contains('btn.addEventListener')) { 'JS FOUND' } else { 'JS MISSING' })"
} else {
    Write-Host "JS OLD MARKER NOT FOUND"
    # Show what's near </script>
    $i = $c.IndexOf('</script>')
    Write-Host "Near </script>: [$($c.Substring([Math]::Max(0,$i-80), 90))]"
}
>>>>>>> origin/SPPPA
