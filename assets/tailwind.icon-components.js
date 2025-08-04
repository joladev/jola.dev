const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

// Heroicons plugin
const heroComponent = plugin(function({matchComponents, theme}) {
  let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
  let values = {}
  let icons = [
    ["", "/24/outline"],
    ["-solid", "/24/solid"],
    ["-mini", "/20/solid"],
    ["-micro", "/16/solid"]
  ]
  icons.forEach(([suffix, dir]) => {
    fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
      let name = path.basename(file, ".svg") + suffix
      values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
    })
  })
  matchComponents({
    "hero": ({name, fullPath}) => {
      let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
      let size = theme("spacing.6")
      if (name.endsWith("-mini")) {
        size = theme("spacing.5")
      } else if (name.endsWith("-micro")) {
        size = theme("spacing.4")
      }
      return {
        [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
        "-webkit-mask": `var(--hero-${name})`,
        "mask": `var(--hero-${name})`,
        "mask-repeat": "no-repeat",
        "-webkit-mask-size": "contain",
        "mask-size": "contain",
        "-webkit-mask-position": "center",
        "mask-position": "center",
        "background-color": "currentColor",
        "vertical-align": "middle",
        "display": "inline-block",
        "width": size,
        "height": size
      }
    }
  }, {values})
})

// Lucide icons plugin
const lucideComponent = plugin(function({matchComponents, theme}) {
  let iconsDir = path.join(__dirname, "../deps/lucide/icons")
  let values = {}
  
  if (fs.existsSync(iconsDir)) {
    fs.readdirSync(iconsDir).forEach(file => {
      if (file.endsWith('.svg')) {
        let name = path.basename(file, ".svg")
        values[name] = {name, fullPath: path.join(iconsDir, file)}
      }
    })
  }
  
  matchComponents({
    "lucide": ({name, fullPath}) => {
      let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
      let size = theme("spacing.6") // Default 24px size for Lucide icons
      return {
        [`--lucide-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
        "-webkit-mask": `var(--lucide-${name})`,
        "mask": `var(--lucide-${name})`,
        "mask-repeat": "no-repeat",
        "-webkit-mask-size": "contain",
        "mask-size": "contain",
        "-webkit-mask-position": "center",
        "mask-position": "center",
        "background-color": "currentColor",
        "vertical-align": "middle",
        "display": "inline-block",
        "width": size,
        "height": size
      }
    }
  }, {values})
})

module.exports = {
  heroComponent,
  lucideComponent
}