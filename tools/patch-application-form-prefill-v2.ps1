Set-Location 'P:\ProjectLI'
$path = 'src\main\webapp\application-form.jsp'
$content = Get-Content -LiteralPath $path -Raw

if ($content -notmatch '<%@ page import="java.util.Set" %>') {
    $content = $content -replace [regex]::Escape("<%@ page import=\"java.util.Map\" %>"), "<%@ page import=\"java.util.Map\" %>`r`n<%@ page import=\"java.util.Set\" %>`r`n<%@ page import=\"java.util.LinkedHashSet\" %>"
}

if ($content -notmatch 'private String toJs\(') {
    $insertBlock = @'
<%!
    private String toJs(Object value) {
        if (value == null) {
            return "";
        }
        String s = String.valueOf(value);
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "")
                .replace("\n", "\\n")
                .replace("</", "<\\/");
    }

    private String appValue(Map<String, Object> app, String key) {
        if (app == null || key == null) {
            return "";
        }
        Object value = app.get(key);
        return value == null ? "" : String.valueOf(value);
    }
%>
<%
    Map<String, Object> editingApp = (Map<String, Object>) request.getAttribute("application");
    boolean editMode = Boolean.TRUE.equals(request.getAttribute("editMode"));
    String formAction = request.getAttribute("formAction") != null
            ? String.valueOf(request.getAttribute("formAction"))
            : (request.getContextPath() + "/applications/new");
    Set<String> existingDocumentKeys = (Set<String>) request.getAttribute("existingDocumentKeys");
    if (existingDocumentKeys == null) {
        existingDocumentKeys = new LinkedHashSet<>();
    }
    StringBuilder existingDocKeysCsv = new StringBuilder();
    for (String key : existingDocumentKeys) {
        if (existingDocKeysCsv.length() > 0) {
            existingDocKeysCsv.append('|');
        }
        existingDocKeysCsv.append(key);
    }

    String jsApplicationType = toJs(appValue(editingApp, "application_type"));
    String jsSupplierEmail = toJs(appValue(editingApp, "supplier_email"));
    String jsSupplierPhone = toJs(appValue(editingApp, "supplier_phone"));
    String jsSupplierName = toJs(appValue(editingApp, "supplier_name"));
    String jsSupplierAddress = toJs(appValue(editingApp, "supplier_address"));
    String jsManufacturerName = toJs(appValue(editingApp, "manufacturer_name"));
    String jsManufacturerAddress = toJs(appValue(editingApp, "manufacturer_address"));
    String jsManufacturerPhone = toJs(appValue(editingApp, "manufacturer_phone"));
    String jsPrincipalName = toJs(appValue(editingApp, "principal_name"));
    String jsPrincipalAddress = toJs(appValue(editingApp, "principal_address"));
    String jsPrincipalPhone = toJs(appValue(editingApp, "principal_phone"));
    String jsProductCategory = toJs(appValue(editingApp, "product_category"));
    String jsProductName = toJs(appValue(editingApp, "product_name"));
    String jsBrand = toJs(appValue(editingApp, "brand"));
    String jsStandardName = toJs(appValue(editingApp, "standard_name"));
    String jsCertificationLicense = toJs(appValue(editingApp, "certification_license"));
    String jsCertificationValidUntil = toJs(appValue(editingApp, "certification_valid_until"));
    String jsTestReportReference = toJs(appValue(editingApp, "test_report_reference"));
    String jsTestReportDate = toJs(appValue(editingApp, "test_report_date"));
    String jsWarrantyYears = toJs(appValue(editingApp, "warranty_years"));
    String jsProductDescription = toJs(appValue(editingApp, "product_description"));
    String jsSabahRepName = toJs(appValue(editingApp, "sabah_rep_name"));
    String jsSabahRepAddress = toJs(appValue(editingApp, "sabah_rep_address"));
    String jsSabahRepPhone = toJs(appValue(editingApp, "sabah_rep_phone"));
    String jsDeclarationName = toJs(appValue(editingApp, "declaration_name"));
    String jsDeclarationPosition = toJs(appValue(editingApp, "declaration_position"));
%>
'@
    $content = $content -replace [regex]::Escape('<%@ page import="java.util.LinkedHashSet" %>') + "`r?`n", "<%@ page import=\"java.util.LinkedHashSet\" %>`r`n$insertBlock"
}

if ($content -notmatch 'existingDocKeysCsv') {
    $content = $content -replace [regex]::Escape('<input type="hidden" name="_csrf" value="${csrf_token}">'), '<input type="hidden" name="_csrf" value="${csrf_token}">`r`n            <input type="hidden" id="existingDocKeysCsv" value="<%= toJs(existingDocKeysCsv.toString()) %>">`r`n            <% if (editMode) { %>`r`n            <div class="alert success">Mod kemaskini permohonan. Maklumat boleh dikemaskini dan dihantar semula.</div>`r`n            <% } %>'
}

