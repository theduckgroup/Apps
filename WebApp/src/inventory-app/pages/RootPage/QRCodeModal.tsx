import { Button, CopyButton as MantineCopyButton, Flex, Modal, Paper, Slider, Stack, Text } from '@mantine/core'
import { useState } from 'react'

import { InvStore } from 'src/inventory-app/models/InvStore'
import { genQrcodeSvg } from './gen-qrcode-svg'

export default function QrModal({ opened, onClose, options }: {
  opened: boolean
  onClose: () => void,
  options: {
    item: InvStore.Item
  }

}) {
  const { item } = options

  const [qrcodeSize, setQRCodeSize] = useState(200)
  const [textSizeRatio, setTextSizeRatio] = useState(0.08)
  const [textWidthRatio, setTextWidthRatio] = useState(1.0)

  const svg = genQrcodeSvg({
    data: item.code, 
    label: item.name, 
    qrcodeSize, 
    textSizeRatio, 
    textWidthRatio 
  })

  return (
    <Modal
      title={<Text>{item?.name ?? ''}</Text>}
      returnFocus={false}
      opened={opened}
      onClose={onClose}
      closeOnClickOutside={false}
      size='xl'
    >
      <Flex gap='xl' py='lg' align='flex-start'>
        {/* Left side: Controls */}
        <Stack gap='xl' style={{ flex: '0 0 250px' }}>
          <div>
            <Text size='sm' fw={500} mb='xs'>QR Code Size</Text>
            <Slider
              value={qrcodeSize}
              onChange={setQRCodeSize}
              min={100}
              max={500}
              step={10}
              marks={[
                { value: 100, label: '100' },
                { value: 200, label: '200' },
                { value: 300, label: '300' },
                { value: 400, label: '400' },
                { value: 500, label: '500' },
              ]}
            />
          </div>

          <div>
            <Text size='sm' fw={500} mb='xs'>Text Size</Text>
            <Slider
              value={textSizeRatio}
              onChange={setTextSizeRatio}
              min={0.04}
              max={0.20}
              step={0.01}
              marks={[
                { value: 0.04, label: 'Small' },
                { value: 0.08, label: 'Medium' },
                { value: 0.12, label: 'Large' },
              ]}
            />
          </div>

          <div>
            <Text size='sm' fw={500} mb='xs'>Text Width</Text>
            <Slider
              value={textWidthRatio}
              onChange={setTextWidthRatio}
              min={0.5}
              max={1.5}
              step={0.05}
              marks={[
                { value: 0.5, label: '50%' },
                { value: 1.0, label: '100%' },
                { value: 1.5, label: '150%' },
              ]}
            />
          </div>
        </Stack>

        {/* Right side: QR Code and Copy Button */}
        <Stack gap='md' style={{ flex: 1 }} align='center'>
          <QRCodeImage svg={svg} size={qrcodeSize} />
          <CopyButton svg={svg} />
        </Stack>
      </Flex>
    </Modal>
  )
}

function QRCodeImage({ svg, size }: {
  svg: string
  size: number
}) {
  return (
    <Paper px={16} py={16} bg='white' radius={1.5}>
      <img src={`data:image/svg+xml;utf8,${encodeURIComponent(svg)}`} width={size} />
    </Paper>
  )
}

function CopyButton({ svg }: {
  svg: string
}) {
  return (
    <MantineCopyButton value={svg} timeout={1000}>
      {({ copied, copy }) => (
        <Button color={copied ? 'gray.7' : 'blue'} onClick={copy}>
          {copied ? 'Copied to Clipboard' : 'Copy SVG'}
        </Button>
      )}
    </MantineCopyButton>
  )
}