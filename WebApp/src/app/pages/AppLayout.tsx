import { Anchor, AppShell, Avatar, Box, Burger, Container, Group, Menu, NavLink, Space, Stack, Text } from '@mantine/core'
import { useDisclosure } from '@mantine/hooks'
import { Outlet, useLocation, useNavigate } from 'react-router'
import { IconChevronRight, IconLogout2, IconUserCircle } from '@tabler/icons-react'
import { format } from 'date-fns'

// import env from 'src/env'
import { useAuth } from 'src/app/contexts'
import axios, { AxiosError } from 'axios'
import { useQuery } from '@tanstack/react-query'
import useModal from 'src/utils/use-modal'
import { ConfirmModal } from 'src/utils/ConfirmModal'

function AppLayout() {
  const [navbarOpened, { toggle: toggleNavbar, close: closeNavbar }] = useDisclosure() // Mobile only

  interface Info {
    env: string | 'production'
    lastUpdated?: string
  }

  const { data: info } = useQuery<Info, AxiosError>({
    queryKey: ['info'],
    queryFn: async () => (await axios.get<Info>('/api/info')).data
  })

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
        // height: isProdEnv ? 60 : 90
        height: 60
      }}
      navbar={{
        width: 250,
        breakpoint: 'md', // Same as burger menu in HeaderContent
        collapsed: { mobile: !navbarOpened }
      }}
      padding={{ base: '0', sm: 'md' }}
    >
      <AppShell.Header withBorder={false}>
        <HeaderContent navbarOpened={navbarOpened} toggleNavbar={toggleNavbar} closeNavbar={closeNavbar} />
      </AppShell.Header>

      <AppShell.Navbar bg='dark.8' withBorder={false}>
        <NavbarContent onClose={closeNavbar} />
      </AppShell.Navbar>

      <AppShell.Main bg='dark.9'>
        {/* py here is opposite of AppShell.padding */}
        <Container py={{ base: 'md', sm: '0px' }}>
          {/* Content is decided by the route nested inside dashboard route */}
          <Outlet />
        </Container>
      </AppShell.Main>

      {/* Test env badge */}
      {info && info.env != 'production' &&
        // mt-4: extra space when scrolled to bottom
        // miw is slightly greater than navbar width (250), defined above
        <div className='sticky pl-2 bottom-2 pb-safe z-1000 w-fit mt-4'>
          <Box bg='yellow.4' c='black' px='0.6rem' py='0.15rem' bdrs={2}>
            {/* className='[font-variant:small-caps]' */}
            <Text lineClamp={1} fz='xs' fw='bold'>
              Test Environment
            </Text>
          </Box>
        </div>
      }
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
    <Box bg='dark.7' h='100%' className='border-b border-b-neutral-700'>
      <Group h='100%' px='md' align='center' wrap='nowrap'>
        {/* <Center> */}
        <Stack gap='0.375rem'>
          <Group align='center'>
            {/* Burger menu */}
            <Burger
              opened={navbarOpened}
              onClick={toggleNavbar}
              hiddenFrom='md' // Same as AppShell navbar breakpoint
              size='sm'
            />
            {/* The Duck Group title */}
            <Anchor href='#' underline='never' onClick={() => navigate('/')}>
              <Text fw='bold' fz={20} c='gray.0'>The Duck Group</Text>
            </Anchor>
            {/* {
              !isProdEnv &&
              <Box bg='yellow.3' c='dark.8' px='xs' bdrs={3}>
                <Text lineClamp={1} fw={600} className='[font-variant:small-caps]'>test environment</Text>
              </Box>
            } */}
          </Group>
          {/* Env badge */}
          {/* {
            !isProdEnv &&
            <Group c='yellow' gap='0.25rem' wrap='nowrap'>
              <IconChevronRight size={17} strokeWidth={2.5} className='flex-none' />
              <Text lineClamp={1}>You are in test environment. Changes will not affect production.</Text>
            </Group>
          } */}
        </Stack>
        {/* </Center> */}

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
  const confirmModal = useModal(ConfirmModal)

  const [menuOpened, { open: openMenu, close: closeMenu }] = useDisclosure(false)

  function handleLogout() {
    confirmModal.open({
      message: 'Log out?',
      actions: [{
        label: 'Log out',
        handler: logout
      }]
    })
  }

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
          name={user?.name}
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
          onClick={handleLogout}
        >
          Log out
        </Menu.Item>
      </Menu.Dropdown>

      {/* Modals */}
      {confirmModal.element}
    </Menu>
  )
}

// Navbar

function NavbarContent({ onClose }: {
  onClose: () => void
}) {
  return (
    <>
      <NavbarLink label='FOH Test' path='/quiz-app' onClose={onClose} />
      <NavbarLink label='Weekly Spending' path='/ws-app' onClose={onClose} />
      <NavbarLink label='Inventory' path='/inventory-app' onClose={onClose} />
      <NavbarLink label='Admin' path='/admin' onClose={onClose} />
    </>
  )
}

function NavbarLink({ label, path, onClose }: {
  label: string
  path: string
  onClose: () => void
}) {
  const location = useLocation()
  const navigate = useNavigate()

  return (
    <NavLink
      href='#'
      label={label}
      rightSection={
        < IconChevronRight size={12} stroke={1.5} className='mantine-rotate-rtl' />
      }
      variant='filled'
      active={location.pathname.startsWith(path)}
      onClick={() => {
        navigate(path)
        onClose()
      }}
    />
  )
}

export default AppLayout
