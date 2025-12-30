import { Button, Checkbox, CopyButton as MantineCopyButton, Flex, Modal, Paper, Slider, Stack, Text, Textarea } from '@mantine/core'
import { useState } from 'react'

import { InvStore } from 'src/inventory-app/models/InvStore'
import { genQRCodeSvg } from './gen-qrcode-svg'

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
  const [overrideLabel, setOverrideLabel] = useState(false)
  const [customLabel, setCustomLabel] = useState('')

  const { data: svgData, size: svgSize } = genQRCodeSvg({
    data: item.code,
    label: overrideLabel ? customLabel : item.name,
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
        <QRCodeControls
          qrcodeSize={qrcodeSize}
          setQRCodeSize={setQRCodeSize}
          textSizeRatio={textSizeRatio}
          setTextSizeRatio={setTextSizeRatio}
          textWidthRatio={textWidthRatio}
          setTextWidthRatio={setTextWidthRatio}
          overrideLabel={overrideLabel}
          setOverrideLabel={setOverrideLabel}
          customLabel={customLabel}
          setCustomLabel={setCustomLabel}
        />

        {/* Right side: QR Code and Copy Button */}
        <Stack gap='md' style={{ flex: 1 }} align='center'>
          <QRCodeImage svgData={svgData} width={svgSize.width} />
          <CopyButton svgData={svgData} />
        </Stack>
      </Flex>
    </Modal>
  )
}

function QRCodeControls({ qrcodeSize, setQRCodeSize, textSizeRatio, setTextSizeRatio, textWidthRatio, setTextWidthRatio, overrideLabel, setOverrideLabel, customLabel, setCustomLabel }: {
  qrcodeSize: number
  setQRCodeSize: (value: number) => void
  textSizeRatio: number
  setTextSizeRatio: (value: number) => void
  textWidthRatio: number
  setTextWidthRatio: (value: number) => void
  overrideLabel: boolean
  setOverrideLabel: (value: boolean) => void
  customLabel: string
  setCustomLabel: (value: string) => void
}) {
  return (
    <Stack gap='2.5rem' style={{ flex: '0 0 250px' }}>
      <Stack gap={0}>
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
      </Stack>

      <Stack gap={0}>
        <Text size='sm' fw={500} mb='xs'>Text Size (relative to code)</Text>
        <Slider
          value={textSizeRatio}
          onChange={setTextSizeRatio}
          min={0.04}
          max={0.15}
          step={0.01}
          marks={[
            { value: 0.04, label: 'Small' },
            { value: 0.08, label: 'Medium' },
            { value: 0.15, label: 'Large' },
          ]}
        />
      </Stack>

      <Stack gap={0}>
        <Text size='sm' fw={500} mb='xs'>Text Max Width (relative to code)</Text>
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
      </Stack>

      <Stack gap='xs'>
        <Checkbox
          label='Override Label'
          checked={overrideLabel}
          onChange={(e) => setOverrideLabel(e.currentTarget.checked)}
        />
        {overrideLabel && (
          <Textarea
            placeholder='Enter custom label'
            value={customLabel}
            onChange={(e) => setCustomLabel(e.currentTarget.value)}
            autosize
            minRows={3}
            maxRows={6}
          />
        )}
      </Stack>
    </Stack>
  )
}

function QRCodeImage({ svgData, width }: {
  svgData: string
  width: number
}) {
  const padding = Math.max(width * 0.08, 16)

  return (
    <Paper p={padding} bg='white' radius={6}>
      <img src={`data:image/svg+xml;utf8,${encodeURIComponent(svgData)}`} width={width} />
    </Paper>
  )
}

function CopyButton({ svgData }: {
  svgData: string
}) {
  return (
    <MantineCopyButton value={svgData} timeout={1000}>
      {({ copied, copy }) => (
        <Button color={copied ? 'gray.7' : 'blue'} onClick={copy}>
          {copied ? 'Copied to Clipboard' : 'Copy SVG'}
        </Button>
      )}
    </MantineCopyButton>
  )
}