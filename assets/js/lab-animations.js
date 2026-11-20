const motionPreference = window.matchMedia("(prefers-reduced-motion: reduce)");

for (const panel of document.querySelectorAll(".research-media")) {
  const image = panel.querySelector("img");
  const button = panel.querySelector("button");
  const poster = image.src;
  const title = panel.closest("article").querySelector("h3").textContent;
  let enabled = !motionPreference.matches;
  let onScreen = false;

  function update() {
    const playing = enabled && onScreen;
    image.src = playing ? image.dataset.animation : poster;
    button.textContent = playing ? "Pause" : "Play";
    button.setAttribute("aria-label", button.textContent + " animation: " + title);
  }

  button.hidden = false;
  button.addEventListener("click", () => {
    enabled = !enabled;
    update();
  });
  motionPreference.addEventListener("change", () => {
    enabled = !motionPreference.matches;
    update();
  });
  new IntersectionObserver(([entry]) => {
    onScreen = entry.isIntersecting;
    update();
  }).observe(panel);
}
