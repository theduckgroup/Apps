import { Text, Group, Stack, Select, Paper } from '@mantine/core'
import { useEffect, useRef, useState } from 'react'
// import { useState } from 'react'
// import { IconInfoCircle } from '@tabler/icons-react'

export default function RoleSelect({ role, disabled, selectInputProps }: {
  role: 'owner' | 'admin' | 'user',
  disabled: boolean,
  selectInputProps: object,
}) {
  // const [roleInfoVisible, setRoleInfoVisible] = useState(false)
  const [roleChanged, setRoleChanged] = useState(false);
  const initialRoleRef = useRef(role)

  useEffect(() => {
    if (role != initialRoleRef.current) {
      setRoleChanged(true)
    }
  }, [role])

  return (
    <Stack gap='sm'>
      <Stack align='flex-start' w='100%' gap='0.05rem'>
        <Text fz='sm'>Role</Text>
        <Group align='center' gap='sm' wrap='nowrap'>
          <Select
            placeholder='Select a role'
            data={[
              { value: 'user', label: 'User' },
              { value: 'admin', label: 'Admin' },
              { value: 'owner', label: 'Owner' },
            ]}
            required
            {...selectInputProps}
            w='60%' // ??
            disabled={disabled}
            allowDeselect={false}
          />
          {/* <Button
            variant='transparent' p={0}
            onClick={() => {
              setRoleInfoVisible(!roleInfoVisible)
            }}
          >
            <IconInfoCircle size={17} stroke={2} />
          </Button> */}
        </Group>
      </Stack>

      {/* Role Warnings */}
      {
        roleChanged &&
        role == 'owner' &&
        <Paper bg='dark.6' px='md' py='xs' radius='sm'>
          <Stack align='flex-start' gap='0.33rem'>
            {/* <Text fz='sm' c='red.5' fw='bold'>Warning</Text> */}
            <Text fz='sm' c='red.5'>Owners can create/update/delete users, admins and other owners (including you!).</Text>
          </Stack>
        </Paper>
      }
      {
        roleChanged &&
        role == 'admin' &&
        <Paper bg='dark.6' px='md' py='xs' radius='sm'>
          <Text fz='sm' c='yellow.5'>Admin can create/update/delete users but cannot modify admins or owners.</Text>
        </Paper>
      }

      {/* Roles Info */}
      {/* {
        roleInfoVisible && (() => {
          const lines = [
            'Owner can create/update/delete owners, admins and users',
            'Admin can create/update/delete users',
            'User does not have access to Admin page'
          ]

          return (
            <Paper bg='dark.6' px='md' py='xs' radius='sm'>
              <Stack gap='0'>
                {lines.map(line => (
                <Group gap='0.5rem' wrap='nowrap' align='baseline'>
                  <Text fz='sm'>▪</Text>
                  <Text fz='sm'>{line}</Text>
                </Group>  
                ))}
              </Stack>
            </Paper>
          )
        })()        
      } */}
    </Stack >
  )
}
