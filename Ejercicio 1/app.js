"use strict";

// Referencias a los controles y a los resultados de la interfaz.
const billInput = document.querySelector("#bill-amount");
const peopleInput = document.querySelector("#people-count");
const currencySelect = document.querySelector("#currency-select");
const inputCurrencyCode = document.querySelector("#input-currency-code");
const inputCurrencySymbol = document.querySelector("#input-currency-symbol");
const amountHint = document.querySelector("#amount-hint");
const tipButtons = [...document.querySelectorAll(".tip-button")];
const tipTotal = document.querySelector("#tip-total");
const grandTotal = document.querySelector("#grand-total");
const perPersonTotal = document.querySelector("#per-person-total");
const tipRateLabel = document.querySelector("#tip-rate-label");
const splitNote = document.querySelector("#split-note");
const billError = document.querySelector("#bill-error");
const peopleError = document.querySelector("#people-error");

// Tasas fijas de demostración expresadas como unidades de moneda por cada USD.
// Actualiza estos valores manualmente si necesitas otra referencia; no son tasas en tiempo real.
const exchangeRates = {
  USD: 1,
  EUR: 0.92,
  MXN: 18,
  COP: 4200,
  CAD: 1.36,
  GBP: 0.79,
  JPY: 150,
};

// Locales que ayudan a mostrar el símbolo de cada moneda de forma familiar.
const currencyLocales = {
  USD: "es-US",
  EUR: "es-ES",
  MXN: "es-MX",
  COP: "es-CO",
  CAD: "en-CA",
  GBP: "en-GB",
  JPY: "ja-JP",
};

// Símbolos con prefijo de país cuando varias monedas comparten el signo de dólar.
const currencySymbols = {
  USD: "$",
  EUR: "€",
  MXN: "MX$",
  COP: "COL$",
  CAD: "CA$",
  GBP: "£",
  JPY: "¥",
};

// Estado local del porcentaje elegido y de la moneda de entrada y presentación.
let selectedTip = 15;
let selectedCurrency = currencySelect.value;
let currencyFormatter = createCurrencyFormatter(selectedCurrency);

// Crea el formato monetario asociado a la moneda seleccionada.
function createCurrencyFormatter(currency) {
  return new Intl.NumberFormat(currencyLocales[currency], {
    style: "currency",
    currency,
    currencyDisplay: ["MXN", "COP", "CAD"].includes(currency) ? "code" : "symbol",
  });
}

// Formatea una cantidad para el campo de entrada sin separadores de miles.
function formatInputAmount(amount) {
  return new Intl.NumberFormat(currencyLocales[selectedCurrency], {
    useGrouping: false,
    maximumFractionDigits: 6,
  }).format(amount);
}

// Actualiza el código, el símbolo y la ayuda del campo de entrada.
function updateInputCurrency() {
  inputCurrencyCode.textContent = selectedCurrency;
  inputCurrencySymbol.textContent = currencySymbols[selectedCurrency];
  amountHint.textContent = `Ingresa el monto en ${selectedCurrency}; los resultados se muestran en la misma moneda.`;
}

// Convierte el texto de la cuenta en un número; acepta punto o coma decimal.
function parseBillAmount(value) {
  const normalizedValue = value.trim().replace(",", ".");
  if (!normalizedValue || !/^(?:\d+(?:\.\d*)?|\.\d+)$/.test(normalizedValue)) {
    return null;
  }

  const amount = Number(normalizedValue);
  return Number.isFinite(amount) ? amount : null;
}

// Conserva solo dígitos y un único separador decimal en el campo del monto.
function sanitizeBillInput(value) {
  let cleanedValue = "";
  let hasDecimalSeparator = false;

  for (const character of value) {
    if (character >= "0" && character <= "9") {
      cleanedValue += character;
    } else if ((character === "." || character === ",") && !hasDecimalSeparator) {
      cleanedValue += character;
      hasDecimalSeparator = true;
    }
  }

  return cleanedValue;
}

// Calcula la propina y el total por persona sin aplicar conversión de moneda.
function calculateTip(bill, tipPercentage, people) {
  const tip = bill * (tipPercentage / 100);
  const total = bill + tip;
  return {
    tip,
    total,
    perPerson: total / people,
  };
}

// Convierte el monto ingresado en la moneda seleccionada a la cantidad base en USD.
function convertToUsd(amountInSelectedCurrency) {
  return amountInSelectedCurrency / exchangeRates[selectedCurrency];
}

// Convierte una cantidad base en USD a la moneda seleccionada y la formatea.
function formatCurrency(amountInUsd) {
  return currencyFormatter.format(amountInUsd * exchangeRates[selectedCurrency]);
}

