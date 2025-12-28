import 'react'
import { renderToString } from 'react-dom/server'
import { qrcode, drawingSVG } from '@bwip-js/browser'

const svgns = 'http://www.w3.org/2000/svg'

export function genQrcodeSvg(data: string, name: string) {
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
  const [, , w_tmp, h_tmp] = codeViewBox.split(' ')
  const codeSize = { width: parseInt(w_tmp), height: parseInt(h_tmp) }
  const codePath = codePathEl.getAttribute('d')!
  // console.info(codeSize, codePath)

  const fontFamily = 'Arial'
  const fontWeight = '500'
  // const fontSize = Math.round(codeSize.width * 0.12)
  const fontSize = Math.round(codeSize.width * 0.08)

  // const dataText_bb = measureText(data, { fontFamily, fontSize })

  const yspace = codeSize.height * 0.05

  const nameTextSize = measureText(name, { fontFamily, fontWeight, fontSize })
  const nameTextX = codeSize.width / 2 - nameTextSize.width / 2
  const nameTextBaseline = codeSize.height + yspace + nameTextSize.height

  const bottomPadding = nameTextSize.height * 0.25 // There is no way to get descent of svg text!

  const viewBoxHeight = codeSize.height + yspace + nameTextSize.height + bottomPadding

  const reactEl = (
    <svg
      xmlns={svgns}
      viewBox={`0 0 ${codeSize.width} ${viewBoxHeight}`}
      width={`${codeSize.width}px`} height={`${viewBoxHeight}px`}
    >
      <path d={codePath} fill='black' fillRule='evenodd' />
      <text
        x={nameTextX} y={nameTextBaseline}
        fontSize={fontSize} fontWeight={fontWeight} fontFamily={fontFamily}
      >
        {name}
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
