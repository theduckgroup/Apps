import 'react'
import { renderToString } from 'react-dom/server'
import { qrcode, drawingSVG } from '@bwip-js/browser'

const svgns = 'http://www.w3.org/2000/svg'

export function genQrcodeSvg(data: string, name: string) {
  name = 'This is a very long line that will wrap automatically\nBut this starts on a new line because of the explicit newline'
  
  const codeSvg = qrcode({
    bcid: 'code128',       // Barcode type
    text: data,    // Text to encode
    scale: 2,
    width: 200,
    height: 200,              // Bar height, in millimeters
    barcolor: '000000',
    includetext: true,            // Show human-readable text
    textxalign: 'center',        // Always good to set this
    textcolor: 'ff0000',        // Red text
  }, drawingSVG())

  // let svgString = code128({
  //   // bcid: 'code128',       // Barcode type
  //   bcid: 'code128',       // Barcode type
  //   text: text,    // Text to encode
  //   scale: 2,
  //   width: 100,
  //   height: 100,              // Bar height, in millimeters
  //   barcolor: '000000',
  //   // includetext: true,            // Show human-readable text
  //   // textxalign: 'center',        // Always good to set this
  //   // textcolor: 'ff0000',        // Red text
  // }, drawingSVG())


  // Container of code svg just so that we can parse it

  const codeSvgDivEl = document.createElement('div')
  codeSvgDivEl.innerHTML = codeSvg
  const codeSvgEl = codeSvgDivEl.querySelector('svg')!

  // Parse code svg to extract view box and path

  const codePathEl = codeSvgEl.querySelector('path')!
  const codeViewBox = codeSvgEl.getAttribute('viewBox')!
  const [, ,w_tmp, h_tmp] = codeViewBox.split(' ')
  const codeSize = { width: parseInt(w_tmp), height: parseInt(h_tmp) }
  const codePath = codePathEl.getAttribute('d')!
  // console.info(codeSize, codePath)

  const fontFamily = 'Arial'
  const fontWeight = '500'
  // const fontSize = Math.round(codeSize.width * 0.12)
  const fontSize = Math.round(codeSize.width * 0.08)

  // const dataText_bb = measureText(data, { fontFamily, fontSize })

  const yspace = codeSize.height * 0.05

  // Wrap name text to fit within QR code width
  const wrappedLines = wrapTextToWidth(
    name,
    codeSize.width,
    { fontFamily, fontWeight, fontSize }
  )

  // Measure single line height for line spacing
  const singleLineHeight = measureText('M', { fontFamily, fontWeight, fontSize }).height
  const lineSpacing = singleLineHeight * 1.2 // 1.2x line height

  const firstLineBaseline = codeSize.height + yspace + singleLineHeight
  const bottomPadding = singleLineHeight * 0.25 // There is no way to get descent of svg text!

  const totalTextHeight = wrappedLines.length * lineSpacing - (lineSpacing - singleLineHeight)
  const viewBoxHeight = codeSize.height + yspace + totalTextHeight + bottomPadding

  const reactEl = (
    <svg
      xmlns={svgns}
      viewBox={`0 0 ${codeSize.width} ${viewBoxHeight}`}
      width={`${codeSize.width}px`} height={`${viewBoxHeight}px`}
    >
      <path d={codePath} fill='black' fillRule='evenodd' />
      <text
        x={codeSize.width / 2}
        y={firstLineBaseline}
        fontSize={fontSize}
        fontWeight={fontWeight}
        fontFamily={fontFamily}
        textAnchor="middle"
      >
        {wrappedLines.map((line, index) => (
          <tspan key={index} x={codeSize.width / 2} dy={index === 0 ? 0 : lineSpacing}>
            {line}
          </tspan>
        ))}
      </text>
    </svg>
  )

  const x = renderToString(reactEl)
  // console.info(x)

  return x
}

