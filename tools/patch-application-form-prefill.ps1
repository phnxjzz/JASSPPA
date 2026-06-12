Set-Location 'P:\ProjectLI'
$path = 'src\main\webapp\application-form.jsp'
$content = Get-Content -LiteralPath $path -Raw

$oldTop = @'
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<!DOCTYPE html>
'@
$newTop = @'
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Set" %>
<%@ page import="java.util.LinkedHashSet" %>
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
<!DOCTYPE html>
'@
if (-not $content.Contains($oldTop)) { throw 'Top block not found' }
$content = $content.Replace($oldTop, $newTop)

$content = $content.Replace('action="${pageContext.request.contextPath}/applications/new"', 'action="<%= formAction %>"')

$oldCsrf = @'
            <input type="hidden" name="_csrf" value="${csrf_token}">
            <h2 class="section-title">Bahagian A: Maklumat Pembekal / Pembuat / Prinsipal</h2>
'@
$newCsrf = @'
            <input type="hidden" name="_csrf" value="${csrf_token}">
            <input type="hidden" id="existingDocKeysCsv" value="<%= toJs(existingDocKeysCsv.toString()) %>">
            <% if (editMode) { %>
            <div class="alert success">Mod kemaskini permohonan. Maklumat boleh dikemaskini dan dihantar semula.</div>
            <% } %>
            <h2 class="section-title">Bahagian A: Maklumat Pembekal / Pembuat / Prinsipal</h2>
'@
if (-not $content.Contains($oldCsrf)) { throw 'CSRF block not found' }
$content = $content.Replace($oldCsrf, $newCsrf)

$content = $content.Replace('<button class="btn btn-primary" type="submit">Hantar Permohonan Online</button>', '<button class="btn btn-primary" type="submit"><%= editMode ? "Kemaskini Permohonan" : "Hantar Permohonan Online" %></button>')

$oldJsHead = @'
    var applicationForm = document.getElementById(''applicationForm'');
    var unsuccessfulPopup = document.getElementById(''unsuccessfulPopup'');
    var popup = document.getElementById(''successPopup'');
    var mandatoryDocKeys = [
        ''official_application_letter'',
        ''principal_appointment_letter'',
        ''certification_license_file'',
        ''test_report_file'',
        ''brochure_catalogue'',
        ''price_list'',
        ''product_benefit_summary'',
        ''project_reference'',
        ''sop_document'',
        ''performance_monitoring_program''
    ];
