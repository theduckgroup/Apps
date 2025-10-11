import { User as SBUser } from '@supabase/supabase-js'

/**
 * User.
 */
export class User {
  id: string
  email: string
  userMetadata: {
    firstName: string
    lastName: string
  }
  appMetadata: {
    roles: User.Role[]
  }

  constructor(sbUser: SBUser) {
    this.id = sbUser.id
    this.email = sbUser.email ?? ''
    this.userMetadata = {
      firstName: sbUser.user_metadata.first_name ?? '',
      lastName: sbUser.user_metadata.last_name ?? ''
    }
    this.appMetadata = {
      roles: sbUser.app_metadata.roles ?? []
    }
  }

  get name() {
    const parts = [this.userMetadata.firstName, this.userMetadata.lastName].filter(x => x)
    
    if (parts.length) {
      return parts.join(' ')
    } else {
      return 'Unknown User'
    }
  }

  get isOwner() {
    return this.appMetadata.roles.includes('org:owner')
  }

  get isAdmin() {
    return this.appMetadata.roles.includes('org:admin')
  }

  get roleName() {
    return (
      this.appMetadata.roles.includes('org:owner') ? 'Owner' :
        this.appMetadata.roles.includes('org:admin') ? 'Admin' :
          'User'
    )
  }
}

export namespace User {
  export type Role = 'org:owner' | 'org:admin'
}

export { type SBUser }