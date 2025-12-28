import { useEffect, useState } from "react"
import { Button, CopyButton, Group, Modal, Paper, Stack, Text } from "@mantine/core"

import { InvStore } from "src/inventory-app/models/InvStore"
import { genQrcodeSvg } from "./gen-qrcode-svg"

export default function QrModal({ opened, onClose, item }: {
  opened: boolean
  onClose: () => void,
  item?: InvStore.Item
}) {
  const [svg, setSvg] = useState<string | undefined>()

  useEffect(() => {
    if (item) {
      const svg = genQrcodeSvg(item.code, item.name)
      setSvg(svg)
    } else {
      setSvg(undefined)
    }
  }, [item])

  // function copySvg() {
  //   const svg = genQrcodeSvg(code, name)
  //   navigator.clipboard.writeText(svg)
  // }

  return (
    <Modal
      title={<Text>{item?.name ?? ''} | QR Code</Text>}
      // size='sm'
      // padding='md'
      // centered
      // overlayProps={{
      //   backgroundOpacity: 0.3,
      //   // blur: 20
      // }}
      returnFocus={false}
      opened={opened}
      onClose={onClose}
    >
      <Stack justify='center' py='lg'>
        <Group justify='center'>
          <Paper w={180} px={16} py={16} bg='white' radius={1.5}>
            {svg && <img src={`data:image/svg+xml;utf8,${encodeURIComponent(svg)}`} width='200px' />}
          </Paper>
        </Group>
        <Group justify='center'>
          <CopyButton value={svg ?? ''} timeout={1000}>
            {({ copied, copy }) => (
              <Button color={copied ? 'gray.7' : 'blue'} onClick={copy}>
                {copied ? 'Copied to Clipboard' : 'Copy SVG'}
              </Button>
            )}
          </CopyButton>
        </Group>
      </Stack>
    </Modal>
  )
}