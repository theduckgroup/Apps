import { Button, Group, Modal, Select, Stack, Text, Textarea } from '@mantine/core'

import { WsTemplate } from 'src/ws-app/models/WsTemplate'
import { isNotEmpty, useForm } from '@mantine/form'


export function EditSupplierModal({ opened, onClose, options }: {
  opened: boolean,
  onClose: () => void,
  options: {
    title: string,
    supplier: WsTemplate.Supplier,
    onSave: (_: WsTemplate.Supplier) => void
  }
}) {
  const { supplier, onSave } = options

  const form = useForm({
    mode: 'uncontrolled',
    initialValues: {
      name: options.supplier.name,
      gstMethod: options.supplier.gstMethod
    },
    validate: {
      name: isNotEmpty('Required')
    },
    clearInputErrorOnChange: true,
  });

  // const [supplier, setSupplier] = useState(options.supplier)

  // const handleNameChange = (value: string) => {
  //   setSupplier(produce(supplier, supplier => {
  //     supplier.name = value
  //   }))
  // }

  const handleSave = (values: typeof form.values) => {
    onClose()
    onSave({
      id: supplier.id,
      name: values.name,
      gstMethod: values.gstMethod
    })
  }

  // function handleInlineChange(value: boolean) {
  //   const modifiedItem = produce(item, item => {
  //     item.name.layout = value ? 'inline' : 'stack'
  //   })

  //   onChange(modifiedItem)
  // }

  // const isValid = supplier.name != ''

  const gstMethods: WsTemplate.GstMethod[] = ['notApplicable', '10%', 'input']
  const gstSelectData = gstMethods.map(x => ({ value: x, label: WsTemplate.gstMethodName(x) }))

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title={options.title}
      size='lg'
      returnFocus={false}
      closeOnClickOutside={false}
    >
      <form onSubmit={form.onSubmit(handleSave)}>
        <Stack>
          <Textarea
            label='Supplier Name'
            data-autofocus={true}
            autosize
            {...form.getInputProps('name')}
          // value={supplier.name}
          // onChange={e => handleNameChange(e.currentTarget.value)}
          />
          {/* <Stack align='flex-start' w='100%' gap='0.05rem'> */}
            {/* <Text fz='sm'>GST</Text>
          <Group align='center' gap='sm' wrap='nowrap'> */}
            <Select
              label='GST'
              placeholder='Select a role'
              data={gstSelectData}
              w='36%' // ??
              allowDeselect={false}
              {...form.getInputProps('gstMethod')}
            />
            {/* </Group> */}
          {/* </Stack> */}
          <Group>
            <Group gap='sm' ml='auto'>
              <Button variant='default' w='6rem' onClick={onClose}>Cancel</Button>
              <Button type='submit' w='6rem'>Save</Button>
            </Group>
          </Group>
        </Stack>
      </form>
    </Modal>
  )
}
