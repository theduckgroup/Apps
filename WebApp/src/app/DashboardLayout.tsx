import { Anchor, AppShell, Avatar, Box, Burger, Button, Center, Container, Group, Menu, Modal, NavLink, Space, Stack, Text } from '@mantine/core'
import { useDisclosure } from '@mantine/hooks'
import { Outlet, useLocation, useNavigate } from 'react-router'
import { IconChevronRight, IconLogout2, IconUserCircle, IconUsers } from '@tabler/icons-react'

import { useAuth } from 'src/auth/AuthContext'
import env from 'src/env'

function DashboardLayout() {
  const [navbarOpened, { toggle: toggleNavbar, close: closeNavbar }] = useDisclosure() // Mobile only

  /*
  const { setColorScheme } = useMantineColorScheme()
  const computedColorScheme = useComputedColorScheme('light')
  
  function toggleColorScheme() {
    setColorScheme(computedColorScheme === 'dark' ? 'light' : 'dark')
  }
  */

  return (
    <AppShell
      header={{
        height: 60
      }}
      navbar={{
        width: 250,
        breakpoint: 'sm',
        collapsed: { mobile: !navbarOpened }
      }}
      padding={{ base: '0', sm: 'md' }}
    >
      <AppShell.Header withBorder={false}>
        <HeaderContent navbarOpened={navbarOpened} toggleNavbar={toggleNavbar} closeNavbar={closeNavbar} />
      </AppShell.Header>

      <AppShell.Navbar px={0} py='md' bg='dark.8' withBorder={false}>
        <NavbarContent close={closeNavbar} />
      </AppShell.Navbar>

      <AppShell.Main bg='dark.9'>
        {/* py here is opposite of AppShell.padding */}
        <Container py={{ base: 'md', sm: '0px' }}>
          {/* Content is decided by the route nested inside dashboard route */}
          <Outlet />
        </Container>
      </AppShell.Main>
    </AppShell>
  )
}

// Header

function HeaderContent({ navbarOpened, toggleNavbar, closeNavbar }: {
  navbarOpened: boolean,
  toggleNavbar: () => void,
  closeNavbar: () => void
}) {
  const navigate = useNavigate()

  return (
    <Box bg='dark.7' h='100%'
      className='border-b border-b-neutral-700'>
      <Group h='100%' px='md'
      >
        <Center>
          <Group>
            <Burger
              opened={navbarOpened}
              onClick={toggleNavbar}
              hiddenFrom='sm'
              size='sm'
            />
            <Anchor href='#' underline='never' onClick={() => navigate('/')}>
              <Text fw='bold' fz={20} c='gray.0'>Quiz App</Text>
            </Anchor>
            {/* <Text fw='bold' fz={20}>Quiz App</Text> */}
          </Group>
        </Center>

        <Space flex={1} />

        <Group gap='xs'>
          <ProfileButton closeNavbar={closeNavbar} />
        </Group>
      </Group>
    </Box>
  )
}

const ProfileButton = ({ closeNavbar }: {
  closeNavbar: () => void
}) => {
  const navigate = useNavigate()
  const { user, logout } = useAuth()
  const name = user && `${user.user_metadata.firstName} ${user.user_metadata.lastName}`

  const [logoutModalOpened, { open: openLogoutModal, close: closeLogoutModal }] = useDisclosure(false)
  const [menuOpened, { open: openMenu, close: closeMenu }] = useDisclosure(false)

  return (
    <Menu
      opened={menuOpened}
      onOpen={openMenu}
      onClose={closeMenu}
      position='bottom-end'
      width='150px'
    >
      <Menu.Target>
        <Avatar
          name={name}
          color='initials'
          radius='xl'
          className='cursor-pointer'
        />
      </Menu.Target>
      <Menu.Dropdown>
        <Menu.Item
          leftSection={<IconUserCircle size={16} />}
          onClick={() => {
            navigate('/profile')
            closeNavbar()
            closeMenu()
          }}
        >
          Profile
        </Menu.Item>
        <Menu.Item
          leftSection={<IconLogout2 size={16} />}
          onClick={openLogoutModal}
        >
          Log out
        </Menu.Item>
      </Menu.Dropdown>

      {/* Logout modal */}
      <Modal
        withCloseButton={false}
        opened={logoutModalOpened}
        onClose={close}
      >
        <Stack>
          <Text>Log out?</Text>
          <Group ml='auto'>
            <Button variant='default' onClick={closeLogoutModal}>Cancel</Button>
            <Button onClick={logout}>Logout</Button>
          </Group>
        </Stack>
      </Modal>
    </Menu>
  )
}

// Navbar

function NavbarContent({ close }: {
  close: () => void
}) {
  const location = useLocation()
  const navigate = useNavigate()

  return (
    <>
      <NavLink
        href='#'
        label='FOH Test'
        variant='filled'
        rightSection={
          <IconChevronRight size={14} stroke={2} className='mantine-rotate-rtl' />
        }
        active={location.pathname.startsWith(env.quizApp.path)}
        onClick={() => navigate(env.quizApp.path)}
      />
      {/* {vendors && vendors.map(vendor => {
        const path = `/vendor/${vendor.id}`

        return (
          <NavLink
            key={vendor.id}
            href={`#vendor_${vendor.id}`}
            label={vendor.name}
            variant='subtle'
            rightSection={
              <IconChevronRight size={12} stroke={1.5} className='mantine-rotate-rtl' />
            }
            active={location.pathname.startsWith(path)}
            onClick={() => {
              if (!location.pathname.startsWith(path)) {
                navigate(path)
              }

              close()
            }}
          />
        )
      })} */}
      <NavLink
        href='#'
        label='Admin'
        rightSection={
          < IconChevronRight size={12} stroke={1.5} className='mantine-rotate-rtl' />
        }
        variant='filled'        
        active={location.pathname.startsWith(`/${env.adminApp.webPath}`)}
        onClick={() => navigate(`/${env.adminApp.webPath}`)}
      />
    </>
  )
}

export default DashboardLayout
