import { useEffect, useMemo, useRef, useState } from 'react'
import { useBlocker, useParams } from 'react-router'
import { useMutation } from '@tanstack/react-query'
import { Anchor, Group, Stack, Text, Title } from '@mantine/core'
import { IconChevronLeft } from '@tabler/icons-react'

import { useApi, usePath } from 'src/app/contexts'
import { InvStore } from 'src/inventory-app/models/InvStore'
import { CatalogEditor } from './CatalogEditor'
import formatError from 'src/common/format-error'
import { Dispatch, ValueOrReducer } from 'src/utils/types-lib'
import { EditorFooter } from 'src/utils/EditorFooter'
import { UnsavedChangesModal } from 'src/utils/UnsavedChangesModal'
import { useBeforeUnload } from 'src/utils/use-before-unload'

export default function StoreEditorPage() {
  const { storeId } = useParams()
  const { navigate } = usePath()
  const { axios } = useApi()
  
  const [store, setStore] = useState<InvStore | null>(null)
  const [didChange, setDidChange] = useState(false) // Whether user made changes or not
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false) // Whether there is pending changes
  const blocker = useBlocker(useMemo(() => hasUnsavedChanges, [hasUnsavedChanges]))
  const mainRef = useRef<HTMLDivElement>(null)
  
  // Load

  const { mutate: loadStore, error: loadError, isPending: isLoading } = useMutation({
    mutationFn: async () => {
      return (await axios.get<InvStore>(`stores/${storeId}`)).data
    },
    onSuccess: store => {
      setStore(store)
    }
  })

  useEffect(() => {
    loadStore()
  }, [loadStore])

  // Save

  const { mutateAsync: saveStoreAsync } = useMutation({
    mutationFn: async (store: InvStore) => {
      // await sleep(1000)
      // throw new Error('Excepteur dolor culpa aute ea magna proident ad adipisicing fugiat ad. Excepteur dolor culpa aute ea magna proident ad adipisicing fugiat ad.')
      const body = store.catalog
      await axios.put(`stores/${storeId}/catalog`, body)
    },
    onSuccess: () => {
      setHasUnsavedChanges(false)
    }
  })

  useBeforeUnload(hasUnsavedChanges)

  return (
    <>
      <div ref={mainRef} className='flex flex-col gap-6 items-start'>
        {/* Back link */}
        <Anchor size='sm' onClick={e => { e.preventDefault(); navigate(`/`) }}>
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
              />
            </>
          )
        })()}
      </div>

      {didChange &&
        <EditorFooter
          editorRef={mainRef}
          hasUnsavedChanges={hasUnsavedChanges}
          save={() => saveStoreAsync(store!)}
          saveButtonLabel='Save Items'
        />
      }

      <UnsavedChangesModal
        blocker={blocker}
        save={() => saveStoreAsync(store!)}
      />
    </>
  )
}

/**
 * Store meta (name etc) and content (items and sections).
 */
function MetaAndContent({ store, setStore }: {
  store: InvStore
  setStore: Dispatch<ValueOrReducer<InvStore | null>>
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