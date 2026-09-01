(() => {
  "use strict";

  const DATA = window.GAMEPAY_DATA;
  if (!DATA || !Array.isArray(DATA.products)) {
    document.body.innerHTML = "<main style='padding:40px;font-family:sans-serif'>Unable to load the product catalog.</main>";
    return;
  }

  const STORAGE_KEY = "gamepay-order-draft-v2";
  const CATEGORY_GROUPS = {
    "AI & Productivity": ["AI"],
    Entertainment: ["Music", "Video", "Streaming"],
    "VPN & Security": ["VPN"],
    "Creative Tools": ["Editing"],
    "Social & Services": ["Social", "Services"],
    More: ["Gift", "Games"]
  };

  const state = {
    activeCategory: "All",
    search: "",
    productId: "",
    planIndex: 0,
    planFilter: "All",
    quantity: 1,
    customAmount: "",
    account: "",
    payment: "",
    note: "",
    orderReference: "",
    lastMessage: "",
    telegramOpened: true
  };

  const elements = {
    views: [...document.querySelectorAll("[data-view]")],
    searchInput: document.getElementById("searchInput"),
    categoryFilters: document.getElementById("categoryFilters"),
    resultCount: document.getElementById("resultCount"),
    productGrid: document.getElementById("productGrid"),
    emptyState: document.getElementById("emptyState"),
    clearFiltersButton: document.getElementById("clearFiltersButton"),
    breadcrumbProduct: document.getElementById("breadcrumbProduct"),
    productArtwork: document.getElementById("productArtwork"),
    productCategory: document.getElementById("productCategory"),
    productTitle: document.getElementById("productTitle"),
    productDescription: document.getElementById("productDescription"),
    productStock: document.getElementById("productStock"),
    productStartingPrice: document.getElementById("productStartingPrice"),
    planFilters: document.getElementById("planFilters"),
    planGrid: document.getElementById("planGrid"),
    customAmountPanel: document.getElementById("customAmountPanel"),
    customAmountLabel: document.getElementById("customAmountLabel"),
    customAmountInput: document.getElementById("customAmountInput"),
    customAmountHint: document.getElementById("customAmountHint"),
    quantityPanel: document.getElementById("quantityPanel"),
    decreaseQuantity: document.getElementById("decreaseQuantity"),
    increaseQuantity: document.getElementById("increaseQuantity"),
    quantityOutput: document.getElementById("quantityOutput"),
    productTotal: document.getElementById("productTotal"),
    continueToCheckout: document.getElementById("continueToCheckout"),
    checkoutForm: document.getElementById("checkoutForm"),
    backToProduct: document.getElementById("backToProduct"),
    accountLabel: document.getElementById("accountLabel"),
    accountInput: document.getElementById("accountInput"),
    accountHint: document.getElementById("accountHint"),
    accountError: document.getElementById("accountError"),
    paymentGrid: document.getElementById("paymentGrid"),
    paymentError: document.getElementById("paymentError"),
    paymentDetails: document.getElementById("paymentDetails"),
    paymentDetailsLabel: document.getElementById("paymentDetailsLabel"),
    paymentNumber: document.getElementById("paymentNumber"),
    paymentName: document.getElementById("paymentName"),
    copyPaymentButton: document.getElementById("copyPaymentButton"),
    noteInput: document.getElementById("noteInput"),
    noteCount: document.getElementById("noteCount"),
    checkoutSummaryContent: document.getElementById("checkoutSummaryContent"),
    reviewContent: document.getElementById("reviewContent"),
    editOrderButton: document.getElementById("editOrderButton"),
    sendTelegramButton: document.getElementById("sendTelegramButton"),
    orderReference: document.getElementById("orderReference"),
    copyReferenceButton: document.getElementById("copyReferenceButton"),
    copyOrderAgainButton: document.getElementById("copyOrderAgainButton"),
    telegramFallback: document.getElementById("telegramFallback"),
    telegramFallbackLink: document.getElementById("telegramFallbackLink"),
    toast: document.getElementById("toast")
  };

  let toastTimer = 0;

  function escapeHTML(value) {
    return String(value ?? "").replace(/[&<>"']/g, character => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;"
    })[character]);
  }

  function formatKs(value) {
    return `${Math.max(0, Number(value) || 0).toLocaleString("en-US")} Ks`;
  }

  function initials(name) {
    return String(name || "GP")
      .replace(/[^A-Za-z0-9 ]/g, " ")
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map(part => part[0] || "")
      .join("")
      .toUpperCase() || "GP";
  }

  function assetURL(path) {
    if (!path) return "";
    if (/^(data:|https?:|\/)/i.test(path)) return path;
    return `assets/${path}`;
  }

  function imageMarkup(path, alt, className = "") {
    const label = escapeHTML(alt);
    if (!path) return `<span class="image-fallback ${className}" aria-hidden="true">${initials(alt)}</span>`;
    return `<img class="${escapeHTML(className)}" src="${escapeHTML(assetURL(path))}" alt="${label}" loading="lazy" decoding="async" data-fallback="${escapeHTML(initials(alt))}">`;
  }

  function applyImageFallbacks(scope = document) {
    scope.querySelectorAll("img[data-fallback]").forEach(image => {
      image.addEventListener("error", () => {
        const fallback = document.createElement("span");
        fallback.className = "image-fallback";
        fallback.setAttribute("aria-hidden", "true");
        fallback.textContent = image.dataset.fallback || "GP";
        image.replaceWith(fallback);
      }, { once: true });
    });
  }

  function showToast(message, type = "success") {
    window.clearTimeout(toastTimer);
    elements.toast.textContent = message;
    elements.toast.classList.toggle("error", type === "error");
    elements.toast.classList.add("show");
    toastTimer = window.setTimeout(() => elements.toast.classList.remove("show"), 2600);
  }

  function saveDraft() {
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (_) {
      // The store still works when browser storage is unavailable.
    }
  }

  function restoreDraft() {
    try {
      const saved = JSON.parse(sessionStorage.getItem(STORAGE_KEY) || "null");
      if (!saved || typeof saved !== "object") return;
      Object.keys(state).forEach(key => {
        if (Object.prototype.hasOwnProperty.call(saved, key)) state[key] = saved[key];
      });
    } catch (_) {
      sessionStorage.removeItem(STORAGE_KEY);
    }
  }

  function currentProduct() {
    return DATA.products.find(product => product.id === state.productId) || null;
  }

  function selectedPlan() {
    const product = currentProduct();
    return product?.plans?.[state.planIndex] || null;
  }

  function availablePlanIndex(product) {
    const index = product?.plans?.findIndex(plan => !plan.outOfStock) ?? -1;
    return Math.max(0, index);
  }

  function getCheapestPrice(product) {
    const prices = product.plans
      .filter(plan => !plan.outOfStock && Number(plan.price) > 0)
      .map(plan => Number(plan.price));
    return prices.length ? Math.min(...prices) : 0;
  }

  function cleanPlanName(plan) {
    const raw = String(plan?.name || "Digital plan").replace(/\\n/g, "\n");
    const withoutPrice = raw.replace(/\s*[–—-]?\s*[0-9][0-9,]*\s*(?:ks|ကျပ်).*$/i, "").trim();
    return plan?.label || withoutPrice || raw;
  }

  function planDuration(plan) {
    if (plan?.noDuration) return "No duration";
    if (plan?.duration) return plan.duration;
    const match = cleanPlanName(plan).match(/(\d+\s*(?:minute|minutes|min|mins|hour|hours|day|days|week|weeks|month|months|year|years))/i);
    return match ? match[1] : (plan?.outOfStock ? "Preorder" : "Standard");
  }

  function planType(plan) {
    const source = `${plan?.type || ""} ${plan?.format || ""} ${plan?.name || ""}`;
    if (plan?.ownMail || /own[- ]?mail|invite/i.test(source)) return "Own Mail";
    if (/private/i.test(source)) return "Private";
    if (/share/i.test(source)) return "Share";
    if (/credit/i.test(source)) return "Credits";
    if (/code|redeem|key/i.test(source)) return "Code";
    return "Standard";
  }

  function planPrice(plan) {
    if (!plan) return 0;
    if (plan.custom) {
      const amount = Number(state.customAmount);
      const base = Number(plan.baseAmount || 1);
      if (!amount || amount < customMinimum(plan)) return 0;
      return Math.ceil((amount / base) * Number(plan.price || 0));
    }
    return Number(plan.price || 0) * Math.max(1, Number(state.quantity) || 1);
  }

  function customMinimum(plan) {
    const product = currentProduct();
    if (plan?.unit === "USD Promote") return 1;
    if (plan?.unit === "Coins") return Math.max(100, Number(plan.minAmount || 0));
    return Number(plan?.minAmount || product?.minAmount || plan?.baseAmount || 1);
  }

  function customAmountError() {
    const plan = selectedPlan();
    if (!plan?.custom) return "";
    const amount = Number(state.customAmount);
    const minimum = customMinimum(plan);
    if (!amount) return `Enter an amount. Minimum: ${minimum} ${plan.unit || ""}`.trim();
    if (amount < minimum) return `Minimum: ${minimum} ${plan.unit || ""}`.trim();
    return "";
  }

  function accountSpecification(product) {
    const source = `${product?.id || ""} ${product?.name || ""} ${product?.category || ""} ${product?.search || ""}`.toLowerCase();
    if (/game|topup|top-up|diamond|uc|genshin|pubg|mobile legend|valorant|roblox/.test(source)) {
      return { label: "Player ID / Game account", placeholder: "Enter Player ID or game account", hint: "Include the server or zone in the note when required." };
    }
    if (/gift|visa|mastercard|steam|itunes|google play/.test(source)) {
      return { label: "Delivery email", placeholder: "Enter the email that should receive the code", hint: "Double-check the email before reviewing the order." };
    }
    if (/telegram|social|facebook|instagram|tiktok|twitter|youtube service/.test(source)) {
      return { label: "Username / Profile link", placeholder: "Enter username or profile link", hint: "Use the exact account that should receive the service." };
    }
    return { label: "Account email / Username", placeholder: "Enter account email or username", hint: "Use the account that should receive this product." };
  }

  function productStatus(product) {
    const available = product.plans.filter(plan => !plan.outOfStock).length;
    if (!available) return { label: "Coming soon", className: "out" };
    if (available < product.plans.length) return { label: "Limited availability", className: "limited" };
    return { label: "Available", className: "" };
  }

  function groupedCategoryMatch(product, category) {
    if (category === "All") return true;
    const accepted = CATEGORY_GROUPS[category] || [category];
    return accepted.includes(product.category);
  }

  function routeFor(name) {
    const clean = String(name || "home").replace(/^#\/?/, "");
    return clean || "home";
  }

  function navigate(route, replace = false) {
    const target = `#/${routeFor(route)}`;
    if (window.location.hash === target) {
      renderRoute();
      return;
    }
    if (replace) history.replaceState(null, "", target);
    else history.pushState(null, "", target);
    renderRoute();
  }

  function resolvedRoute() {
    return routeFor(window.location.hash);
  }

  function showView(name) {
    elements.views.forEach(view => {
      const active = view.dataset.view === name;
      view.hidden = !active;
      view.setAttribute("aria-hidden", String(!active));
    });
    window.scrollTo({ top: 0, behavior: "auto" });
  }

  function renderRoute() {
    const route = resolvedRoute();
    const [section, id] = route.split("/");

    if (section === "product" && id) {
      const product = DATA.products.find(item => item.id === id);
      if (!product) return navigate("products", true);
      if (state.productId !== id) selectProduct(product, false);
      showView("product");
      renderProductPage();
    } else if (section === "checkout") {
      if (!currentProduct()) return navigate("products", true);
      if (customAmountError()) return navigate(`product/${state.productId}`, true);
      showView("checkout");
      renderCheckout();
    } else if (section === "review") {
      if (!currentProduct()) return navigate("products", true);
      if (!validateCheckout(false)) return navigate("checkout", true);
      showView("review");
      renderReview();
    } else if (section === "success") {
      if (!state.lastMessage || !state.orderReference) return navigate("products", true);
      showView("success");
      renderSuccess();
    } else if (section === "products") {
      showView("products");
      renderCatalog();
    } else {
      showView("home");
    }

    saveDraft();
  }

  function renderCategoryFilters() {
    elements.categoryFilters.innerHTML = DATA.categories.map(category => `
      <button class="filter-chip ${state.activeCategory === category ? "active" : ""}" type="button" data-category="${escapeHTML(category)}" aria-pressed="${state.activeCategory === category}">${escapeHTML(category)}</button>
    `).join("");
  }

  function filteredProducts() {
    const query = state.search.trim().toLowerCase();
    return DATA.products.filter(product => {
      if (product.isGuide) return false;
      const categoryMatch = groupedCategoryMatch(product, state.activeCategory);
      const searchable = `${product.name} ${product.search || ""} ${product.category || ""}`.toLowerCase();
      return categoryMatch && (!query || searchable.includes(query));
    });
  }

  function renderCatalog() {
    elements.searchInput.value = state.search;
    renderCategoryFilters();
    const products = filteredProducts();
    elements.resultCount.textContent = `${products.length} product${products.length === 1 ? "" : "s"} found`;
    elements.emptyState.hidden = products.length > 0;
    elements.productGrid.hidden = products.length === 0;

    elements.productGrid.innerHTML = products.map(product => {
      const status = productStatus(product);
      const price = getCheapestPrice(product);
      return `
        <article class="product-card">
          ${product.top ? '<span class="popular-badge">Popular</span>' : ""}
          <button class="product-card-main" type="button" data-product-id="${escapeHTML(product.id)}" aria-label="View ${escapeHTML(product.name)} plans">
            <span class="product-logo">${imageMarkup(product.icon, product.name)}</span>
            <span class="product-card-category">${escapeHTML(product.category || "Digital")}</span>
            <h2>${escapeHTML(product.name)}</h2>
            <span class="product-price"><span>${price ? "Plans from" : "Price"}</span><strong>${price ? formatKs(price) : "Ask support"}</strong></span>
            <span class="product-card-meta"><i class="status-dot ${status.className}" aria-hidden="true"></i>${product.plans.length} plan${product.plans.length === 1 ? "" : "s"} · ${status.label}</span>
          </button>
          <button class="product-card-action" type="button" data-product-id="${escapeHTML(product.id)}">View plans</button>
        </article>`;
    }).join("");
    applyImageFallbacks(elements.productGrid);
  }

  function selectProduct(product, resetRoute = true) {
    state.productId = product.id;
    state.planIndex = availablePlanIndex(product);
    state.planFilter = "All";
    state.quantity = 1;
    state.customAmount = "";
    state.account = "";
    state.payment = "";
    state.note = "";
    state.orderReference = "";
    state.lastMessage = "";
    if (resetRoute) navigate(`product/${product.id}`);
  }

  function relevantPlanFilters(product) {
    const types = [...new Set(product.plans.map(planType))];
    return types.length > 1 ? ["All", ...types] : [];
  }

  function renderPlanFilters(product) {
    const filters = relevantPlanFilters(product);
    if (filters.length && !filters.includes(state.planFilter)) state.planFilter = "All";
    elements.planFilters.innerHTML = filters.map(filter => `
      <button class="filter-chip ${state.planFilter === filter ? "active" : ""}" type="button" data-plan-filter="${escapeHTML(filter)}" aria-pressed="${state.planFilter === filter}">${escapeHTML(filter)}</button>
    `).join("");
  }

  function renderProductPage() {
    const product = currentProduct();
    if (!product) return;
    const status = productStatus(product);
    const price = getCheapestPrice(product);

    elements.breadcrumbProduct.textContent = product.name;
    elements.productCategory.textContent = product.category || "Digital product";
    elements.productTitle.textContent = product.name;
    elements.productDescription.textContent = product.description || product.note || "Choose a plan to view the available ordering options.";
    elements.productStock.textContent = status.label;
    elements.productStock.className = `stock-badge ${status.className === "out" ? "out" : ""}`;
    elements.productStartingPrice.textContent = price ? `From ${formatKs(price)}` : "Contact support for price";
    elements.productArtwork.innerHTML = `<span class="product-logo">${imageMarkup(product.icon, product.name)}</span>`;
    applyImageFallbacks(elements.productArtwork);

    renderPlanFilters(product);
    const visiblePlans = product.plans
      .map((plan, index) => ({ plan, index }))
      .filter(({ plan }) => state.planFilter === "All" || planType(plan) === state.planFilter);

    elements.planGrid.innerHTML = visiblePlans.map(({ plan, index }) => `
      <button class="plan-card" type="button" role="radio" aria-checked="${index === state.planIndex}" data-plan-index="${index}" ${plan.outOfStock ? "disabled" : ""}>
        <span class="plan-card-top"><strong class="plan-card-name">${escapeHTML(cleanPlanName(plan))}</strong>${plan.bestSeller ? '<span class="plan-card-badge">Best seller</span>' : plan.discount ? '<span class="plan-card-badge">Discount</span>' : plan.outOfStock ? '<span class="plan-card-badge">Out of stock</span>' : ""}</span>
        <span class="plan-card-meta"><span>Type<strong>${escapeHTML(planType(plan))}</strong></span><span>Duration<strong>${escapeHTML(planDuration(plan))}</strong></span></span>
        <strong class="plan-card-price">${plan.custom ? "Custom price" : Number(plan.price) ? formatKs(plan.price) : "Ask support"}</strong>
      </button>
    `).join("");

    renderProductControls();
  }

  function renderProductControls() {
    const plan = selectedPlan();
    if (!plan) return;
    const isCustom = Boolean(plan.custom);
    elements.customAmountPanel.hidden = !isCustom;
    elements.quantityPanel.hidden = isCustom;

    if (isCustom) {
      const minimum = customMinimum(plan);
      elements.customAmountLabel.textContent = `Enter ${plan.unit || "amount"}`;
      elements.customAmountInput.min = String(minimum);
      elements.customAmountInput.step = String(Number(plan.baseAmount || 1));
      elements.customAmountInput.placeholder = `Minimum ${minimum}`;
      elements.customAmountInput.value = state.customAmount;
      const error = customAmountError();
      elements.customAmountHint.textContent = error || `Minimum ${minimum} ${plan.unit || ""} · Rate ${formatKs(plan.price)} per ${plan.baseAmount || 1} ${plan.unit || ""}`;
      elements.customAmountHint.classList.toggle("error", Boolean(error));
    }

    elements.quantityOutput.value = String(state.quantity);
    elements.quantityOutput.textContent = String(state.quantity);
    elements.decreaseQuantity.disabled = state.quantity <= 1;
    elements.productTotal.textContent = planPrice(plan) ? formatKs(planPrice(plan)) : "—";
    elements.continueToCheckout.disabled = Boolean(plan.outOfStock || customAmountError());
  }

  function renderCheckout() {
    const product = currentProduct();
    const specification = accountSpecification(product);
    elements.accountLabel.textContent = specification.label;
    elements.accountInput.placeholder = specification.placeholder;
    elements.accountHint.textContent = specification.hint;
    elements.accountInput.value = state.account;
    elements.noteInput.value = state.note;
    elements.noteCount.textContent = String(state.note.length);
    elements.accountError.textContent = "";
    elements.accountInput.closest(".form-field").classList.remove("invalid");
    elements.paymentError.textContent = "";
    renderPayments();
    renderSummary();
  }

  function renderPayments() {
    elements.paymentGrid.innerHTML = DATA.paymentMethods.map(method => {
      const meta = DATA.paymentMeta[method] || { label: method, logo: "" };
      return `
        <button class="payment-option" type="button" role="radio" aria-checked="${state.payment === method}" data-payment="${escapeHTML(method)}">
          ${imageMarkup(meta.logo, meta.label)}
          <span>${escapeHTML(meta.label)}</span>
        </button>`;
    }).join("");
    applyImageFallbacks(elements.paymentGrid);
    renderPaymentDetails();
  }

  function renderPaymentDetails() {
    if (!state.payment) {
      elements.paymentDetails.hidden = true;
      return;
    }
    const meta = DATA.paymentMeta[state.payment] || { label: state.payment };
    const account = DATA.paymentAccounts[state.payment];
    elements.paymentDetails.hidden = false;
    elements.paymentDetailsLabel.textContent = meta.label;
    elements.paymentNumber.textContent = account?.phone || "Confirm in Telegram";
    elements.paymentName.textContent = account?.name || "Support will provide the correct account";
    elements.copyPaymentButton.hidden = !account?.phone;
    elements.copyPaymentButton.disabled = !account?.phone;
  }

  function summaryRows() {
    const product = currentProduct();
    const plan = selectedPlan();
    return [
      ["Plan", cleanPlanName(plan)],
      [plan?.custom ? "Custom amount" : "Quantity", plan?.custom ? `${state.customAmount} ${plan.unit || ""}`.trim() : state.quantity],
      ["Payment", state.payment ? (DATA.paymentMeta[state.payment]?.label || state.payment) : "Not selected"]
    ];
  }

  function renderSummary() {
    const product = currentProduct();
    const plan = selectedPlan();
    if (!product || !plan) return;
    const rows = summaryRows();
    elements.checkoutSummaryContent.innerHTML = `
      <div class="summary-product"><span class="product-logo">${imageMarkup(product.icon, product.name)}</span><div><strong>${escapeHTML(product.name)}</strong><span>${escapeHTML(cleanPlanName(plan))}</span></div></div>
      <div class="summary-lines">
        ${rows.map(([label, value]) => `<div class="summary-line"><span>${escapeHTML(label)}</span><strong>${escapeHTML(value)}</strong></div>`).join("")}
        <div class="summary-line total"><span>Total</span><strong>${formatKs(planPrice(plan))}</strong></div>
      </div>`;
    applyImageFallbacks(elements.checkoutSummaryContent);
  }

  function validateCheckout(showErrors = true) {
    const account = state.account.trim();
    const accountInvalid = account.length < 3;
    const paymentInvalid = !state.payment;
    const customInvalid = Boolean(customAmountError());

    if (showErrors) {
      elements.accountError.textContent = accountInvalid ? "Please enter the required account information." : "";
      elements.accountInput.closest(".form-field").classList.toggle("invalid", accountInvalid);
      elements.paymentError.textContent = paymentInvalid ? "Please select a payment method." : "";
      if (accountInvalid) elements.accountInput.focus();
      else if (paymentInvalid) elements.paymentGrid.querySelector("button")?.focus();
    }
    return !accountInvalid && !paymentInvalid && !customInvalid && Boolean(currentProduct() && selectedPlan());
  }

  function generateReference() {
    const date = new Date();
    const datePart = [date.getFullYear().toString().slice(-2), String(date.getMonth() + 1).padStart(2, "0"), String(date.getDate()).padStart(2, "0")].join("");
    const timePart = [String(date.getHours()).padStart(2, "0"), String(date.getMinutes()).padStart(2, "0")].join("");
    const random = Math.floor(100 + Math.random() * 900);
    return `GPH-${datePart}-${timePart}-${random}`;
  }

  function buildOrderMessage() {
    const product = currentProduct();
    const plan = selectedPlan();
    if (!product || !plan) return "";
    const paymentLabel = DATA.paymentMeta[state.payment]?.label || state.payment;
    const paymentAccount = DATA.paymentAccounts[state.payment];
    const lines = [
      "GAMEPAY HUB — DIGITAL ORDER",
      "────────────────────",
      `Reference: ${state.orderReference}`,
      `Product: ${product.name}`,
      `Plan: ${cleanPlanName(plan)}`,
      plan.custom ? `Custom amount: ${state.customAmount} ${plan.unit || ""}`.trim() : `Quantity: ${state.quantity}`,
      `Account: ${state.account.trim()}`,
      `Payment: ${paymentLabel}`,
      paymentAccount?.phone ? `Payment number: ${paymentAccount.phone}` : "Payment number: Confirm with support",
      `Total: ${formatKs(planPrice(plan))}`
    ];
    if (state.note.trim()) lines.push(`Note: ${state.note.trim()}`);
    lines.push("────────────────────", "Please confirm stock and the payment step before processing.");
    return lines.join("\n");
  }

  function renderReview() {
    if (!state.orderReference) state.orderReference = generateReference();
    const product = currentProduct();
    const plan = selectedPlan();
    const paymentLabel = DATA.paymentMeta[state.payment]?.label || state.payment;
    const rows = [
      ["Reference", state.orderReference],
      ["Product", product.name],
      ["Plan", cleanPlanName(plan)],
      [plan.custom ? "Custom amount" : "Quantity", plan.custom ? `${state.customAmount} ${plan.unit || ""}`.trim() : state.quantity],
      ["Account", state.account.trim()],
      ["Payment", paymentLabel],
      ...(state.note.trim() ? [["Note", state.note.trim()]] : []),
      ["Total", formatKs(planPrice(plan)), "total"]
    ];
    elements.reviewContent.innerHTML = rows.map(([label, value, className = ""]) => `<div class="review-row ${className}"><span>${escapeHTML(label)}</span><strong>${escapeHTML(value)}</strong></div>`).join("");
    saveDraft();
  }

  function renderSuccess() {
    elements.orderReference.textContent = state.orderReference;
    elements.telegramFallback.hidden = state.telegramOpened;
    const url = telegramURL(state.lastMessage);
    elements.telegramFallbackLink.href = url;
  }

  function telegramURL(message) {
    const username = String(DATA.telegramUsername || "").replace(/^@/, "");
    return `https://t.me/${encodeURIComponent(username)}?text=${encodeURIComponent(message)}`;
  }

  async function copyText(text) {
    if (!text) return false;
    try {
      if (navigator.clipboard?.writeText && window.isSecureContext) {
        await navigator.clipboard.writeText(text);
        return true;
      }
      const textarea = document.createElement("textarea");
      textarea.value = text;
      textarea.setAttribute("readonly", "");
      textarea.style.position = "fixed";
      textarea.style.opacity = "0";
      document.body.appendChild(textarea);
      textarea.select();
      const copied = document.execCommand("copy");
      textarea.remove();
      return copied;
    } catch (_) {
      return false;
    }
  }

  async function prepareTelegramOrder() {
    if (!validateCheckout(false)) {
      navigate("checkout");
      return;
    }
    if (!state.orderReference) state.orderReference = generateReference();
    const message = buildOrderMessage();
    state.lastMessage = message;
    const url = telegramURL(message);

    const telegramWindow = window.open(url, "_blank");
    if (telegramWindow) telegramWindow.opener = null;
    state.telegramOpened = Boolean(telegramWindow);

    const copied = await copyText(message);
    showToast(copied ? "Order copied. Paste and send it in Telegram." : "Telegram opened. Copy the order again if the message is empty.", copied ? "success" : "error");
    saveDraft();
    navigate("success");
  }

  document.addEventListener("click", event => {
    const routeControl = event.target.closest("[data-route]");
    if (routeControl) {
      event.preventDefault();
      navigate(routeControl.dataset.route);
      return;
    }

    const productControl = event.target.closest("[data-product-id]");
    if (productControl) {
      const product = DATA.products.find(item => item.id === productControl.dataset.productId);
      if (product) selectProduct(product);
      return;
    }

    const categoryControl = event.target.closest("[data-category]");
    if (categoryControl) {
      state.activeCategory = categoryControl.dataset.category;
      renderCatalog();
      saveDraft();
      return;
    }

    const filterControl = event.target.closest("[data-plan-filter]");
    if (filterControl) {
      state.planFilter = filterControl.dataset.planFilter;
      const product = currentProduct();
      const activePlan = selectedPlan();
      if (product && state.planFilter !== "All" && planType(activePlan) !== state.planFilter) {
        const nextIndex = product.plans.findIndex(plan => !plan.outOfStock && planType(plan) === state.planFilter);
        if (nextIndex >= 0) {
          state.planIndex = nextIndex;
          state.quantity = 1;
          state.customAmount = "";
          state.orderReference = "";
        }
      }
      renderProductPage();
      saveDraft();
      return;
    }

    const planControl = event.target.closest("[data-plan-index]");
    if (planControl && !planControl.disabled) {
      state.planIndex = Number(planControl.dataset.planIndex);
      state.quantity = 1;
      state.customAmount = "";
      state.orderReference = "";
      renderProductPage();
      saveDraft();
      return;
    }

    const paymentControl = event.target.closest("[data-payment]");
    if (paymentControl) {
      state.payment = paymentControl.dataset.payment;
      elements.paymentError.textContent = "";
      renderPayments();
      renderSummary();
      saveDraft();
    }
  });

  elements.searchInput.addEventListener("input", () => {
    state.search = elements.searchInput.value;
    renderCatalog();
    saveDraft();
  });

  elements.clearFiltersButton.addEventListener("click", () => {
    state.search = "";
    state.activeCategory = "All";
    renderCatalog();
    elements.searchInput.focus();
    saveDraft();
  });

  elements.customAmountInput.addEventListener("input", () => {
    state.customAmount = elements.customAmountInput.value;
    renderProductControls();
    saveDraft();
  });

  elements.decreaseQuantity.addEventListener("click", () => {
    state.quantity = Math.max(1, state.quantity - 1);
    renderProductControls();
    saveDraft();
  });

  elements.increaseQuantity.addEventListener("click", () => {
    state.quantity += 1;
    renderProductControls();
    saveDraft();
  });

  elements.continueToCheckout.addEventListener("click", () => {
    const error = customAmountError();
    if (error) {
      showToast(error, "error");
      elements.customAmountInput.focus();
      return;
    }
    navigate("checkout");
  });

  elements.backToProduct.addEventListener("click", () => navigate(`product/${state.productId}`));

  elements.accountInput.addEventListener("input", () => {
    state.account = elements.accountInput.value;
    elements.accountError.textContent = "";
    elements.accountInput.closest(".form-field").classList.remove("invalid");
    saveDraft();
  });

  elements.noteInput.addEventListener("input", () => {
    state.note = elements.noteInput.value.slice(0, 500);
    elements.noteCount.textContent = String(state.note.length);
    saveDraft();
  });

  elements.copyPaymentButton.addEventListener("click", async () => {
    const number = DATA.paymentAccounts[state.payment]?.phone;
    const copied = await copyText(number || "");
    showToast(copied ? "Payment number copied." : "Unable to copy the payment number.", copied ? "success" : "error");
  });

  elements.checkoutForm.addEventListener("submit", event => {
    event.preventDefault();
    state.account = elements.accountInput.value;
    state.note = elements.noteInput.value;
    if (!validateCheckout(true)) return;
    if (!state.orderReference) state.orderReference = generateReference();
    saveDraft();
    navigate("review");
  });

  elements.editOrderButton.addEventListener("click", () => navigate("checkout"));
  elements.sendTelegramButton.addEventListener("click", prepareTelegramOrder);

  elements.copyReferenceButton.addEventListener("click", async () => {
    const copied = await copyText(state.orderReference);
    showToast(copied ? "Reference ID copied." : "Unable to copy the reference ID.", copied ? "success" : "error");
  });

  elements.copyOrderAgainButton.addEventListener("click", async () => {
    const copied = await copyText(state.lastMessage);
    showToast(copied ? "Order copied again." : "Unable to copy the order.", copied ? "success" : "error");
  });

  window.addEventListener("popstate", renderRoute);
  window.addEventListener("hashchange", renderRoute);

  document.getElementById("currentYear").textContent = String(new Date().getFullYear());
  restoreDraft();
  if (!window.location.hash) navigate("home", true);
  else renderRoute();
})();
