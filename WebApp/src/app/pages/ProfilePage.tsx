import { Stack, Text, Title, Group, ColorSwatch, Divider, Tooltip, UnstyledButton } from '@mantine/core'
import { IconCheck } from '@tabler/icons-react'

import { useAuth, useAppSettings } from 'src/app/contexts'

const ProfilePage = () => {
  const { user } = useAuth()
  const { themeColor, setThemeColor, availableColors } = useAppSettings()
  
  return (
    <>
      <title>Profile | The Duck Group</title>
      <Stack>
        {user &&
          <>
            <Stack gap='sm'>
              <Title order={4} c='gray.0'>Account</Title>
              <Stack gap={0}>
                <Text>{`${user.userMetadata.firstName} ${user.userMetadata.lastName}`}</Text>
                <Text>{user.email}</Text>
              </Stack>
            </Stack>
            <Divider />
            <Stack gap='md'>
              <Title order={4} c='gray.0'>Theme</Title>
              <Group gap='sm'>
                {availableColors.map((color) => (
                  <Tooltip key={color.value} label={color.label} position='top'>
                    <UnstyledButton
                      onClick={() => setThemeColor(color.value)}
                      style={{ position: 'relative' }}
                    >
                      <ColorSwatch 
                        color={color.swatch} 
                        size={28}
                        style={{ cursor: 'pointer' }}
                      />
                      {themeColor === color.value && (
                        <div
                          style={{
                            position: 'absolute',
                            top: '50%',
                            left: '50%',
                            transform: 'translate(-50%, -50%)',
                            pointerEvents: 'none'
                          }}
                        >
                          <IconCheck size={16} color='white' stroke={3} />
                        </div>
                      )}
                    </UnstyledButton>
                  </Tooltip>
                ))}
              </Group>
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