if ($content -notmatch 'var existingDocKeys = new Set') {
    $content = $content -replace 'var mandatoryDocKeys = \[(?s).*?\];', "$0`r`n    var existingDocCsvField = document.getElementById('existingDocKeysCsv');`r`n    var existingDocKeys = new Set(`r`n        existingDocCsvField && existingDocCsvField.value`r`n            ? existingDocCsvField.value.split('|').filter(function(v) { return v && v.trim() !== ''; })`r`n            : []`r`n    );`r`n`r`n    var initialFormData = {`r`n        application_type: \"<%= jsApplicationType %>\",`r`n        supplier_email: \"<%= jsSupplierEmail %>\",`r`n        supplier_phone: \"<%= jsSupplierPhone %>\",`r`n        supplier_name: \"<%= jsSupplierName %>\",`r`n        supplier_address: \"<%= jsSupplierAddress %>\",`r`n        manufacturer_name: \"<%= jsManufacturerName %>\",`r`n        manufacturer_address: \"<%= jsManufacturerAddress %>\",`r`n        manufacturer_phone: \"<%= jsManufacturerPhone %>\",`r`n        principal_name: \"<%= jsPrincipalName %>\",`r`n        principal_address: \"<%= jsPrincipalAddress %>\",`r`n        principal_phone: \"<%= jsPrincipalPhone %>\",`r`n        product_category: \"<%= jsProductCategory %>\",`r`n        product_name: \"<%= jsProductName %>\",`r`n        brand: \"<%= jsBrand %>\",`r`n        standard_name: \"<%= jsStandardName %>\",`r`n        certification_license: \"<%= jsCertificationLicense %>\",`r`n        certification_valid_until: \"<%= jsCertificationValidUntil %>\",`r`n        test_report_reference: \"<%= jsTestReportReference %>\",`r`n        test_report_date: \"<%= jsTestReportDate %>\",`r`n        warranty_years: \"<%= jsWarrantyYears %>\",`r`n        product_description: \"<%= jsProductDescription %>\",`r`n        sabah_rep_name: \"<%= jsSabahRepName %>\",`r`n        sabah_rep_address: \"<%= jsSabahRepAddress %>\",`r`n        sabah_rep_phone: \"<%= jsSabahRepPhone %>\",`r`n        declaration_name: \"<%= jsDeclarationName %>\",`r`n        declaration_position: \"<%= jsDeclarationPosition %>\"`r`n    };`r`n`r`n    function setIfPresent(name, value) {`r`n        if (value == null || value === '') return;`r`n        var field = applicationForm ? applicationForm.querySelector('[name=\"' + name + '\"]') : null;`r`n        if (!field) return;`r`n        field.value = value;`r`n    }`r`n`r`n    function applyInitialFormData() {`r`n        if (!applicationForm) return;`r`n        setIfPresent('application_type', initialFormData.application_type);`r`n        setIfPresent('supplier_email', initialFormData.supplier_email);`r`n        setIfPresent('supplier_phone', initialFormData.supplier_phone);`r`n        setIfPresent('supplier_name', initialFormData.supplier_name);`r`n        setIfPresent('supplier_address', initialFormData.supplier_address);`r`n        setIfPresent('manufacturer_name', initialFormData.manufacturer_name);`r`n        setIfPresent('manufacturer_address', initialFormData.manufacturer_address);`r`n        setIfPresent('manufacturer_phone', initialFormData.manufacturer_phone);`r`n        setIfPresent('principal_name', initialFormData.principal_name);`r`n        setIfPresent('principal_address', initialFormData.principal_address);`r`n        setIfPresent('principal_phone', initialFormData.principal_phone);`r`n        setIfPresent('sabah_rep_name', initialFormData.sabah_rep_name);`r`n        setIfPresent('sabah_rep_address', initialFormData.sabah_rep_address);`r`n        setIfPresent('sabah_rep_phone', initialFormData.sabah_rep_phone);`r`n        setIfPresent('declaration_name', initialFormData.declaration_name);`r`n        setIfPresent('declaration_position', initialFormData.declaration_position);`r`n`r`n        var firstProduct = document.querySelector('[data-product-item]');`r`n        if (firstProduct) {`r`n            var setProduct = function(name, value) {`r`n                if (value == null || value === '') return;`r`n                var productField = firstProduct.querySelector('[name=\"' + name + '[]\"]');`r`n                if (productField) productField.value = value;`r`n            };`r`n            setProduct('product_category', initialFormData.product_category);`r`n            setProduct('product_name', initialFormData.product_name);`r`n            setProduct('brand', initialFormData.brand);`r`n            setProduct('standard_name', initialFormData.standard_name);`r`n            setProduct('certification_license', initialFormData.certification_license);`r`n            setProduct('certification_valid_until', initialFormData.certification_valid_until);`r`n            setProduct('test_report_reference', initialFormData.test_report_reference);`r`n            setProduct('test_report_date', initialFormData.test_report_date);`r`n            setProduct('warranty_years', initialFormData.warranty_years);`r`n            setProduct('product_description', initialFormData.product_description);`r`n        }`r`n    }`r`n`r`n    applyInitialFormData();"
}

$content = $content -replace [regex]::Escape('var fileInput = applicationForm.querySelector(''input[type="file"][data-doc-key="'' + docKey + ''"]'');'), "if (existingDocKeys.has(docKey)) {`r`n                    return false;`r`n                }`r`n                var fileInput = applicationForm.querySelector('input[type=\"file\"][data-doc-key=\"' + docKey + '\"]');"

Set-Content -LiteralPath $path -Value $content -Encoding UTF8

Select-String -Path $path -Pattern 'formAction','existingDocKeysCsv','toJs\(','appValue\(','initialFormData','existingDocKeys\.has','Kemaskini Permohonan' | Format-Table LineNumber,Line -AutoSize
