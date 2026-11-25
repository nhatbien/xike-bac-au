/* Ìe Bắc Âu — giao diện (trang đóng gói trong APK). Dữ liệu + máy chạy buổi thở nằm phía Java, gọi qua cầu window.App.
   Các màn: chinh · buoi (buổi thở rảnh tay) · xong / chitiet · ninvui · caidat · thongke · ds · nhatky. */
'use strict';

const XK = (() => {
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const e = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const xuong = s => e(s).replace(/\n/g, '<br>');

  function goi(ten, ...a) {
    try {
      return window.App && typeof window.App[ten] === 'function' ? window.App[ten](...a) : null;
    } catch (x) {
      console.error(ten, x);
      return null;
    }
  }
  function json(ten, ...a) {
    const s = goi(ten, ...a);
    if (!s) return {};
    try { return JSON.parse(s); } catch (x) { return {}; }
  }

  // ---------------------------------------------------------------- biểu tượng (SVG tự vẽ, không dùng emoji)
  const IC = {
    tuyet: '<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round">' +
      [0, 60, 120, 180, 240, 300].map(r => `<g transform="rotate(${r} 12 12)"><path d="M12 12V2.6M12 5.2 9.8 3.4M12 5.2l2.2-1.8M12 8.4l-1.8-1.5M12 8.4l1.8-1.5"/></g>`).join('') + '</svg>',
    dongHo: '<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="13" r="8"/><path d="M12 13V9M9.5 2.5h5M12 2.5V5M18.5 6.5l1.5-1.5"/></svg>',
    banhRang: '<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2.2"/><circle cx="10" cy="17" r="2.2"/></svg>',
    cot: '<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M5 20V11M10 20V5M15 20v-7M20 20V8M3 20.5h18"/></svg>',
    so: '<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><rect x="4" y="3.5" width="16" height="17" rx="2.5"/><path d="M8 8h8M8 12h8M8 16h5"/></svg>',
    but: '<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20l1-4L16 5l3 3L8 19l-4 1zM14 7l3 3"/></svg>',
    sao: '<svg class="ic" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.8l2.7 5.7 6.2.8-4.6 4.3 1.2 6.2L12 16.9 6.5 19.8l1.2-6.2L3.1 9.3l6.2-.8z"/></svg>',
    tho: '<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"><path d="M3 9h11a3 3 0 1 0-3-3M3 13h15a3 3 0 1 1-3 3M3 17h7"/></svg>',
  };

  // ---------------------------------------------------------------- điều hướng
  const ngan = [];
  let hienTai = null;
  const MAN = {};

  /** Đóng hộp thoại đang mở mà KHÔNG chạy việc của nó (màn đổi thì hộp của màn cũ hết nghĩa). */
  function dongHopIm() {
    const h = $('#hop');
    h.hidden = true;
    h.innerHTML = '';
    dongHopCb = null;
  }
  function di(man, ts, thay) {
    dongHopIm();
    if (hienTai && hienTai.don) { try { hienTai.don(); } catch (x) { /* thôi */ } }
    if (hienTai && !thay) ngan.push({ man: hienTai.man, ts: hienTai.ts });
    hienTai = { man, ts };
    ve();
    window.scrollTo(0, 0);
  }
  function ve() {
    const el = $('#man');
    el.innerHTML = '';
    el.className = 'man man-' + hienTai.man;
    hienTai.don = MAN[hienTai.man](el, hienTai.ts) || null;
  }
  function veChinh() {
    dongHopIm();
    if (hienTai && hienTai.don) { try { hienTai.don(); } catch (x) { /* thôi */ } }
    ngan.length = 0;
    hienTai = { man: 'chinh' };
    ve();
    window.scrollTo(0, 0);
  }
  function lui() {
    if (!ngan.length) {
      if (hienTai.man !== 'chinh') { veChinh(); return true; }
      return false;
    }
    dongHopIm();
    if (hienTai.don) { try { hienTai.don(); } catch (x) { /* thôi */ } }
    hienTai = ngan.pop();
    ve();
    return true;
  }
  /** Phím / cử chỉ Quay lại của máy. Trả true nếu trang tự xử lý. */
  function quayLai() {
    if (!$('#hop').hidden) { dongHop(); return true; }
    if (hienTai.man === 'buoi') { hoiDung(); return true; }
    if (hienTai.quayLai && hienTai.quayLai()) return true;
    return lui();
  }

  let dongHopCb = null;
  const thanhTren = t => `<header class="thanh"><button class="lui" data-lui aria-label="Quay lại">‹</button><h2>${e(t)}</h2></header>`;
  function noiLui(el) { $$('[data-lui]', el).forEach(b => { b.onclick = () => lui(); }); }

  // ---------------------------------------------------------------- hộp thoại + báo nhanh
  function hop(o) {
    if (typeof o === 'string') o = { chu: o };
    const h = $('#hop');
    const nut = o.nut || [{ t: 'Được' }];
    h.innerHTML = `<div class="nen-hop"></div><div class="the-hop" role="dialog">${o.tieuDe ? `<h3>${e(o.tieuDe)}</h3>` : ''}` +
      `<p>${e(o.chu || '')}</p><div class="hang-nut">${nut.map((n, i) => `<button class="nut ${n.kieu || ''}" data-i="${i}">${e(n.t)}</button>`).join('')}</div></div>`;
    h.hidden = false;
    dongHopCb = o.huy || null;
    $('.nen-hop', h).onclick = () => dongHop();
    $$('[data-i]', h).forEach(b => {
      b.onclick = () => {
        const n = nut[+b.dataset.i];
        dongHopCb = null;
        dongHop();
        if (n.f) n.f();
      };
    });
  }
  function dongHop() {
    const h = $('#hop');
    h.hidden = true;
    h.innerHTML = '';
    const cb = dongHopCb;
    dongHopCb = null;
    if (cb) cb();
  }
  let henBao = 0;
  function bao(s) {
    const b = $('#bao');
    b.textContent = s;
    b.hidden = false;
    clearTimeout(henBao);
    henBao = setTimeout(() => { b.hidden = true; }, 2600);
  }

  // ================================================================= MÀN CHÍNH
  MAN.chinh = el => {
    const d = json('trangChinh');
    const muc = (man, ten, phu, ic, nen, mau) => `<button class="muc" data-di="${man}"><span class="vong" style="background:${nen};color:${mau}">${ic}</span>` +
      `<span><span class="ten">${e(ten)}</span><span class="phu">${e(phu)}</span></span><span class="mui">›</span></button>`;
    el.innerHTML = `
      <section class="man-dau" id="manDau">
        <div class="buu-anh"><span class="bang-keo"></span><img src="dau.jpg" alt=""><span class="tem">${IC.tuyet}</span></div>
        <blockquote class="loi-ong" id="loiOng">“${e(LOI_ONG)}”</blockquote>
        <span class="keo-xuong" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9l6 6 6-6"/></svg></span>
      </section>
      <p class="ky-ten">— Wim Hof không nói vậy</p>
      <header class="dau">
        <h1>Ìe Bắc Âu</h1>
        <p class="phu">${e(d.dongPhu || 'thở cùng ông Wim · rảnh tay từ đầu tới cuối')}</p>
      </header>
      <div class="the nhac">${IC.tuyet}<p>${e(d.nhacNho || '')}</p></div>
      <button class="nut-lon" id="batDau"><span class="t">${IC.tho} Bắt đầu thở</span><span class="s">${e(d.batDau || '')}</span></button>
      <nav class="ds-muc">
        ${muc('ninvui', 'Nín thở vui', d.ninVui || 'đồng hồ bấm giờ thử sức nín', IC.dongHo, 'var(--hong-nhat)', 'var(--san-ho)')}
        ${muc('caidat', 'Cài đặt', 'số hiệp, giây nín thở, giây giữ hơi phục hồi', IC.banhRang, 'var(--mu-tat-nhat)', 'var(--vang)')}
        ${muc('thongke', 'Thống kê', d.thongKe || 'lịch tập, kỷ lục, huy hiệu', IC.cot, 'var(--bac-ha-nhat)', 'var(--bang)')}
        ${muc('ds', 'Các buổi đã tập', d.dsBuoi || 'chưa có buổi nào', IC.so, 'var(--lam-nhat)', 'var(--lam-cu)')}
        ${muc('nhatky', 'Nhật ký', 'chụp màn này gửi lại khi có lỗi', IC.but, 'var(--giay-dam)', 'var(--mo)')}
      </nav>
      <p class="cau">“${e(d.cau || '')}”</p>
      <p class="chan">Ìe Bắc Âu ${e(d.phienBan || '')} · thở theo cách của Wim Hof, không phải app chính thức của ông</p>`;
    $('#batDau', el).onclick = batDau;
    $$('[data-di]', el).forEach(b => { b.onclick = () => di(b.dataset.di); });
    vuaLoiOng();
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(vuaLoiOng);
    $('img', el).addEventListener('load', vuaLoiOng);
    window.addEventListener('resize', vuaLoiOng);
    return () => window.removeEventListener('resize', vuaLoiOng);
  };

  // Câu user viết 17/11 — chiếm TRỌN màn đầu (cỡ chữ tự co giãn cho vừa khoảng trống dưới ảnh), kéo xuống mới thấy ký tên.
  const LOI_ONG = 'Tôi biết các bạn thông qua mấy con gà, nên tôi đồng ý cho phép các bạn làm app này. Thực ra thì, các bạn đã làm những điều ' +
    'còn phi thường hơn cả tôi, vì ở chỗ tôi thì trời lạnh dễ đoán, còn nơi các bạn thì thời tiết có thể nóng lạnh khó lường hơn nhiều. ' +
    'Tôi thực sự nể phục các bạn.';
  function vuaLoiOng() {
    const sec = $('#manDau'), q = $('#loiOng');
    if (!sec || !q) return;
    const anh = $('.buu-anh', sec), keo = $('.keo-xuong', sec);
    const cs = getComputedStyle(anh);
    const cao = sec.clientHeight - anh.offsetHeight - parseFloat(cs.marginTop) - parseFloat(cs.marginBottom) - keo.offsetHeight - 14;
    let lo = 15, hi = 72;
    for (let i = 0; i < 14; i++) {
      const m = (lo + hi) / 2;
      q.style.fontSize = m + 'px';
      if (q.scrollHeight <= cao) lo = m; else hi = m;
    }
    q.style.fontSize = Math.floor(lo * 10) / 10 + 'px';
  }

  function batDau() {
    const loi = goi('batDauBuoi');
    if (loi) { hop({ tieuDe: 'Chưa thở được', chu: loi }); return; }
    di('buoi');
  }

  // ================================================================= BUỔI THỞ
  const SO_KHUNG = 24;
  let khung = null;
  function napKhung() {
    if (khung) return khung;
    khung = [];
    for (let i = 0; i < SO_KHUNG; i++) {
      const im = new Image();
      im.decoding = 'async';
      im.src = 'khung/k' + String(i).padStart(2, '0') + '.jpg';
      khung.push(im);
    }
    return khung;
  }

  MAN.buoi = el => {
    el.innerHTML = `
      <div class="anh-khung"><canvas id="cv"></canvas>
        <div class="tren"><span class="chip" id="hiep">Hiệp 1</span><span class="chip" id="buoc">Chuẩn bị</span></div>
      </div>
      <section class="the-tho">
        <div class="lon vua" id="lon">Chuẩn bị…</div>
        <div class="nho-tho" id="nho">đang mở tiếng…</div>
        <div class="vach" title="phổi đầy cỡ nào"><i id="day" style="width:30%"></i></div>
        <div class="tien"><i id="pn" style="width:0%"></i></div>
        <div class="nhan-tien"><span id="gio"></span><span id="con"></span></div>
        <div class="hang-nut"><button class="nut" id="tam">Tạm dừng</button><button class="nut nut-dung" id="dung">Dừng</button></div>
        <p class="goi-y">Phím âm lượng bên hông máy: to / nhỏ tiếng · tắt màn hình vẫn thở tiếp</p>
      </section>`;
    goi('giuManHinh', true);
    const anh = napKhung();
    const cv = $('#cv', el), ctx = cv.getContext('2d');
    const o = { lon: $('#lon', el), nho: $('#nho', el), hiep: $('#hiep', el), buoc: $('#buoc', el), day: $('#day', el), pn: $('#pn', el),
      gio: $('#gio', el), con: $('#con', el), tam: $('#tam', el) };
    const cu = {};
    let raf = 0, dungVe = false, tamDung = false;
    const moLuc = performance.now();
    function coLai() {
      const r = cv.getBoundingClientRect(), dpr = Math.min(2.5, window.devicePixelRatio || 1);
      cv.width = Math.round(r.width * dpr);
      cv.height = Math.round(r.height * dpr);
      ctx.imageSmoothingQuality = 'high';
    }
    coLai();
    window.addEventListener('resize', coLai);
    function veAnh(day) {
      const f = Math.max(0, Math.min(1, day)) * (SO_KHUNG - 1), i = Math.floor(f), t = f - i;
      const a = anh[i], b = anh[Math.min(SO_KHUNG - 1, i + 1)];
      if (!a.complete || !a.naturalWidth) return;
      const W = cv.width, H = cv.height, s = Math.max(W / a.naturalWidth, H / a.naturalHeight);
      const w = a.naturalWidth * s, h = a.naturalHeight * s, x = (W - w) / 2, y = (H - h) * 0.6;
      ctx.globalAlpha = 1;
      ctx.drawImage(a, x, y, w, h);
      if (t > 0.02 && b.complete && b.naturalWidth) {
        ctx.globalAlpha = t;
        ctx.drawImage(b, x, y, w, h);
        ctx.globalAlpha = 1;
      }
    }
    function dat(k, v, f) { if (cu[k] !== v) { cu[k] = v; f(v); } }
    const mau = s => s.loai === 1 ? (s.lon === 'IN' ? 'var(--san-ho)' : s.lon === 'OUT' ? 'var(--lam-cu)' : 'var(--chu)')
      : s.loai === 2 ? 'var(--bang)' : s.loai === 3 ? 'var(--vang)' : 'var(--chu)';
    const dh = g => { g = Math.max(0, g | 0); return (g >= 3600 ? Math.floor(g / 3600) + ':' : '') + String(Math.floor(g / 60) % 60).padStart(2, '0') + ':' + String(g % 60).padStart(2, '0'); };
    function vong() {
      if (dungVe) return;
      raf = requestAnimationFrame(vong);
      const s = json('buoi');
      if (!s.co) {
        if (!s.ketQua && !s.loi && performance.now() - moLuc < 6000) { veAnh(0.3); return; }   // dịch vụ đang khởi động
        ketThuc(s);
        return;
      }
      tamDung = !!s.tam;
      dat('hiep', 'Hiệp ' + (s.hiep || 1) + ' / ' + (s.soHiep || 1), v => { o.hiep.textContent = v; });
      dat('buoc', (s.buoc || '') + (s.gio ? ' · ' + s.gio : ''), v => { o.buoc.textContent = v; });
      dat('lon', s.lon || '', v => { o.lon.textContent = v; o.lon.classList.toggle('vua', v.length > 5); });
      dat('mau', mau(s), v => { o.lon.style.color = v; });
      dat('nho', s.nho || '', v => { o.nho.textContent = v; });
      dat('day', Math.round((s.day || 0) * 1000), v => { o.day.style.width = (v / 10) + '%'; });
      dat('pn', s.pn || 0, v => { o.pn.style.width = (v / 10) + '%'; });
      dat('con', s.con != null ? 'còn ' + dh(s.con) : '', v => { o.con.textContent = v; });
      dat('gioPn', s.pn != null ? Math.floor((s.pn || 0) / 10) + '% buổi' : '', v => { o.gio.textContent = v; });
      dat('tam', tamDung ? 'Tiếp tục' : 'Tạm dừng', v => { o.tam.textContent = v; o.tam.classList.toggle('nut-chinh', tamDung); });
      veAnh(s.day == null ? 0.3 : s.day);
    }
    function ketThuc(s) {
      dungVe = true;
      cancelAnimationFrame(raf);
      goi('daXem');
      if (s.ketQua) di('xong', s.ketQua, true);
      else veChinh();
      if (s.loi) hop({ tieuDe: 'Buổi thở dừng', chu: s.loi });
    }
    o.tam.onclick = () => { goi(tamDung ? 'tiepTuc' : 'tamDung'); };
    $('#dung', el).onclick = hoiDung;
    raf = requestAnimationFrame(vong);
    return () => {
      dungVe = true;
      cancelAnimationFrame(raf);
      window.removeEventListener('resize', coLai);
      goi('giuManHinh', false);
    };
  };

  function hoiDung() {
    const s = json('buoi');
    if (!s.co) { veChinh(); return; }
    hop({
      tieuDe: 'Dừng buổi thở?',
      chu: s.seGhi ? 'Các hiệp đã xong vẫn được ghi.' + (s.loai === 2 ? ' Hiệp đang nín dở ghi đúng số giây bạn đã nín.' : '')
        : 'Chưa xong hiệp nào nên buổi này không được ghi.',
      nut: [{ t: 'Tập tiếp' }, {
        t: 'Dừng', kieu: 'nut-dung', f: () => {
          if (!json('buoi').co) { theoBuoi(); return; }      // buổi đã tự xong trong lúc hộp đang mở
          const kq = goi('dungBuoi');
          goi('daXem');
          if (kq) { try { di('xong', JSON.parse(kq), true); return; } catch (x) { /* thôi */ } }
          veChinh();
        },
      }],
    });
  }

  // ================================================================= XONG BUỔI / CHI TIẾT
  function veChiTiet(el, k, laXong) {
    if (!k || k.id == null) { el.innerHTML = thanhTren('Buổi thở') + '<p class="trong">Không tìm thấy buổi này.</p>'; noiLui(el); return; }
    const pt = v => Math.max(0, Math.min(100, v / Math.max(1, k.max) * 100));
    el.innerHTML = `
      ${thanhTren(laXong ? 'Xong buổi thở' : 'Buổi thở')}
      ${laXong ? `<div class="khen"><h2>${e(k.loiKhen)}</h2>${(k.khen || []).map(x => `<span class="tem-khen">${e(x)}</span>`).join('')}</div>` : ''}
      <div class="the"><p class="dam">${e(k.ngay)}</p><p>${xuong(k.tom)}</p><p class="mo nho" style="margin-top:4px">${e(k.phu)}</p></div>
      <div class="the"><h3>Nín từng hiệp</h3>
        ${(k.hiep || []).map((h, i) => `<div class="hiep-hang"><span class="ten">Hiệp ${i + 1}</span>
          <div class="thanh-ngang"><i class="${h.dat ? 'dat' : ''}" style="width:${pt(h.thuc)}%"></i>${h.muc > 0 ? `<b style="left:${pt(h.muc)}%"></b>` : ''}</div>
          <span class="so">${e(h.chu)}</span></div>`).join('')}
        <p class="mo nho">vạch hồng = mức nín đã đặt · thanh xanh ngọc = nín đủ mức</p>
      </div>
      <p class="cau">“${e(k.cau)}”</p>
      ${laXong ? '<button class="nut-lon gon" id="ve"><span class="t">Về màn chính</span></button>'
        : '<button class="nut nut-dung rong" id="xoa">Xoá buổi này…</button>'}`;
    noiLui(el);
    if (laXong) $('#ve', el).onclick = veChinh;
    else $('#xoa', el).onclick = () => hop({
      tieuDe: 'Xoá buổi này?', chu: k.ngay + '\nXoá rồi không lấy lại được.',
      nut: [{ t: 'Thôi' }, { t: 'Xoá', kieu: 'nut-dung', f: () => { if (goi('xoaBuoi', k.id)) { bao('Đã xoá buổi'); lui(); } else bao('Xoá không được'); } }],
    });
  }
  MAN.xong = (el, k) => veChiTiet(el, k, true);
  MAN.chitiet = (el, id) => veChiTiet(el, json('chiTiet', id), false);

  // ================================================================= NÍN THỞ VUI
  MAN.ninvui = el => {
    const CHO = 0, CHAY = 1, XONG = 2;
    let tt = CHO, t0 = 0, batDauLuc = 0, ketQua = 0, kyMoi = false, idCuoi = 0, raf = 0, d = json('ninVui');
    const vach = [];
    for (let i = 0; i < 60; i++) {
      const a = i * 6 * Math.PI / 180, r1 = i % 5 === 0 ? 118 : 124, r2 = 131;
      vach.push(`<line x1="${150 + r1 * Math.sin(a)}" y1="${150 - r1 * Math.cos(a)}" x2="${150 + r2 * Math.sin(a)}" y2="${150 - r2 * Math.cos(a)}" stroke="${i % 5 === 0 ? '#8A7262' : '#CDB58D'}" stroke-width="${i % 5 === 0 ? 3 : 1.6}" stroke-linecap="round"/>`);
    }
    const so = [0, 15, 30, 45].map((n, i) => {
      const a = i * Math.PI / 2;
      return `<text x="${150 + 100 * Math.sin(a)}" y="${150 - 100 * Math.cos(a) + 6}" text-anchor="middle" font-family="Lora,serif" font-size="17" fill="#8A7262">${n}</text>`;
    }).join('');
    el.innerHTML = `${thanhTren('Nín thở vui')}
      <div class="mat-dh" id="mat">
        <svg viewBox="0 0 300 300">
          <circle cx="150" cy="150" r="142" fill="#FFF9EE" stroke="#CDB58D" stroke-width="3" stroke-dasharray="7 6"/>
          <circle cx="150" cy="150" r="134" fill="none" stroke="#F3E5C8" stroke-width="2"/>
          <circle id="vongKy" cx="150" cy="150" r="138" fill="none" stroke="#E3A82B" stroke-width="5" stroke-linecap="round"
            stroke-dasharray="0 1000" transform="rotate(-90 150 150)" opacity=".75"/>
          ${vach.join('')}${so}
          <g id="kim"><line x1="150" y1="168" x2="150" y2="34" stroke="#E07A5F" stroke-width="4" stroke-linecap="round"/>
            <circle cx="150" cy="150" r="8" fill="#E07A5F"/><circle cx="150" cy="150" r="3" fill="#FFF9EE"/></g>
        </svg>
        <div class="giua"><div class="so" id="so">0:00,0</div><div class="vong-nho" id="vong"></div></div>
      </div>
      <p class="s1" id="s1"></p><p class="s2" id="s2"></p>
      <div class="the" id="tk"></div>`;
    noiLui(el);
    const mat = $('#mat', el), soEl = $('#so', el), vongEl = $('#vong', el), kim = $('#kim', el), s1 = $('#s1', el), s2 = $('#s2', el),
      vongKy = $('#vongKy', el);
    const dongHo = ms => { ms = Math.max(0, ms); const s = Math.floor(ms / 1000), m = Math.floor(s / 60); return m + ':' + String(s % 60).padStart(2, '0') + ',' + Math.floor((ms % 1000) / 100); };
    function chu() {
      const ky = d.kyLuc || 0;
      if (tt === CHAY) {
        const ms = performance.now() - t0;
        s1.className = 's1';
        s1.textContent = 'Đang nín… bình tĩnh, thả lỏng vai';
        s2.textContent = ky > 0 && ms < ky ? 'còn ' + dongHo(ky - ms) + ' nữa là phá kỷ lục' : ky > 0 ? 'VƯỢT KỶ LỤC rồi! Chạm để dừng khi cần thở' : 'chạm để dừng khi cần thở';
      } else if (tt === XONG) {
        s1.className = 's1' + (kyMoi ? ' ky' : '');
        s1.textContent = kyMoi ? 'KỶ LỤC MỚI: ' + dongHo(ketQua) + '!' : ketQua < 1000 ? 'Bấm nhầm rồi, thử lại nhé' : 'Lần này ' + dongHo(ketQua);
        s2.textContent = 'chạm đồng hồ để thử lần nữa';
      } else {
        s1.className = 's1';
        s1.textContent = 'Hít thở vài hơi, thở ra hết, rồi chạm để bắt đầu nín';
        s2.textContent = 'chạm vào mặt đồng hồ';
      }
    }
    function veTk() {
      d = json('ninVui');
      const gd = d.ganDay || [];
      $('#tk', el).innerHTML = `<h3>${e(d.kyLucChu || 'chưa có kỷ lục')}</h3><p class="mo">${e(d.tom || '')}</p>` +
        (gd.length ? `<ul class="gan-day">${gd.map(x => `<li><span class="mo">${e(x.luc)}</span><span class="ms">${e(x.chu)}</span></li>`).join('')}</ul>` : '') +
        (tt === XONG && idCuoi ? '<button class="nut rong" id="xoaCuoi" style="margin-top:12px">Xoá lần vừa rồi</button>' : '');
      const xb = $('#xoaCuoi', el);
      if (xb) xb.onclick = () => hop({
        tieuDe: 'Xoá lần nín ' + dongHo(ketQua) + '?', nut: [{ t: 'Thôi' }, {
          t: 'Xoá', kieu: 'nut-dung', f: () => { goi('ninVuiXoa', idCuoi); idCuoi = 0; tt = CHO; veTk(); chu(); veMat(0); bao('Đã xoá lần vừa rồi'); },
        }],
      });
      veMat(tt === CHAY ? performance.now() - t0 : tt === XONG ? ketQua : 0);
    }
    function veMat(ms) {
      kim.setAttribute('transform', `rotate(${(ms / 60000 * 360) % 360} 150 150)`);
      soEl.textContent = dongHo(ms);
      vongEl.textContent = ms >= 60000 ? 'vòng ' + (Math.floor(ms / 60000) + 1) : '';
      const ky = d.kyLuc || 0, chuVi = 2 * Math.PI * 138;
      const p = ky > 0 ? Math.min(1, ms / ky) : 0;
      vongKy.setAttribute('stroke-dasharray', `${p * chuVi} ${chuVi}`);
      vongKy.setAttribute('stroke', ky > 0 && ms > ky ? '#E07A5F' : '#E3A82B');
    }
    function chay() {
      raf = requestAnimationFrame(chay);
      veMat(performance.now() - t0);
      chu();
    }
    function bam() {
      if (tt === CHAY) {
        cancelAnimationFrame(raf);
        ketQua = Math.round(performance.now() - t0);
        const r = json('ninVuiThem', batDauLuc, ketQua);
        kyMoi = !!r.kyLucMoi;
        idCuoi = r.ghi ? batDauLuc : 0;
        tt = XONG;
        goi('rung');
        goi('giuManHinh', false);
        veMat(ketQua);
        chu();
        veTk();
      } else {
        tt = CHAY;
        t0 = performance.now();
        batDauLuc = Date.now();
        kyMoi = false;
        goi('rung');
        goi('giuManHinh', true);
        chay();
        veTk();
      }
    }
    mat.onclick = bam;
    hienTai.quayLai = () => { if (tt === CHAY) { bam(); return true; } return false; };
    chu();
    veTk();
    return () => { cancelAnimationFrame(raf); if (tt === CHAY) bam(); goi('giuManHinh', false); };
  };

  // ================================================================= CÀI ĐẶT
  MAN.caidat = el => {
    const d = json('caiDat');
    const dsNin = d.dsNin || [], dsGiu = d.dsGiu || [];
    const s = { soHiep: d.soHiep || 3, nin: d.nin || 90, giu: d.giu || 15 };
    const gan = (ds, v) => { let b = 0; ds.forEach((x, i) => { if (Math.abs(x.v - v) < Math.abs(ds[b].v - v)) b = i; }); return b; };
    el.innerHTML = `${thanhTren('Cài đặt buổi thở')}
      <div class="the"><h3>Số hiệp</h3><div class="chips" id="hiep">${[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(n =>
        `<button class="chip-chon ${n === s.soHiep ? 'chon' : ''}" data-v="${n}">${n}</button>`).join('')}</div></div>
      <div class="the"><h3>Nín thở mỗi hiệp</h3><div class="gia-tri" id="ninT"></div>
        <input type="range" id="nin" min="0" max="${Math.max(0, dsNin.length - 1)}" step="1" value="${gan(dsNin, s.nin)}">
        <div class="hai-dau"><span>15 giây</span><span>thở ra hết rồi nín</span><span>10 phút</span></div></div>
      <div class="the"><h3>Hít vào giữ (phục hồi)</h3><div class="gia-tri" id="giuT"></div>
        <input type="range" id="giu" min="0" max="${Math.max(0, dsGiu.length - 1)}" step="1" value="${gan(dsGiu, s.giu)}">
        <div class="hai-dau"><span>5 giây</span><span>hít đầy rồi giữ</span><span>60 giây</span></div></div>
      <div class="the du-kien" id="dk">${e(d.duKien || '')}</div>
      <div class="the giai-thich">${e(d.giaiThich || '')}</div>`;
    noiLui(el);
    const ninI = $('#nin', el), giuI = $('#giu', el), ninT = $('#ninT', el), giuT = $('#giuT', el), dk = $('#dk', el);
    let hen = 0;
    function hien() {
      ninT.textContent = dsNin[+ninI.value] ? dsNin[+ninI.value].t : '';
      giuT.textContent = dsGiu[+giuI.value] ? dsGiu[+giuI.value].t : '';
    }
    function luu() {
      s.nin = dsNin[+ninI.value] ? dsNin[+ninI.value].v : s.nin;
      s.giu = dsGiu[+giuI.value] ? dsGiu[+giuI.value].v : s.giu;
      clearTimeout(hen);
      hen = setTimeout(() => { const r = goi('datCaiDat', s.soHiep, s.nin, s.giu); if (r) dk.textContent = r; }, 120);
    }
    ninI.oninput = () => { hien(); luu(); };
    giuI.oninput = () => { hien(); luu(); };
    $$('#hiep button', el).forEach(b => {
      b.onclick = () => {
        s.soHiep = +b.dataset.v;
        $$('#hiep button', el).forEach(x => x.classList.toggle('chon', x === b));
        luu();
      };
    });
    hien();
  };

  // ================================================================= THỐNG KÊ
  const TEN_KY = ['Hôm nay', 'Tuần này', 'Tháng này', 'Năm nay', 'Tất cả'];
  MAN.thongke = (el, ts) => {
    let ky = ts && ts.ky != null ? ts.ky : 1, luiKy = 0;
    function veTk() {
      const d = json('thongKe', ky, luiKy);
      const cot = d.cot;
      const bd = (ds, lop) => {
        const max = Math.max(1, ...ds);
        return `<div class="bieu-do ${lop}">${ds.map(v => `<div class="c"><i class="${v > 0 ? 'co' : ''}" style="height:${v > 0 ? Math.max(4, v / max * 100) : 3}%"></i></div>`).join('')}</div>`;
      };
      const nhan = ds => {
        const buoc = ds.length > 12 ? 5 : 1;
        return `<div class="nhan-cot">${ds.map((t, i) => `<span>${i % buoc === 0 || i === ds.length - 1 ? e(t) : ''}</span>`).join('')}</div>`;
      };
      const l = d.lich || { giay: [], lech: 0, homNay: -1 };
      const maxL = Math.max(1, ...(l.giay || [0]));
      const tron = (a, b, t) => { const p = n => parseInt(n, 16); const c = [0, 2, 4].map(i => Math.round(p(a.substr(i + 1, 2)) + (p(b.substr(i + 1, 2)) - p(a.substr(i + 1, 2))) * t)); return `rgb(${c.join(',')})`; };
      let o = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map(t => `<div class="thu">${t}</div>`).join('');
      for (let i = 0; i < l.lech; i++) o += '<div></div>';
      (l.giay || []).forEach((g, i) => {
        if (g > 0) {
          const muc = Math.min(1000, 300 + g * 700 / maxL);
          o += `<div class="o co ${muc > 650 ? 'dam-mau' : ''} ${i === l.homNay ? 'nay' : ''}" style="background:${tron('#F6E2B0', '#E07A5F', muc / 1000)}">${i + 1}<small>${Math.max(1, Math.round(g / 60))}'</small></div>`;
        } else o += `<div class="o ${i === l.homNay ? 'nay' : ''}">${i + 1}</div>`;
      });
      const NEN = ['var(--mu-tat-nhat)', 'var(--hong-nhat)', 'var(--bac-ha-nhat)', 'var(--lam-nhat)'], VIEN = ['var(--mu-tat)', 'var(--san-ho)', 'var(--bac-ha)', 'var(--lam-cu)'];
      let mi = 0;
      const hh = (d.huyHieu || []).map(h => h.dat
        ? `<div class="st dat" style="background:${NEN[mi % 4]};border-color:${VIEN[mi++ % 4]}">${IC.sao}<div><b>${e(h.ten)}</b><span>${e(h.moTa)}</span></div></div>`
        : `<div class="st chua">${IC.sao}<div><b>${e(h.ten)}</b><span>${e(h.moTa)}</span></div></div>`).join('');
      el.innerHTML = `${thanhTren('Thống kê')}
        <div class="tab">${TEN_KY.map((t, i) => `<button data-ky="${i}" class="${i === ky ? 'chon' : ''}">${t}</button>`).join('')}</div>
        ${ky !== 4 ? `<div class="dieu-huong"><button class="nut" id="truoc">‹ Trước</button><button class="nut" id="nay" ${luiKy === 0 ? 'disabled' : ''}>Nay</button>
          <button class="nut" id="sau" ${luiKy === 0 ? 'disabled' : ''}>Sau ›</button></div>` : ''}
        <p class="tieu-ky">${e(d.tieuDe || '')}</p>
        ${d.o ? `<div class="o-so">${d.o.map(x => `<div><b>${e(x.so)}</b><span>${e(x.chu)}</span></div>`).join('')}</div>` : ''}
        <div class="the dong-tk">${(d.dong || []).map(x => `<p>${e(x)}</p>`).join('')}</div>
        <div class="the ky-luc">${e(d.kyLuc || '')}</div>
        ${cot ? `<div class="the"><div class="dau-bd"><b style="color:var(--chu)">Phút tập</b><span>${e(cot.maxPhut)}</span></div>${bd(cot.phut, 'phut')}${nhan(cot.nhan)}
          <div class="dau-bd"><b style="color:var(--chu)">Nín lâu nhất</b><span>${e(cot.maxNin)}</span></div>${bd(cot.nin, 'nin')}${nhan(cot.nhan)}</div>` : ''}
        <div class="the"><h3>${e(l.tieuDe || '')}</h3><div class="lich">${o}</div></div>
        <div class="the"><h3>Huy hiệu (${e(d.soHuyHieu || 0)} đã đạt)</h3><p class="mo nho">sticker màu là đã có, viền chấm là sắp tới</p><div class="sticker">${hh}</div></div>
        <div class="the"><p class="dam">${e(d.ninVui || '')}</p><p style="margin-top:6px">${e(d.nhacNho || '')}</p></div>
        <p class="cau">“${e(d.cau || '')}”</p>`;
      noiLui(el);
      $$('[data-ky]', el).forEach(b => { b.onclick = () => { ky = +b.dataset.ky; luiKy = 0; hienTai.ts = { ky }; veTk(); }; });
      const tr = $('#truoc', el), nay = $('#nay', el), sau = $('#sau', el);
      if (tr) tr.onclick = () => { luiKy++; veTk(); };
      if (nay) nay.onclick = () => { luiKy = 0; veTk(); };
      if (sau) sau.onclick = () => { if (luiKy > 0) luiKy--; veTk(); };
    }
    veTk();
  };

  // ================================================================= DANH SÁCH BUỔI
  MAN.ds = el => {
    const ds = (() => { try { return JSON.parse(goi('dsBuoi') || '[]'); } catch (x) { return []; } })();
    el.innerHTML = `${thanhTren('Các buổi đã tập')}` + (ds.length
      ? `<div class="ds-buoi">${ds.map(b => `<button data-id="${b.id}"><b>${e(b.tieuDe)}</b><span>${e(b.dong)}</span></button>`).join('')}</div>`
      : '<p class="trong">Chưa có buổi nào.<br>Màn chính → Bắt đầu thở</p>');
    noiLui(el);
    $$('[data-id]', el).forEach(b => { b.onclick = () => di('chitiet', +b.dataset.id); });
  };

  // ================================================================= NHẬT KÝ
  MAN.nhatky = el => {
    const t = goi('nhatKy') || '(không đọc được nhật ký)';
    el.innerHTML = `${thanhTren('Nhật ký')}<p class="mo nho">Có lỗi thì chụp màn này hoặc bấm “Gửi nhật ký” rồi gửi lại.</p>
      <pre class="nk">${e(t)}</pre><button class="nut rong" id="gui">Gửi nhật ký</button>`;
    noiLui(el);
    $('#gui', el).onclick = () => goi('chiaSe', t);
  };

  // ================================================================= vòng đời
  /** Mở lại app / dịch vụ báo đổi: đưa về đúng màn theo trạng thái buổi thở. */
  function theoBuoi() {
    const s = json('buoi');
    if (s.co) {
      if (hienTai.man !== 'buoi') { if (hienTai.man !== 'chinh') veChinh(); di('buoi'); }
      return true;
    }
    if (s.ketQua && hienTai.man !== 'xong') {
      goi('daXem');
      if (hienTai.man === 'buoi') di('xong', s.ketQua, true);
      else { veChinh(); di('xong', s.ketQua); }
      if (s.loi) hop({ tieuDe: 'Buổi thở dừng', chu: s.loi });
      return true;
    }
    if (s.loi) {
      goi('daXem');
      if (hienTai.man === 'buoi') veChinh();
      hop({ tieuDe: 'Buổi thở dừng', chu: s.loi });
      return true;
    }
    return false;
  }
  function hienLai() {
    if (theoBuoi()) return;
    if (['chinh', 'thongke', 'ds'].includes(hienTai.man) && $('#hop').hidden) ve();
  }
  function buoiDoi() {
    if (hienTai.man === 'buoi') return;          // màn buổi thở tự thấy qua vòng vẽ
    theoBuoi();
  }
  function vien(tren, duoi) {
    document.documentElement.style.setProperty('--tren', Math.max(0, tren) + 'px');
    document.documentElement.style.setProperty('--duoi', Math.max(0, duoi) + 'px');
  }

  function batDauApp() {
    hienTai = { man: 'chinh' };
    ve();
    theoBuoi();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', batDauApp);
  else batDauApp();

  return { quayLai, hienLai, buoiDoi, vien, di };
})();
window.XK = XK;
