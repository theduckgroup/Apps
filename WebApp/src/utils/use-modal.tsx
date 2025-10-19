import { produce } from 'immer'
import { ComponentType, useCallback, useState } from 'react'

export default function useModal<Options>(ModalComponentType: ModalComponentType<Options>) {
  type ModalState = { id: number, opened: boolean, options: Options }

  // Data is structured so that we can use updater variant of setState and avoid costly dependencies
  const [data, setData] = useState<ModalState[]>([])

  const open = useCallback((options: Options) => {
    setData(data => (
      data.concat({
        id: data.length,
        opened: false,
        options
      })
    ))

    // Wait for modal IDs to be updated, otherwise no in animation
    setTimeout(() => {
      setData(data => produce(data, data => {
        data[data.length - 1].opened = true
      }))
    }, 0)
  }, [])

  const close = useCallback(() => {
    setData(data => produce(data, data => {
      for (const x of data) {
        x.opened = false
      }
    }))

    // Wait for dismiss animation & remove old (never used again) modals
    setTimeout(() => {
      setData([])
    }, 1000)
  }, [])

  return {
    open,
    close,
    element: data.map(({ id, opened, options }) => (
      <ModalComponentType key={id} opened={opened} onClose={close} options={options} />
    ))
  }
}

export type ModalComponentType<Options> = ComponentType<{
  opened: boolean
  onClose: () => void
  options: Options
}>