import { useCallback, useEffect, useState } from 'react'
import { useParams } from 'react-router'
import { useMutation } from '@tanstack/react-query'
import { Anchor, Box, Button, Group, Loader, Stack, Text, Title } from '@mantine/core'
import { IconArrowBackUp, IconChevronLeft } from '@tabler/icons-react'

import { useApi, usePath } from 'src/app/contexts'
import { InvStore } from 'src/inventory-app/models/InvStore'
import { CatalogEditor } from './CatalogEditor'
import formatError from 'src/common/format-error'
import useModal from 'src/utils/use-modal'
import { ConfirmModal } from 'src/utils/ConfirmModal'
import { Dispatch, ValueOrReducer } from 'src/utils/types-lib'
import { useElementRect } from 'src/utils/use-element-rect'
import { useViewportSize } from '@mantine/hooks'

export default function StoreEditorPage() {
  const { storeId } = useParams()
  const { navigate } = usePath()
  const { axios } = useApi()
  // const storeName = location.state?.storeName

  const [store, setStore] = useState<InvStore | null>(null)
  const [didChange, setDidChange] = useState(false) // Whether user made changes or not
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false) // Whether there is pending changes

  // Load

  const { mutate: loadStore, error: loadError, isPending: isLoading } = useMutation({
    mutationFn: async () => {
      return (await axios.get<InvStore>(`store/${storeId}`)).data
    },
    onSuccess: store => {
      setStore(store)
    }
  })

  useEffect(() => {
    loadStore()
  }, [loadStore])

  // Save

  const { mutate: saveStore, error: saveError, isPending: saving } = useMutation({
    mutationFn: async (store: InvStore) => {
      const body = store.catalog
      await axios.put(`store/${storeId}/catalog`, body)
    }
  })

  const handleSaveChanges = useCallback(() => {
    saveStore(store!)
    setHasUnsavedChanges(false)
  }, [store, saveStore])

  const [mainRef, mainRect] = useElementRect()
  const viewportSize = useViewportSize()

  return (
    <>
      <div ref={mainRef} className='flex flex-col gap-6 items-start'>
        {/* Save error */}
        {
          saveError &&
          <Stack align='center'>
            <Group>
              <Text c='red'>{formatError(saveError)}</Text>
              {/* <Button variant='subtle' size='compact-md'>Retry</Button> */}
              <Anchor href='#' onClick={() => saveStore(store!)}>Retry</Anchor>
            </Group>
          </Stack>
        }

        {/* Back link */}
        <Anchor size='sm' href='#' onClick={() => navigate(`/`)}>
          <Group gap='0.2rem'>
            <IconChevronLeft size={18} />
            Back to Inventory
          </Group>
        </Anchor>

        {/* Content */}
        {(() => {
          if (isLoading) {
            return <Text>Loading...</Text>
          }

          if (loadError) {
            return <Text c='red'>{formatError(loadError)}</Text>
          }

          if (!store) {
            return <>???</>
          }

          return (
            <>
              <title>{store.name + ' | The Duck Group'}</title>
              <MetaAndContent
                store={store}
                setStore={valueOrReducer => {
                  setStore(valueOrReducer)
                  setDidChange(true)
                  setHasUnsavedChanges(true)
                }}
                saving={saving}
                dirty={hasUnsavedChanges}
              />
            </>
          )
        })()}
      </div>

      {/* Floating save bar */}
      {didChange && (
        <>
          {/* pb-[max(1rem, env(safe-area-inset-bottom))]  */}
          <div className='h-26' />
          <div
            className='
              fixed left-0 right-0 bottom-0 h-22 pb-[env(safe-area-inset-bottom)] 
              bg-[var(--mantine-color-dark-7)]
              flex justify-end
            '
            style={{
              paddingRight: viewportSize.width - (mainRect?.right ?? 0)
            }}
          >
            <div className='flex flex-row items-center px-4 py-4 gap-4'>
              <Button onClick={handleSaveChanges} loading={saving} disabled={!hasUnsavedChanges}>
                Save Changes
              </Button>
            </div>
          </div>
        </>
      )
      }
    </>
  )
}

/**
 * Store meta (name etc) and content (items and sections).
 */
function MetaAndContent({ store, setStore, saving, dirty }: {
  store: InvStore
  setStore: Dispatch<ValueOrReducer<InvStore | null>>,
  saving: boolean
  dirty: boolean
}) {

  type Reducer<T> = (prev: T) => T

  const setData: Dispatch<Reducer<[InvStore.Item[], InvStore.Section[]]>> = reducer => {
    setStore(store => {
      const [items, sections] = reducer([store!.catalog.items, store!.catalog.sections])
      return { ...store!, catalog: { items, sections } }
    })
  }

  return (
    <Stack className='w-full' gap='xl'>
      {/* Title */}
      <Title order={1} c='gray.1'>Edit Items</Title>

      {/* Items editor */}
      <CatalogEditor
        items={store.catalog.items}
        sections={store.catalog.sections}
        setData={setData}
      />
    </Stack>
  )
}