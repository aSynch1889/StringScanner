(() => {
  const copy = {
    zh: {
      title: "StringScanner — Swift / ObjC 字符串审计",
      description:
        "扫描 Swift 与 Objective-C 项目中的字符串字面量，识别本地化缺口。提供 macOS GUI 与 CLI，免费开源。",
      navPreview: "界面",
      navFeatures: "能力",
      navDownload: "下载",
      eyebrow: "开源 · macOS 13+ · arm64",
      lede: "把工程里的字符串字面量一次扫清，标出还没本地化的缺口。",
      ctaDownload: "下载安装包",
      ctaPreview: "看真实界面",
      shotAlt: "StringScanner 应用界面截图",
      previewKicker: "产品截图",
      previewTitle: "侧栏扫描，按文件审字面量",
      previewLede: "导出、筛选、主题与语言都在同一窗口里，不靠运行时截图猜漏翻。",
      capKicker: "能力",
      featuresTitle: "在源码里找字符串",
      f1Title: "Swift 与 Objective-C",
      f1Body:
        "覆盖 .swift / .m / .h，识别 NSLocalizedString、String(localized:)、Text 等常见写法。",
      f2Title: "GUI 与 CLI 同一套引擎",
      f2Body: "侧栏一键扫描、筛选、导出；命令行进脚本与 CI。",
      f3Title: "直接进 Xcode",
      f3Body: "导出 .xcstrings / .strings，也可 JSON、CSV，并支持自定义本地化包装。",
      downloadTitle: "下载",
      downloadHeading: "装上就能扫",
      downloadLede:
        "v1.1.0 · build 722d038 · Apple Silicon。若被拦截，右键「打开」，或执行下方 quarantine 命令。",
      dlGuiTitle: "macOS GUI",
      dlGuiBody: "拖进「应用程序」的 .app",
      dlCliTitle: "CLI",
      dlCliBody: "stringscanner-cli，适合终端与自动化",
      dlAction: "下载 .zip",
      cliKicker: "命令行",
      cliTitle: "三分钟上手",
      cliLede: "解压、赋权，直接扫整个工程目录。",
    },
    en: {
      title: "StringScanner — Swift / ObjC literal audit",
      description:
        "Scan Swift and Objective-C projects for string literals, spot localization gaps. macOS GUI and CLI, free and open source.",
      navPreview: "UI",
      navFeatures: "Capabilities",
      navDownload: "Download",
      eyebrow: "Open source · macOS 13+ · arm64",
      lede: "Sweep every string literal in the project, and flag what still isn’t localized.",
      ctaDownload: "Download",
      ctaPreview: "See the real UI",
      shotAlt: "StringScanner app screenshot",
      previewKicker: "Screenshots",
      previewTitle: "Scan in the sidebar, audit by file",
      previewLede:
        "Export, filters, theme, and language live in one window — no guessing from runtime screenshots.",
      capKicker: "Capabilities",
      featuresTitle: "Find strings in source",
      f1Title: "Swift and Objective-C",
      f1Body:
        "Covers .swift / .m / .h and common APIs like NSLocalizedString, String(localized:), and Text.",
      f2Title: "One engine, GUI & CLI",
      f2Body: "Scan, filter, and export in the app; drive scripts and CI from the terminal.",
      f3Title: "Drop into Xcode",
      f3Body:
        "Export .xcstrings / .strings, plus JSON and CSV, with custom localize wrappers.",
      downloadTitle: "Download",
      downloadHeading: "Install and scan",
      downloadLede:
        "v1.1.0 · build 722d038 · Apple Silicon. If Gatekeeper blocks it, right-click Open or run the quarantine command below.",
      dlGuiTitle: "macOS GUI",
      dlGuiBody: "A .app for Applications",
      dlCliTitle: "CLI",
      dlCliBody: "stringscanner-cli for terminals and automation",
      dlAction: "Download .zip",
      cliKicker: "CLI",
      cliTitle: "Ready in three minutes",
      cliLede: "Unzip, chmod, scan any project folder.",
    },
  };

  const heroShot = document.getElementById("heroShot");
  const previewShot = document.getElementById("previewShot");
  const langButtons = document.querySelectorAll(".lang-switch [data-lang]");
  const shotTabs = document.querySelectorAll(".preview-tabs [data-shot]");

  function shotSrc(lang) {
    return lang === "en" ? "./images/app-en.png" : "./images/app-zh.png";
  }

  function applyLang(lang) {
    const dict = copy[lang] || copy.zh;
    document.documentElement.lang = lang === "en" ? "en" : "zh-Hans";
    document.title = dict.title;
    const desc = document.querySelector('meta[name="description"]');
    if (desc) desc.setAttribute("content", dict.description);

    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (key && dict[key] != null) el.textContent = dict[key];
    });
    document.querySelectorAll("[data-i18n-alt]").forEach((el) => {
      const key = el.getAttribute("data-i18n-alt");
      if (key && dict[key] != null) el.setAttribute("alt", dict[key]);
    });

    langButtons.forEach((btn) => {
      btn.classList.toggle("is-active", btn.getAttribute("data-lang") === lang);
    });

    setShot(lang);
    try {
      localStorage.setItem("ss-lang", lang);
    } catch (_) {}
  }

  function setShot(lang) {
    const src = shotSrc(lang);
    if (heroShot) heroShot.src = src;
    if (previewShot) previewShot.src = src;
    shotTabs.forEach((btn) => {
      const active = btn.getAttribute("data-shot") === lang;
      btn.classList.toggle("is-active", active);
      btn.setAttribute("aria-selected", active ? "true" : "false");
    });
  }

  langButtons.forEach((btn) => {
    btn.addEventListener("click", () => applyLang(btn.getAttribute("data-lang")));
  });

  shotTabs.forEach((btn) => {
    btn.addEventListener("click", () => applyLang(btn.getAttribute("data-shot")));
  });

  let initial = "zh";
  try {
    initial = localStorage.getItem("ss-lang") || initial;
  } catch (_) {}
  applyLang(initial);

  const nodes = document.querySelectorAll("[data-reveal]");
  if (!("IntersectionObserver" in window)) {
    nodes.forEach((el) => el.classList.add("in"));
    return;
  }

  const io = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          io.unobserve(entry.target);
        }
      }
    },
    { threshold: 0.12, rootMargin: "0px 0px -5% 0px" }
  );

  nodes.forEach((el, index) => {
    if (el.closest(".hero-copy") || el.classList.contains("hero-plane")) {
      el.style.transitionDelay = `${index * 80}ms`;
    }
    io.observe(el);
  });
})();