function measureText(
  text: string,
  { fontFamily, fontWeight, fontSize }: {
    fontFamily: string,
    fontWeight: string,
    fontSize: number,
  }
): { width: number, height: number } {
  // From: https://www.reddit.com/r/webdev/comments/1e809pz/getting_the_bounding_box_of_an_svg_text_element/

  // console.info(fontFamily, fontSize)
  const svgEl = document.createElementNS(svgns, 'svg')
  document.body.appendChild(svgEl)

  const textEl = document.createElementNS(svgns, 'text')
  textEl.setAttribute('y', '0')
  textEl.style.fontFamily = fontFamily
  textEl.style.fontSize = fontSize.toString()
  textEl.style.fontWeight = fontWeight
  textEl.textContent = text
  svgEl.appendChild(textEl)

  const bbox = textEl.getBBox()
  textEl.parentNode!.removeChild(textEl)
  // console.info(`bbox: ${bbox.width} ${bbox.height}`)

  svgEl.parentNode!.removeChild(svgEl)

  return { width: bbox.width, height: bbox.height }
}

/**
 * Wraps text to fit within a maximum width by breaking at word boundaries.
 * Uses a greedy algorithm to fit as many words as possible on each line.
 * Respects explicit line breaks (\n).
 */
function wrapTextToWidth(
  text: string,
  maxWidth: number,
  fontProps: {
    fontFamily: string,
    fontWeight: string,
    fontSize: number,
  }
): string[] {
  // First split by explicit newlines to preserve them
  const paragraphs = text.split('\n')
  const allLines: string[] = []

  for (const paragraph of paragraphs) {
    // Wrap each paragraph independently
    const words = paragraph.split(/\s+/).filter(w => w.length > 0)

    if (words.length === 0) {
      // Empty paragraph (from consecutive \n or leading/trailing \n)
      allLines.push('')
      continue
    }

    let currentLine = ''

    for (const word of words) {
      const testLine = currentLine ? `${currentLine} ${word}` : word
      const testWidth = measureText(testLine, fontProps).width

      if (testWidth <= maxWidth) {
        // Word fits on current line
        currentLine = testLine
      } else {
        // Word doesn't fit, start new line
        if (currentLine) {
          allLines.push(currentLine)
        }

        // Check if single word is too long
        const wordWidth = measureText(word, fontProps).width
        if (wordWidth > maxWidth) {
          // Single word is longer than max width, add it anyway
          allLines.push(word)
          currentLine = ''
        } else {
          currentLine = word
        }
      }
    }

    // Add remaining text from this paragraph
    if (currentLine) {
      allLines.push(currentLine)
    }
  }

  // Handle empty input
  return allLines.length > 0 ? allLines : ['']
}

// Canvas drawing code
// Doesn't work because of blurry issue


/*
// const canvas = document.getElementById('canvas') as HTMLCanvasElement
const canvas = canvasRef.current!
console.info(`canvas = ${canvas}`)
// console.info(ctx)
const ctx = canvas.getContext('2d')!
console.info(`ctx = ${ctx}`)
console.info(ctx)

const width = 250
const padding = 15

const path = new Path2D(svgPath)
// const path = new Path2D('M 0 0 L 20 10 L 20 20 L 0 20 Z')
//context.strokeStyle = `rgb(0, 0, 0)`
// context.fillStyle = `rgb(0, 0, 0)`
canvas.width = canvas.offsetWidth
canvas.height = canvas.offsetHeight
ctx.clearRect(0, 0, canvas.width, canvas.height)
ctx.save()
ctx.scale(0.25, 0.25)
ctx.fillStyle = `black`
ctx.translate(0.25, 0.25)
ctx.fill(path)
ctx.restore()
*/
// ctx.stroke(path)
// ctx.fillRect(20, 20, 100, 100)

// ctx.fillStyle = "rgb(200 0 0)";
// ctx.fillRect(10, 10, 50, 50);

// ctx.fillStyle = "rgb(0 0 200 / 50%)";
// ctx.fillRect(30, 30, 50, 50);


// console.info(`svg = ${svgString}`)

// const svg = parse(svgString)

// console.info(svg)

// setSvg(svgString)
// setSvg(svg)
