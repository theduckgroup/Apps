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

  const [initialStore, setInitialStore] = useState<InvStore | null>(null)
  const [store, setStore] = useState<InvStore | null>(null)
  const [saveTrigger, setSaveTrigger] = useState(0)
  const [dirty, setDirty] = useState(false)

  // Load

  const { mutate: loadStore, error: loadError, isPending: isLoading } = useMutation({
    mutationFn: async () => {
      return (await axios.get<InvStore>(`store/${storeId}`)).data
    },
    onSuccess: store => {
      setInitialStore(store)
      setStore(store)
    }
  })

  useEffect(() => {
    loadStore()
  }, [loadStore])

  // Save

  const { mutate: saveStore, error: saveError, isPending: isSaving } = useMutation({
    mutationFn: async (store: InvStore) => {
      const body = store.catalog
      await axios.put(`store/${storeId}/catalog`, body)
    }
  })

  useEffect(() => {
    if (saveTrigger > 0) {
      saveStore(store!)
    }
  }, [store, saveStore, saveTrigger])

  const setNeedsSave = useCallback(() => {
    setSaveTrigger(x => x + 1)
  }, [setSaveTrigger])

  // Set

  const setStoreAndSave: Dispatch<ValueOrReducer<InvStore | null>> = useCallback(valueOrReducer => {
    setStore(valueOrReducer)
    setDirty(true)
  }, [setStore])

  const handleSaveChanges = useCallback(() => {
    setNeedsSave()
    setDirty(false)
  }, [setNeedsSave])

  const handleDiscardChanges = useCallback(() => {
    setStore(initialStore)
    setDirty(false)
  }, [initialStore, setStore])

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
                setStore={setStoreAndSave}
                saving={isSaving}
                dirty={dirty}
              />
            </>
          )
        })()}
      </div>

      {/* Floating save bar */}
      {dirty && (
        <>
          {/* pb-[max(1rem, env(safe-area-inset-bottom))]  */}
          <div className='h-26' />
          <div
            className='
              fixed left-0 right-0 bottom-0 h-22 pb-[env(safe-area-inset-bottom)] 
              bg-[var(--mantine-color-dark-6)]
              flex justify-end
            '
            style={{
              paddingRight: viewportSize.width - (mainRect?.right ?? 0)
            }}
          >
            <div className='flex flex-row items-center px-4 py-4 gap-4'>
              <Button variant='default' onClick={handleDiscardChanges} disabled={isSaving}>
                Discard Changes
              </Button>
              <Button onClick={handleSaveChanges} loading={isSaving}>
                Save Changes
              </Button>
            </div>
          </div>
          {/* <div className='sticky bottom-0 pt-6 pb-[env(safe-area-inset-bottom)] flex justify-center items-center'> */}
          {/* <div
            // className='
            //   fixed bottom-0 h-22 pb-[env(safe-area-inset-bottom)] 
            //   //bg-[var(--mantine-color-dark-6)]
            //   flex justify-center items-center
            // '
            className='
              fixed left-0 bottom-0 h-22 pb-[env(safe-area-inset-bottom)] 
              bg-[var(--mantine-color-dark-6)]
              flex justify-center items-center
            '
            style={{
              right: viewportSize.width - (mainRect?.right ?? 0)
            }}
          >
            <div className='flex flex-row items-center px-4 py-4 gap-4'>
              <Button variant='default' onClick={handleDiscardChanges} disabled={isSaving}>
                Discard Changes
              </Button>
              <Button onClick={handleSaveChanges} loading={isSaving}>
                Save Changes
              </Button>
            </div>
          </div> */}
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
      {/* Metadata + Save loader */}
      <Group className='w-full items-start'>
        {/* Metadata + Edit button */}
        {/* <Stack w='100%' gap='xs' align='flex-start' mr='auto'> */}
        <Stack className='w-full gap-2 items-start mr-auto'>
          {/* Title + Saving loader */}
          <Group bg='dark.9' pt='sm' className='gap-2 items-baseline'>
            {/* Name */}
            <Title order={1} c='gray.1'>Edit Items</Title>
            {/* Save loader */}
            {saving && <Loader ml='auto' size='xs' />}
          </Group>
          {/* Code, items per page */}
          {/* <Stack gap='0'>
            <Text>Code: {template.code}</Text>
            <Text>Email Recipients: {template.emailRecipients.join(', ')}</Text>
          </Stack> */}
        </Stack>
      </Group>

      {/* Items editor */}
      <CatalogEditor
        items={store.catalog.items}
        sections={store.catalog.sections}
        setData={setData}
      />
    </Stack>
  )
}