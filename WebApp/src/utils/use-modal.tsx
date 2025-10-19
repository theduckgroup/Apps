import { produce } from 'immer'
import { ComponentType, useCallback, useState } from 'react'

export default function useModal<Options = undefined>(ModalComponentType: ModalComponentType<Options>): {
  open: OpenFn<Options>,
  close: () => void,
  element: React.ReactNode
} {
  // Data is structured so that we can use updater variant of setState and avoid costly dependencies
  type ModalState = { id: number, opened: boolean, options: Options }
  const [data, setData] = useState<ModalState[]>([])

  const open = useCallback((options: unknown) => {
    setData(data => (
      data.concat({
        id: data.length,
        opened: false,
        options: options as Options // Type-erase
      })
    ))

    // Wait for modal IDs to be updated, otherwise no entrance animation
    setTimeout(() => {
      setData(data => produce(data, data => {
        data[data.length - 1].opened = true
      }))
    }, 0)
  }, []) as OpenFn<Options> // Type-erase

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

type OpenFn<Options> = (...args: Options extends undefined ? [] : [arg: Options]) => void
// type OpenFn1<Options> = ReturnType<typeof useModal<Options>>['open'] // Alternative if `open`'s type is declared in-place

export type ModalComponentType<Options> = ComponentType<{
  opened: boolean
  onClose: () => void
  options: Options
}>