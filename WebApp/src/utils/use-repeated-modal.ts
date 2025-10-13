/*
 IMPORTANT: Modify this in Common.
 */

import { useMemo, useState } from 'react'

/**
 * Returns states needed for repeatedly opening the same modal but with fresh
 * state every time.
 */
export default function useRepeatedModal(): ReturnValue {
  const [modalIDs, setModalIDs] = useState<number[]>([])
  const [openedModalId, setOpenedModalId] = useState<number>()

  return useMemo(() => ({
    modalIDs,
    isOpened: (id: number) => openedModalId == id,
    open: () => {
      const id = modalIDs.length
      setModalIDs(modalIDs.concat(id))

      // Need to wait for modal IDs to be updated, otherwise no in animation
      setTimeout(() => setOpenedModalId(id), 0)
    },
    close: () => {
      setOpenedModalId(undefined)

      // Wait & remove old (never used again) modals
      setTimeout(() => {
        setModalIDs([])
      }, 500)
    }
  }), [modalIDs, openedModalId])
}

interface ReturnValue {
  modalIDs: number[]
  isOpened: (id: number) => boolean
  open: () => void
  close: () => void
}