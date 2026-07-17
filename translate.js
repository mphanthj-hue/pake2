(function() {
    // 1. Nhúng thư viện cấu hình Google Translate ẩn thanh công cụ gốc
    var googleTranslateElement = document.createElement('div');
    googleTranslateElement.id = 'google_translate_element';
    googleTranslateElement.style.display = 'none'; // Ẩn hoàn toàn giao diện Google tránh vướng mắt
    document.body.appendChild(googleTranslateElement);

    window.googleTranslateElementInit = function() {
        new google.translate.TranslateElement({
            pageLanguage: 'auto',
            includedLanguages: 'vi',
            layout: google.translate.TranslateElement.InlineLayout.SIMPLE,
            autoDisplay: true
        }, 'google_translate_element');
        
        // Buộc Google Translate tự động kích hoạt dịch sang Tiếng Việt
        setTimeout(function() {
            var select = document.querySelector('select.goog-te-combo');
            if (select) {
                select.value = 'vi';
                select.dispatchEvent(new Event('change'));
            }
        }, 1000);
    };

    var script = document.createElement('script');
    script.src = '//://google.com';
    document.head.appendChild(script);

    // 2. Chống dịch các thẻ codebox, khối lệnh dev và các thẻ kỹ thuật
    var style = document.createElement('style');
    style.innerHTML = `
        code, pre, .codebox, [class*="code"], [class*="dev"], pre *, code * {
            notranslate: yes !important;
        }
        .goog-te-banner-frame { display: none !important; } /* Ẩn thanh thông báo của Google ở đỉnh app */
        body { top: 0px !important; }
    `;
    document.head.appendChild(style);

    // Gắn thuộc tính class="notranslate" vào tất cả các vùng chứa mã nguồn
    function protectCodeBlocks() {
        var ignoredElements = document.querySelectorAll('pre, code, .codebox, [class*="code"], [class*="dev"]');
        ignoredElements.forEach(function(el) {
            el.classList.add('notranslate');
            el.setAttribute('translate', 'no');
        });
    }

    // 3. Tối ưu hóa hiệu năng: Cuộn đến đâu dịch đến đó (Chỉ dịch các thành phần DOM mới xuất hiện)
    protectCodeBlocks();
    var observer = new MutationObserver(function(mutations) {
        protectCodeBlocks(); // Bảo vệ các đoạn codebox mới được render khi cuộn trang
    });

    observer.observe(document.body, {
        childList: true,
        subtree: true
    });
})();
