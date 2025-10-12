import { User } from '@supabase/supabase-js'

export function getUserName(user: User) {
  const parts = [
    user.user_metadata.first_name,
    user.user_metadata.last_name
  ].filter(x => x)

  if (parts.length) {
    return parts.join(' ')
  } else {
    return 'Unknown User'
  }
}

export const Roles = {
  owner: 'org:owner' as const,
  admin: 'org:admin' as const
}

export type Role = typeof Roles['owner'] | typeof Roles['admin']

export function getUserRoles(user: User): Role[] {
  const sbroles = user.app_metadata.roles
  let roles: Role[] = []

  if (!sbroles) {
    console.error('Supabase roles are undefined')
    return []
  }

  if (!Array.isArray(sbroles)) {
    console.error('Supabase roles are undefined')
    return []
  }

  for (const x of sbroles) {
    if (x == Roles.owner) {
      roles.push(x)
    } else if (x == Roles.admin) {
      roles.push(x)
    } else {
      console.error(`Unknown role: ${x}`)
    }
  }

  return roles
}
