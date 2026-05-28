import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: { type: Number, default: 10000 } }

  connect() {
    this.currentIndex = 0
    this.timer = null
    this.init()

    const matchesEl = this.element.querySelector("#tournament_matches")
    if (matchesEl) {
      this.observer = new MutationObserver(() => {
        const saved = this.currentIndex
        clearInterval(this.timer)
        this.init()
        if (saved < this.slides.length) this.showSlide(saved)
      })
      this.observer.observe(matchesEl, { childList: true })
    }
  }

  disconnect() {
    clearInterval(this.timer)
    this.observer?.disconnect()
  }

  init() {
    this.slides = Array.from(this.element.querySelectorAll("[data-slide]"))
    this.dotsEl = this.element.querySelector("#slide-dots")
    this.titleEl = this.element.querySelector("#slide-title")

    if (this.slides.length === 0) return

    this.buildDots()
    this.showSlide(0)

    if (this.slides.length > 1) {
      this.timer = setInterval(() => this.next(), this.intervalValue)
    }
  }

  buildDots() {
    if (!this.dotsEl) return
    this.dotsEl.innerHTML = ""
    if (this.slides.length <= 1) return
    this.slides.forEach((_, i) => {
      const dot = document.createElement("span")
      dot.className = "slide-dot"
      dot.addEventListener("click", () => {
        clearInterval(this.timer)
        this.showSlide(i)
        this.timer = setInterval(() => this.next(), this.intervalValue)
      })
      this.dotsEl.appendChild(dot)
    })
  }

  showSlide(idx) {
    this.currentIndex = idx
    this.slides.forEach((s, i) => { s.style.display = i === idx ? "block" : "none" })
    if (this.titleEl) {
      this.titleEl.textContent = this.slides[idx]?.dataset.slideTitle || ""
    }
    const dots = this.dotsEl?.querySelectorAll(".slide-dot") || []
    dots.forEach((d, i) => d.classList.toggle("active", i === idx))
  }

  next() {
    this.showSlide((this.currentIndex + 1) % this.slides.length)
  }
}
