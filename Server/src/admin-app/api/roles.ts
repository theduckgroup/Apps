import { User } from '@supabase/supabase-js'

export const Roles = {
  owner: 'org:owner' as const,
  admin: 'org:admin' as const
}
// const OwnerRole = 'org:owner' as const
// const AdminRole = 'org:admin' as const

export type Role = typeof Roles['owner'] | typeof Roles['admin']

export function getRoles(user: User): Role[] {
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
