import { createClient } from '@supabase/supabase-js'
import env from 'src/env'

export default createClient(env.supabase.url, env.supabase.key)