'@
$newJsHead = @'
    var applicationForm = document.getElementById(''applicationForm'');
    var productArrayList = document.getElementById(''productArrayList'');
    var unsuccessfulPopup = document.getElementById(''unsuccessfulPopup'');
    var popup = document.getElementById(''successPopup'');
    var mandatoryDocKeys = [
        ''official_application_letter'',
        ''principal_appointment_letter'',
        ''certification_license_file'',
        ''test_report_file'',
        ''brochure_catalogue'',
        ''price_list'',
        ''product_benefit_summary'',
        ''project_reference'',
        ''sop_document'',
        ''performance_monitoring_program''
    ];
    var existingDocCsvField = document.getElementById(''existingDocKeysCsv'');
    var existingDocKeys = new Set(
        existingDocCsvField && existingDocCsvField.value
            ? existingDocCsvField.value.split(''|'').filter(function(v) { return v && v.trim() !== ''''; })
            : []
    );

    var initialFormData = {
        application_type: "<%= jsApplicationType %>",
        supplier_email: "<%= jsSupplierEmail %>",
        supplier_phone: "<%= jsSupplierPhone %>",
        supplier_name: "<%= jsSupplierName %>",
        supplier_address: "<%= jsSupplierAddress %>",
        manufacturer_name: "<%= jsManufacturerName %>",
        manufacturer_address: "<%= jsManufacturerAddress %>",
        manufacturer_phone: "<%= jsManufacturerPhone %>",
        principal_name: "<%= jsPrincipalName %>",
        principal_address: "<%= jsPrincipalAddress %>",
        principal_phone: "<%= jsPrincipalPhone %>",
        product_category: "<%= jsProductCategory %>",
        product_name: "<%= jsProductName %>",
        brand: "<%= jsBrand %>",
        standard_name: "<%= jsStandardName %>",
        certification_license: "<%= jsCertificationLicense %>",
        certification_valid_until: "<%= jsCertificationValidUntil %>",
        test_report_reference: "<%= jsTestReportReference %>",
        test_report_date: "<%= jsTestReportDate %>",
        warranty_years: "<%= jsWarrantyYears %>",
        product_description: "<%= jsProductDescription %>",
        sabah_rep_name: "<%= jsSabahRepName %>",
        sabah_rep_address: "<%= jsSabahRepAddress %>",
        sabah_rep_phone: "<%= jsSabahRepPhone %>",
        declaration_name: "<%= jsDeclarationName %>",
        declaration_position: "<%= jsDeclarationPosition %>"
    };

    function setIfPresent(name, value) {
        if (value == null || value === '''') return;
        var field = applicationForm ? applicationForm.querySelector(''[name="'' + name + ''"]'') : null;
        if (!field) return;
        field.value = value;
    }

    function applyInitialFormData() {
        if (!applicationForm) return;
        setIfPresent(''application_type'', initialFormData.application_type);
        setIfPresent(''supplier_email'', initialFormData.supplier_email);
        setIfPresent(''supplier_phone'', initialFormData.supplier_phone);
        setIfPresent(''supplier_name'', initialFormData.supplier_name);
        setIfPresent(''supplier_address'', initialFormData.supplier_address);
        setIfPresent(''manufacturer_name'', initialFormData.manufacturer_name);
        setIfPresent(''manufacturer_address'', initialFormData.manufacturer_address);
        setIfPresent(''manufacturer_phone'', initialFormData.manufacturer_phone);
        setIfPresent(''principal_name'', initialFormData.principal_name);
        setIfPresent(''principal_address'', initialFormData.principal_address);
        setIfPresent(''principal_phone'', initialFormData.principal_phone);
        setIfPresent(''sabah_rep_name'', initialFormData.sabah_rep_name);
        setIfPresent(''sabah_rep_address'', initialFormData.sabah_rep_address);
        setIfPresent(''sabah_rep_phone'', initialFormData.sabah_rep_phone);
        setIfPresent(''declaration_name'', initialFormData.declaration_name);
        setIfPresent(''declaration_position'', initialFormData.declaration_position);

        if (productArrayList) {
            var firstProduct = productArrayList.querySelector(''[data-product-item]'');
            if (firstProduct) {
                var setProduct = function(name, value) {
                    if (value == null || value === '''') return;
                    var productField = firstProduct.querySelector(''[name="'' + name + ''[]"]'');
                    if (productField) productField.value = value;
                };
                setProduct(''product_category'', initialFormData.product_category);
                setProduct(''product_name'', initialFormData.product_name);
                setProduct(''brand'', initialFormData.brand);
                setProduct(''standard_name'', initialFormData.standard_name);
                setProduct(''certification_license'', initialFormData.certification_license);
                setProduct(''certification_valid_until'', initialFormData.certification_valid_until);
                setProduct(''test_report_reference'', initialFormData.test_report_reference);
                setProduct(''test_report_date'', initialFormData.test_report_date);
                setProduct(''warranty_years'', initialFormData.warranty_years);
                setProduct(''product_description'', initialFormData.product_description);
            }
        }
    }

    applyInitialFormData();
'@
if (-not $content.Contains($oldJsHead)) { throw 'JS head block not found' }
$content = $content.Replace($oldJsHead, $newJsHead)

$oldMissingDocs = @'
            var hasMissingRequiredDoc = keysToCheck.some(function(docKey) {
                var fileInput = applicationForm.querySelector(''input[type="file"][data-doc-key="'' + docKey + ''"]'');
                return !fileInput || !fileInput.files || fileInput.files.length === 0;
            });
'@
$newMissingDocs = @'
            var hasMissingRequiredDoc = keysToCheck.some(function(docKey) {
                if (existingDocKeys.has(docKey)) {
                    return false;
                }
                var fileInput = applicationForm.querySelector(''input[type="file"][data-doc-key="'' + docKey + ''"]'');
                return !fileInput || !fileInput.files || fileInput.files.length === 0;
            });
'@
if (-not $content.Contains($oldMissingDocs)) { throw 'Missing docs block not found' }
$content = $content.Replace($oldMissingDocs, $newMissingDocs)

Set-Content -LiteralPath $path -Value $content -Encoding UTF8
Write-Host 'PATCHED'
Select-String -Path $path -Pattern 'appValue\(','editMode','existingDocKeysCsv','Kemaskini Permohonan','initialFormData','existingDocKeys\.has' | Select-Object -First 20 | Format-Table LineNumber,Line -AutoSize