// Actualiza errores, etiquetas y resultados cuando cambia cualquier entrada.
function renderResults() {
  const amount = parseBillAmount(billInput.value);
  const people = Number(peopleInput.value);
  const hasAmount = amount !== null;
  const hasValidPeople = Number.isInteger(people) && people > 0;

  billError.textContent =
    billInput.value.trim() && !hasAmount
      ? "Escribe un monto válido, por ejemplo 42.50."
      : "";
  peopleError.textContent = hasValidPeople
    ? ""
    : "El número de personas debe ser un entero mayor que cero.";
  billInput.setAttribute("aria-invalid", String(Boolean(billError.textContent)));
  peopleInput.setAttribute("aria-invalid", String(Boolean(peopleError.textContent)));
  tipRateLabel.textContent = `(${selectedTip}%)`;

  if (!hasAmount || !hasValidPeople) {
    tipTotal.textContent = "$—";
    grandTotal.textContent = "$—";
    perPersonTotal.textContent = "$—";
    splitNote.textContent = !hasAmount
      ? "Ingresa el total para comenzar"
      : "Ingresa un número válido de personas";
    return;
  }

  const amountInUsd = convertToUsd(amount);
  const result = calculateTip(amountInUsd, selectedTip, people);
  tipTotal.textContent = formatCurrency(result.tip);
  grandTotal.textContent = formatCurrency(result.total);
  perPersonTotal.textContent = formatCurrency(result.perPerson);
  splitNote.textContent = `Dividido entre ${people} ${people === 1 ? "persona" : "personas"}`;
}

// Cambia la moneda del campo y conserva el valor económico de la cuenta.
function updateCurrency() {
  const previousCurrency = selectedCurrency;
  const amount = parseBillAmount(billInput.value);
  selectedCurrency = currencySelect.value;
  currencyFormatter = createCurrencyFormatter(selectedCurrency);
  if (amount !== null) {
    const amountInUsd = amount / exchangeRates[previousCurrency];
    billInput.value = formatInputAmount(amountInUsd * exchangeRates[selectedCurrency]);
  }
  updateInputCurrency();
  renderResults();
}

// Evita que se escriban letras, símbolos o un segundo separador decimal en la cuenta.
function handleBillBeforeInput(event) {
  if (!event.inputType.startsWith("insert") || event.data === null) {
    return;
  }

  const start = billInput.selectionStart ?? billInput.value.length;
  const end = billInput.selectionEnd ?? billInput.value.length;
  const proposedValue =
    billInput.value.slice(0, start) + event.data + billInput.value.slice(end);

  if (sanitizeBillInput(proposedValue) !== proposedValue) {
    event.preventDefault();
  }
}

// Limpia entradas que el navegador introduzca sin pasar por beforeinput, como pegados.
function handleBillInput() {
  const sanitizedValue = sanitizeBillInput(billInput.value);
  if (sanitizedValue !== billInput.value) {
    billInput.value = sanitizedValue;
  }
  renderResults();
}

// Limita el campo de personas a dígitos enteros y vuelve a calcular.
function handlePeopleInput() {
  const digitsOnly = peopleInput.value.replace(/\D/g, "");
  if (digitsOnly !== peopleInput.value) {
    peopleInput.value = digitsOnly;
  }
  renderResults();
}

// Cambia el número de personas y mantiene siempre un valor mínimo de uno.
function changePeopleCount(amount) {
  const people = Number(peopleInput.value);
  const currentPeople = Number.isInteger(people) && people > 0 ? people : 1;
  peopleInput.value = String(Math.max(1, currentPeople + amount));
  renderResults();
}

// Eventos de los campos, el selector de moneda y los botones de porcentaje.
billInput.addEventListener("beforeinput", handleBillBeforeInput);
billInput.addEventListener("input", handleBillInput);
peopleInput.addEventListener("beforeinput", (event) => {
  if (event.inputType.startsWith("insert") && event.data !== null && !/^\d+$/.test(event.data)) {
    event.preventDefault();
  }
});
peopleInput.addEventListener("input", handlePeopleInput);
currencySelect.addEventListener("change", updateCurrency);

tipButtons.forEach((button) => {
  button.addEventListener("click", () => {
    selectedTip = Number(button.dataset.tip);
    tipButtons.forEach((option) => {
      const isSelected = option === button;
      option.classList.toggle("is-selected", isSelected);
      option.setAttribute("aria-pressed", String(isSelected));
    });
    renderResults();
  });
});

// Botones para ajustar rápidamente la cantidad de personas.
document
  .querySelector("#decrease-people")
  .addEventListener("click", () => changePeopleCount(-1));
document
  .querySelector("#increase-people")
  .addEventListener("click", () => changePeopleCount(1));

// Muestra el estado inicial de la calculadora.
updateInputCurrency();
renderResults();
