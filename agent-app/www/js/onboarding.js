/**
 * Onboarding checklist for required Android permissions.
 */
(function () {
    const listEl = document.getElementById('onboardingList');
    const refreshBtn = document.getElementById('onboardingRefreshBtn');
    const sectionEl = document.getElementById('onboardingSection');

    if (!listEl || !refreshBtn || !sectionEl) {
        return;
    }

    const ITEMS = [
        {
            key: 'deviceAdmin',
            title: 'Device Admin',
            note: 'จำเป็นสำหรับสั่งล็อกหน้าจอและตั้งนโยบายบนอุปกรณ์',
            settings: 'device_admin',
            required: true
        },
        {
            key: 'deviceOwner',
            title: 'Device Owner (แนะนำ)',
            note: 'ต้อง factory reset ก่อน หากต้องการ kiosk / ปิดสกรีนช็อต / รีบูต',
            settings: null,
            required: false
        },
        {
            key: 'usageAccess',
            title: 'Usage Access Permission',
            note: 'ใช้ตรวจว่าแอปไหนกำลังเปิดอยู่และเก็บ usage stats',
            settings: 'usage_access',
            required: true
        },
        {
            key: 'notificationAccess',
            title: 'Notification Access',
            note: 'ใช้อ่านข้อความแจ้งเตือนและเคลียร์แจ้งเตือนจากแดชบอร์ด',
            settings: 'notification_access',
            required: true
        },
        {
            key: 'installPackages',
            title: 'Install Unknown Apps',
            note: 'อนุญาตให้ติดตั้ง APK ที่สั่งจากศูนย์ควบคุม (มี pop-up ยืนยัน)',
            settings: 'install_packages',
            required: true
        },
        {
            key: 'mediaProjection',
            title: 'Media Projection Consent',
            note: 'ต้องให้สิทธิ์จับหน้าจอด้วยตัวเองเมื่อมี pop-up (ตรวจสถานะอัตโนมัติไม่ได้)',
            settings: 'media_projection',
            manual: true,
            required: false
        }
    ];

    const createItemEl = (item) => {
        const wrapper = document.createElement('div');
        wrapper.className = 'onboarding-item loading';
        wrapper.dataset.key = item.key;

        const statusDot = document.createElement('span');
        statusDot.className = 'onboarding-status dot';
        wrapper.appendChild(statusDot);

        const details = document.createElement('div');
        details.className = 'onboarding-details';
        const title = document.createElement('span');
        title.className = 'onboarding-title';
        title.textContent = item.title;
        details.appendChild(title);
        const note = document.createElement('span');
        note.className = 'onboarding-note';
        note.textContent = item.note;
        details.appendChild(note);
        wrapper.appendChild(details);

        if (item.settings) {
            const actionBtn = document.createElement('button');
            actionBtn.className = 'btn btn-secondary';
            actionBtn.textContent = 'เปิด Settings';
            actionBtn.addEventListener('click', () => openSettings(item.settings));
            wrapper.appendChild(actionBtn);
        }

        return wrapper;
    };

    const renderInitial = () => {
        listEl.innerHTML = '';
        ITEMS.forEach((item) => {
            listEl.appendChild(createItemEl(item));
        });
    };

    const setStatus = (key, status) => {
        const el = listEl.querySelector(`[data-key="${key}"]`);
        if (!el) {
            return;
        }
        el.classList.remove('loading', 'completed', 'missing');
        if (status === 'completed') {
            el.classList.add('completed');
        } else if (status === 'missing') {
            el.classList.add('missing');
        } else {
            el.classList.add('loading');
        }
    };

    const fetchStatuses = async () => {
        renderInitial();
        try {
            const statuses = await (window.nativeControls ? window.nativeControls.getPermissionStatuses() : Promise.reject(new Error('nativeControls not ready')));
            ITEMS.forEach((item) => {
                if (item.manual) {
                    setStatus(item.key, 'loading');
                    return;
                }
                const value = Boolean(statuses[item.key]);
                setStatus(item.key, value ? 'completed' : (item.required ? 'missing' : 'loading'));
            });

            const allRequiredComplete = ITEMS.filter(i => i.required).every(i => Boolean(statuses[i.key]));
            sectionEl.dataset.allComplete = allRequiredComplete ? 'true' : 'false';
        } catch (error) {
            console.error('[Onboarding] Failed to fetch permission statuses:', error);
        }
    };

    const openSettings = async (target) => {
        if (!window.nativeControls) {
            return;
        }
        try {
            await window.nativeControls.openSettings(target);
        } catch (error) {
            console.error('[Onboarding] Failed to open settings:', error);
        }
    };

    refreshBtn.addEventListener('click', () => {
        fetchStatuses();
    });

    document.addEventListener('deviceready', () => {
        fetchStatuses();
    });

    // Render placeholder before statuses arrive
    renderInitial();
})();
