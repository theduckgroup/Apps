import { useState, useEffect } from 'react'
import { Button, Group, Menu, MenuItem, Stack, Table, Text, Title } from '@mantine/core'
import { IconEdit, IconKey, IconPlus, IconTrash } from '@tabler/icons-react'
import { useQuery } from '@tanstack/react-query'

import { useAuth, usePath, useApi } from 'src/app/contexts'
import { User, type SBUser } from 'src/app/models/User'
import eventHub from '../event-hub'
import AddUserModal from './AddUserModal'
import EditUserModal from './EditUserModal'
import DeleteUserModal from './DeleteUserModal'
import SetPasswordModal from './SetPasswordModal'
import useRepeatedModal from 'src/common/use-repeated-modal'
import formatError from 'src/common/format-error'

export default function UsersPage() {
  const { axios } = useApi()

  const { data: users, isLoading, error, refetch } = useQuery<User[]>({
    queryKey: ['users'],
    queryFn: async () => {
      const data = (await axios.get<SBUser[]>('/users')).data
      return data.map(x => new User(x))
    }
  })

  useEffect(() => {
    const unsubscribe = eventHub.onUsersChanged(() => {
      console.info(`! Refetching`)
      refetch()
    })

    return unsubscribe
  }, [refetch])

  return (
    <Stack align='flex-start'>
      <Title order={2} c='gray.0' pb='xs'>Users</Title>

      {(() => {
        if (isLoading) {
          return <Text>Loading...</Text>
        }

        if (error) {
          return <Text c='red'>{formatError(error)}</Text>
        }

        if (!users) {
          throw new Error('???')
        }

        return <Content users={users} />
      })()}
    </Stack>
  )
}

function Content({ users }: { users: User[] }) {
  const addModal = useRepeatedModal()

  // Delete modal must not be inside UserRow because the row will be gone
  const [deleteUser, setDeleteUser] = useState<User>()
  const [deleteModalOpened, setDeleteModalOpened] = useState(false)

  return (
    <>
      <Stack align='flex-start' w='100%'>
        <Table verticalSpacing='xs'>
          <Table.Thead>
            <Table.Tr>
              <Table.Th styles={{ th: { width: '30%' } }}>
                Name
              </Table.Th>
              <Table.Th styles={{ th: { width: '40%' } }}>
                Email
              </Table.Th>
              <Table.Th styles={{ th: { width: '15%' } }}>
                Role
              </Table.Th>
              <Table.Th styles={{ th: { width: '15%' } }}>
                {/* Manage */}
              </Table.Th>
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {sortUsers(users).map(user => (
              <UserRow
                key={user.id}
                user={user}
                onDelete={() => {
                  setDeleteUser(user)
                  setDeleteModalOpened(true)
                }}
              />
            ))}
          </Table.Tbody>
        </Table>

        {/* Add button */}
        <Button
          variant='filled' size='sm'
          leftSection={<IconPlus size={15} stroke={2.5} />}
          onClick={addModal.open}
        >
          Add User
        </Button>
      </Stack>

      {addModal.modalIDs.map(id => (
        <AddUserModal opened={addModal.isOpened(id)} onClose={addModal.close} />
      ))}
      <DeleteUserModal userId={deleteUser?.id ?? ''} opened={deleteModalOpened} onClose={() => setDeleteModalOpened(false)} />
    </>
  )
}

function UserRow({ user, onDelete }: {
  user: User,
  onDelete: () => void
}) {
  const { user: currentUser } = useAuth()
  const [manageMenuOpened, setManageMenuOpened] = useState(false)
  const editModal = useRepeatedModal()
  const passwordModal = useRepeatedModal()

  function checkRoles(action: 'update' | 'delete') {
    if (!currentUser) {
      return false
    }

    if (currentUser.isOwner) {
      if (currentUser.id == user.id) {
        switch (action) {
          case 'update': return true
          case 'delete': return false
        }

      } else {
        return true
      }

    } else if (currentUser.isAdmin) {
      if (user.isOwner || user.isAdmin) {
        return false

      } else {
        return true
      }

    } else {
      return false
    }
  }

  return (
    <Table.Tr key={user.id}>
      <Table.Td>
        {user.name}
        {user.id == currentUser?.id ? ' *' : null}
      </Table.Td>
      <Table.Td>{user.email}</Table.Td>
      <Table.Td>{user.roleName}</Table.Td>
      <Table.Td>
        {
          (checkRoles('update') || checkRoles('delete')) &&
          <Group justify='end'>
            <Menu
              opened={manageMenuOpened}
              onChange={setManageMenuOpened}
              closeOnItemClick={false}
              position='bottom-end'
            >
              <Menu.Target>
                <Button variant='transparent' size='compact-xs'>
                  Manage
                </Button>
              </Menu.Target>
              <Menu.Dropdown>
                {checkRoles('update') && <>
                  <MenuItem
                    leftSection={<IconEdit size={14} />}
                    onClick={() => {
                      setManageMenuOpened(false)
                      editModal.open()
                    }}
                  >
                    Edit
                  </MenuItem>
                  <MenuItem
                    leftSection={<IconKey size={14} />}
                    onClick={() => {
                      setManageMenuOpened(false)
                      passwordModal.open()
                    }}
                  >
                    Set Password
                  </MenuItem>
                </>}

                {checkRoles('delete') &&
                  <MenuItem
                    leftSection={<IconTrash size={14} />}
                    color='red'
                    onClick={() => {
                      setManageMenuOpened(false)
                      onDelete()
                    }}
                  >
                    Delete
                  </MenuItem>
                }
              </Menu.Dropdown>
            </Menu>
          </Group>
        }
      </Table.Td>

      {editModal.modalIDs.map(id => (
        <EditUserModal key={id} title='Edit User' user={user} opened={editModal.isOpened(id)} onClose={editModal.close} />
      ))}
      {passwordModal.modalIDs.map(id => (
        <SetPasswordModal user={user} opened={passwordModal.isOpened(id)} onClose={passwordModal.close} />
      ))}
    </Table.Tr>
  )
}

function sortUsers(users: User[]): User[] {
  users = users.sort((a, b) => a.name.localeCompare(b.name))

  users = users.sort((a, b) => {
    function order(user: User) {
      if (user.isOwner) { return 2 }
      else if (user.isAdmin) { return 1 }
      else { return 0 }
    }

    const order_a = order(a)
    const order_b = order(b)

    if (order_a < order_b) { return 1 }
    else if (order_a == order_b) { return 0 }
    else { return -1 }
  })

  return users
}
