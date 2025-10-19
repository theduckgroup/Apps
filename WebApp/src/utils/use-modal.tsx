import { Button } from '@mantine/core'
import { ComponentType, useCallback, useState } from 'react'

export default function useModal<Options>(ModalComponentType: ModalComponentType<Options>) {
  const [data, setData] = useState<{id: number, options: Options}[]>([])
  const [openedModalId, setOpenedModalId] = useState<number>()

  const open = useCallback((options: Options) => {
    const id = data.length
    setData(data.concat({id, options}))

    // Need to wait for modal IDs to be updated, otherwise no in animation
    setTimeout(() => setOpenedModalId(id), 0)
  }, [data])

  const close = useCallback(() => {
    const modalId = openedModalId
    setOpenedModalId(undefined)

    // Wait & remove old (never used again) modals
    setTimeout(() => {
      // data = data.filter(x => x.id != modalId)
      setData([])
    }, 5000)
  }, [openedModalId])

  return {
    open,
    close,
    element: data.map(({id, options}) => (
      <ModalComponentType key={id} opened={id == openedModalId} onClose={close} options={options} />
    ))
  }
}


// function XXX() {
//   const confirmModal = useModal()

//   const handleClick = () => {
//     confirmModal.open()
//   }

//   return (
//     <>
//       <Button onClick={handleClick} />
//       {confirmModal.element}
//     </>
//   )
// }

export type ModalComponentType<Options> = ComponentType<{
  opened: boolean
  onClose: () => void
  options: Options
}>