import { Stack, Text, Title } from '@mantine/core'
// import { IconExternalLink } from '@tabler/icons-react'

import { useAuth } from 'src/app/providers/AuthContext'

const ProfilePage = () => {
  const { user } = useAuth()
  
  return (
    <>
      <Stack>
        {user &&
          <>
            <Stack>
              <Title order={2} c='gray.0'>Profile</Title>
              <Stack gap={0}>
                <Text>{`${user.userMetadata.firstName} ${user.userMetadata.lastName}`}</Text>
                <Text>{user.email}</Text>
              </Stack>
            </Stack>
            {/* <Divider /> */}
            {/* <Stack gap='xs' align='flex-start'>
              <Text >Use Admin console to edit profile.</Text>
              <Anchor href='http://admin.theduckgroup.com.au' target='_blank'>
                <Button
                  variant='default' size='sm'
                  leftSection={<IconExternalLink size={12} stroke={2} />}>
                  Open Admin
                </Button>
              </Anchor>
            </Stack> */}
          </>
        }
      </Stack>
    </>
  )
}

export default ProfilePage