// Smoke test for the Westmere musl binding.
// Run with musl Node so js-binding.js selects skia.linux-x64-musl.node.
// Draw, text and PNG do not need pdfjs. PDF extraction uses pdfjs-dist
// 6.3.289, the catalog pin in n8n 2.48.5 (packages/nodes-base/utils/binary.ts).

import { createCanvas, GlobalFonts } from '@napi-rs/canvas'
import { readFileSync, writeFileSync } from 'node:fs'

const font = '/usr/share/fonts/dejavu/DejaVuSans.ttf'
if (!GlobalFonts.registerFromPath(font, 'DejaVu Sans')) {
  throw new Error('font register failed: ' + font)
}

function paint(withText) {
  const canvas = createCanvas(120, 40)
  const ctx = canvas.getContext('2d')
  ctx.fillStyle = '#ffffff'
  ctx.fillRect(0, 0, 120, 40)
  ctx.fillStyle = '#cc0000'
  ctx.fillRect(4, 4, 24, 24)
  if (withText) {
    ctx.fillStyle = '#003366'
    ctx.font = '16px "DejaVu Sans"'
    ctx.fillText('Westmere', 32, 26)
  }
  return canvas.toBuffer('image/png')
}

const plain = paint(false)
const png = paint(true)
if (png[0] !== 0x89 || png.toString('ascii', 1, 4) !== 'PNG') {
  throw new Error('PNG signature missing')
}
if (Buffer.compare(plain, png) === 0) {
  throw new Error('fillText did not change the PNG')
}
writeFileSync(new URL('./out.png', import.meta.url), png)
console.log('CANVAS_OK bytes=' + png.length)

const { getDocument } = await import('pdfjs-dist/legacy/build/pdf.mjs')
const data = new Uint8Array(readFileSync(new URL('./westmere.pdf', import.meta.url)))
const doc = await getDocument({ data }).promise
const page = await doc.getPage(1)
const text = (await page.getTextContent()).items.map((item) => item.str).join('')
if (!text.includes('Westmere OK')) {
  throw new Error('pdf text mismatch: ' + JSON.stringify(text))
}
console.log('PDF_OK text=' + JSON.stringify(text) + ' pages=' + doc.numPages)
